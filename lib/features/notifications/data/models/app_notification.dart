/// Types canoniques de notifications supportes cote app.
/// Le back peut les envoyer sous forme de chaine (ex: "new_message") ou de
/// classe Laravel completement qualifiee (ex: "App\\Notifications\\NewMessage").
enum NotificationKind {
  newMessage,
  newOffer,
  newApplication,
  newMissionRequest,
  missionStatusChanged,
  applicationStatusChanged,
  interviewInvitation,
  paymentReceived,
  paymentCompleted,
  reviewReceived,
  system,
  other;

  static NotificationKind fromRaw(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.isEmpty) return NotificationKind.other;
    if (s.contains('message')) return NotificationKind.newMessage;
    if (s.contains('interview') || s.contains('entretien')) {
      return NotificationKind.interviewInvitation;
    }
    if (s.contains('mission') && s.contains('status')) {
      return NotificationKind.missionStatusChanged;
    }
    if (s.contains('mission') &&
        (s.contains('request') || s.contains('demande') || s.contains('created'))) {
      return NotificationKind.newMissionRequest;
    }
    if (s.contains('application') && s.contains('status')) {
      return NotificationKind.applicationStatusChanged;
    }
    if (s.contains('application') ||
        s.contains('candidature') ||
        s.contains('candidat')) {
      return NotificationKind.newApplication;
    }
    if (s.contains('offer') || s.contains('offre') || s.contains('job')) {
      return NotificationKind.newOffer;
    }
    if (s.contains('payment') && s.contains('receiv')) {
      return NotificationKind.paymentReceived;
    }
    if (s.contains('payment') && s.contains('complet')) {
      return NotificationKind.paymentCompleted;
    }
    if (s.contains('payment') ||
        s.contains('paiement') ||
        s.contains('paid')) {
      return NotificationKind.paymentReceived;
    }
    if (s.contains('review') ||
        s.contains('avis') ||
        s.contains('note') ||
        s.contains('rating')) {
      return NotificationKind.reviewReceived;
    }
    if (s.contains('system') ||
        s.contains('welcome') ||
        s.contains('info')) {
      return NotificationKind.system;
    }
    return NotificationKind.other;
  }

  /// Clef i18n pour le libelle par defaut de ce type.
  String get i18nTitleKey => 'notif.type.${_titleSlug()}';

  String _titleSlug() {
    switch (this) {
      case NotificationKind.newMessage:
        return 'new_message';
      case NotificationKind.newOffer:
        return 'new_offer';
      case NotificationKind.newApplication:
        return 'new_application';
      case NotificationKind.newMissionRequest:
        return 'new_mission_request';
      case NotificationKind.missionStatusChanged:
        return 'mission_status_changed';
      case NotificationKind.applicationStatusChanged:
        return 'application_status_changed';
      case NotificationKind.interviewInvitation:
        return 'interview_invitation';
      case NotificationKind.paymentReceived:
        return 'payment_received';
      case NotificationKind.paymentCompleted:
        return 'payment_completed';
      case NotificationKind.reviewReceived:
        return 'review_received';
      case NotificationKind.system:
        return 'system';
      case NotificationKind.other:
        return 'other';
    }
  }
}

/// Representation d'une notification cote app.
/// Tolerant sur le format : le back peut renvoyer soit le format Laravel natif
/// (data JSON serialise + type FQCN), soit un format aplati.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.rawType,
    this.title,
    this.body,
    this.readAt,
    this.createdAt,
    this.data = const {},
    // Entites liees pour permettre la navigation depuis le tap.
    this.missionId,
    this.offerId,
    this.applicationId,
    this.conversationId,
    this.freelancerId,
    this.userId,
  });

  final String id;
  final NotificationKind kind;
  final String rawType;
  final String? title;
  final String? body;
  final String? readAt;
  final String? createdAt;
  final Map<String, dynamic> data;
  final int? missionId;
  final int? offerId;
  final int? applicationId;
  final int? conversationId;
  final int? freelancerId;
  final int? userId;

  bool get isUnread => readAt == null || readAt!.trim().isEmpty;

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> data = const {};
    final rawData = j['data'];
    if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else if (rawData is String && rawData.isNotEmpty) {
      // Laravel serialize parfois data en JSON string.
      try {
        // On evite d'importer dart:convert ici, un parse defensif basique.
        data = <String, dynamic>{'raw': rawData};
      } catch (_) {
        data = <String, dynamic>{};
      }
    }

    // Priorite : data.kind (canonique, envoye par le back) puis j['type']
    // (FQCN Laravel) puis j['kind'] tel quel.
    final rawType = (data['kind'] ?? j['type'] ?? j['kind'] ?? '').toString();
    final kind = NotificationKind.fromRaw(rawType);

    String? title = j['title']?.toString() ??
        data['title']?.toString() ??
        data['subject']?.toString();
    String? body = j['message']?.toString() ??
        data['message']?.toString() ??
        data['body']?.toString() ??
        data['content']?.toString();

    return AppNotification(
      id: (j['id'] ?? '').toString(),
      kind: kind,
      rawType: rawType,
      title: title,
      body: body,
      readAt: j['read_at']?.toString(),
      createdAt: j['created_at']?.toString(),
      data: data,
      missionId: _iOrNull(data['mission_id']) ?? _iOrNull(j['mission_id']),
      offerId: _iOrNull(data['offer_id']) ??
          _iOrNull(data['offre_id']) ??
          _iOrNull(j['offer_id']) ??
          _iOrNull(j['offre_id']),
      applicationId: _iOrNull(data['application_id']) ??
          _iOrNull(data['candidature_id']) ??
          _iOrNull(j['candidature_id']),
      conversationId: _iOrNull(data['conversation_id']) ??
          _iOrNull(j['conversation_id']),
      freelancerId: _iOrNull(data['freelancer_id']) ??
          _iOrNull(j['freelancer_id']),
      userId: _iOrNull(data['user_id']) ??
          _iOrNull(data['sender_id']) ??
          _iOrNull(j['user_id']),
    );
  }
}

int? _iOrNull(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}
