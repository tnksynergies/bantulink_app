import 'message.dart';

class Participant {
  const Participant({required this.id, this.nom, this.prenom, this.isActive = false});
  final int id;
  final String? nom;
  final String? prenom;
  final bool isActive;

  String get name {
    final n = [prenom, nom].where((e) => e != null && e!.trim().isNotEmpty).join(' ').trim();
    return n.isEmpty ? 'Utilisateur' : n;
  }

  factory Participant.fromJson(Map<String, dynamic> j) => Participant(
        id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
        nom: j['nom']?.toString(),
        prenom: j['prenom']?.toString(),
        isActive: j['is_active'] == true || j['is_active'] == 1,
      );
}

class Conversation {
  const Conversation({
    required this.id,
    this.participants = const [],
    this.messages = const [],
    this.unreadCount = 0,
  });

  final int id;
  final List<Participant> participants;
  final List<Message> messages;
  final int unreadCount;

  Participant? other(int myId) {
    for (final p in participants) {
      if (p.id != myId) return p;
    }
    return participants.isNotEmpty ? participants.first : null;
  }

  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  factory Conversation.fromJson(Map<String, dynamic> j) {
    final parts = <Participant>[];
    final rp = j['participants'];
    if (rp is List) {
      for (final p in rp) {
        if (p is Map) parts.add(Participant.fromJson(Map<String, dynamic>.from(p)));
      }
    }
    final msgs = <Message>[];
    final rm = j['messages'];
    if (rm is List) {
      for (final m in rm) {
        if (m is Map) msgs.add(Message.fromJson(Map<String, dynamic>.from(m)));
      }
    }
    return Conversation(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      participants: parts,
      messages: msgs,
      unreadCount: j['unread_count'] is int
          ? j['unread_count'] as int
          : int.tryParse('${j['unread_count']}') ?? 0,
    );
  }
}
