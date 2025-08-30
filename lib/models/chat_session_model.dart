class ChatSessionModel {
  final int? id;
  final String title;
  final DateTime createdAt;
  final DateTime lastActivity;
  final String taskFilePath;
  final int messageCount;
  final String? lastMessage;

  ChatSessionModel({
    this.id,
    required this.title,
    required this.createdAt,
    required this.lastActivity,
    required this.taskFilePath,
    required this.messageCount,
    this.lastMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
      'taskFilePath': taskFilePath,
      'messageCount': messageCount,
      'lastMessage': lastMessage,
    };
  }

  factory ChatSessionModel.fromMap(Map<String, dynamic> map) {
    return ChatSessionModel(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastActivity: DateTime.fromMillisecondsSinceEpoch(map['lastActivity']),
      taskFilePath: map['taskFilePath'],
      messageCount: map['messageCount'],
      lastMessage: map['lastMessage'],
    );
  }

  @override
  String toString() {
    return 'ChatSessionModel(id: $id, title: $title, createdAt: $createdAt, lastActivity: $lastActivity, taskFilePath: $taskFilePath, messageCount: $messageCount, lastMessage: $lastMessage)';
  }
}
