class Conversation {
  final DateTime sessionId;
  final DateTime createdAt;
  final String userId;
  final String? title;

  Conversation({
    required this.sessionId,
    required this.createdAt,
    required this.userId,
    this.title,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      sessionId: DateTime.parse(json['session_id'] as String).toUtc(),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      userId: json['user_id'] as String,
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId.toUtc().toIso8601String(),
      'created_at': sessionId.toUtc().toIso8601String(),
      'user_id': userId,
      'title': title,
    };
  }
}