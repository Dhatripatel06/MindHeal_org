class ChatSession {
  final String id;
  final String title;
  final DateTime lastUpdated;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastUpdated,
    required this.messageCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lastUpdated': lastUpdated.toIso8601String(),
      'messageCount': messageCount,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      messageCount: json['messageCount'],
    );
  }

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? lastUpdated,
    int? messageCount,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}
