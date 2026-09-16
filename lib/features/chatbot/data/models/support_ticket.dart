class SupportTicket {
  SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    this.adminResponse,
    this.createdAt,
  });

  final int id;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final String? adminResponse;
  final String? createdAt;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as int,
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      priority: json['priority'] as String? ?? 'medium',
      adminResponse: json['admin_response'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
