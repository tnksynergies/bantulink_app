import '../../../../core/utils/media_url.dart';

class MessageAttachment {
  const MessageAttachment({this.name, this.url});
  final String? name;
  final String? url;
  factory MessageAttachment.fromJson(Map<String, dynamic> j) => MessageAttachment(
        name: (j['name'] ?? j['filename'] ?? j['nom'])?.toString(),
        url: mediaUrl((j['url'] ?? j['path'] ?? j['lien'])?.toString()),
      );
}

class Message {
  const Message({
    required this.id,
    this.content,
    this.senderId,
    this.createdAt,
    this.readAt,
    this.attachments = const [],
    this.sending = false,
  });

  final int id;
  final String? content;
  final int? senderId;
  final String? createdAt;
  final String? readAt;
  final List<MessageAttachment> attachments;
  final bool sending;

  String get timeShort {
    final d = createdAt;
    if (d == null) return '';
    final t = DateTime.tryParse(d);
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory Message.fromJson(Map<String, dynamic> j) {
    final atts = <MessageAttachment>[];
    final ra = j['attachments'];
    if (ra is List) {
      for (final a in ra) {
        if (a is Map) atts.add(MessageAttachment.fromJson(Map<String, dynamic>.from(a)));
      }
    }
    return Message(
      id: _i(j['id']),
      content: j['content']?.toString(),
      senderId: _ni(j['sender_id'] ?? j['user_id']),
      createdAt: (j['created_at'] ?? j['createdAt'])?.toString(),
      readAt: (j['read_at'])?.toString(),
      attachments: atts,
    );
  }
}

int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
int? _ni(dynamic v) => v is int ? v : int.tryParse('$v');
