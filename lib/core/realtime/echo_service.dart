import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'reverb_config.dart';

/// Service temps reel (protocole Pusher, compatible Reverb) via WebSocket pur.
/// Fonctionne sur Android, iOS, desktop ET web (web_socket_channel).
abstract class EchoService {
  Future<void> ensureConnected();
  Future<void> subscribeConversation(
      int conversationId, void Function(Map<String, dynamic> message) onMessage);
  Future<void> unsubscribeConversation(int conversationId);
  void dispose();
}

EchoService createEchoService(Dio dio) => WebSocketEchoService(dio);

class WebSocketEchoService implements EchoService {
  WebSocketEchoService(this._dio);
  final Dio _dio;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  String? _socketId;
  bool _connecting = false;
  bool _disposed = false;
  Timer? _reconnect;
  final Map<String, void Function(Map<String, dynamic>)> _handlers = {};

  String get _url {
    final scheme = ReverbConfig.useTLS ? 'wss' : 'ws';
    return '$scheme://${ReverbConfig.host}:${ReverbConfig.port}'
        '/app/${ReverbConfig.appKey}?protocol=7&client=dart&version=1.0&flash=false';
  }

  @override
  Future<void> ensureConnected() async {
    if (_disposed) return;
    if (_channel != null) return;
    await _connect();
  }

  Future<void> _connect() async {
    if (_connecting || _disposed || _channel != null) return;
    _connecting = true;
    try {
      final ch = WebSocketChannel.connect(Uri.parse(_url));
      _channel = ch;
      _sub = ch.stream.listen(
        _onData,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onData(dynamic raw) {
    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final event = (frame['event'] ?? '').toString();

    if (event == 'pusher:connection_established') {
      final data = _decode(frame['data']);
      _socketId = data['socket_id']?.toString();
      // (re)abonnement de tous les canaux en attente
      for (final c in _handlers.keys.toList()) {
        _subscribeRaw(c);
      }
      return;
    }
    if (event == 'pusher:ping') {
      _send({'event': 'pusher:pong', 'data': {}});
      return;
    }
    if (event == 'pusher:error') return;
    if (event.contains('subscription_succeeded')) return;

    // Evenements applicatifs (.message.sent / message.sent)
    final channel = frame['channel']?.toString();
    if (channel == null) return;
    final handler = _handlers[channel];
    if (handler == null) return;
    if (!event.contains('message')) return;

    final data = _decode(frame['data']);
    final msg = data['message'] is Map
        ? Map<String, dynamic>.from(data['message'] as Map)
        : data;
    handler(msg);
  }

  Map<String, dynamic> _decode(dynamic d) {
    if (d is Map) return Map<String, dynamic>.from(d);
    if (d is String) {
      try {
        final x = jsonDecode(d);
        return x is Map ? Map<String, dynamic>.from(x) : {};
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  void _send(Map<String, dynamic> m) {
    try {
      _channel?.sink.add(jsonEncode(m));
    } catch (_) {}
  }

  /// Autorise puis abonne un canal prive (auth via /broadcasting/auth, Bearer ajoute par Dio).
  Future<void> _subscribeRaw(String channel) async {
    if (_socketId == null) return;
    String? auth;
    try {
      final res = await _dio.post(ReverbConfig.authPath, data: {
        'socket_id': _socketId,
        'channel_name': channel,
      });
      final d = res.data;
      if (d is Map) auth = d['auth']?.toString();
    } catch (_) {}
    if (auth == null) return;
    _send({
      'event': 'pusher:subscribe',
      'data': {'auth': auth, 'channel': channel},
    });
  }

  String _ch(int id) => 'private-conversations.$id';

  @override
  Future<void> subscribeConversation(
      int conversationId, void Function(Map<String, dynamic>) onMessage) async {
    final channel = _ch(conversationId);
    _handlers[channel] = onMessage;
    await ensureConnected();
    // Si deja connecte (socket_id connu), on s'abonne tout de suite ;
    // sinon l'abonnement se fera a la reception de connection_established.
    if (_socketId != null) await _subscribeRaw(channel);
  }

  @override
  Future<void> unsubscribeConversation(int conversationId) async {
    final channel = _ch(conversationId);
    _handlers.remove(channel);
    _send({
      'event': 'pusher:unsubscribe',
      'data': {'channel': channel},
    });
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _socketId = null;
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _reconnect?.cancel();
    if (_handlers.isEmpty) return; // rien a ecouter, inutile de reconnecter
    _reconnect = Timer(const Duration(seconds: 3), _connect);
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnect?.cancel();
    _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}
