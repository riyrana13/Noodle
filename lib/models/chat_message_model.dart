class ChatMessageModel {
  final int? id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;
  final int processingTimeMs;
  final String queryType; // 'cpu' or 'gpu'
  final String? modelResponse;
  final String? taskFilePath;
  final int? sessionId;

  ChatMessageModel({
    this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
    required this.processingTimeMs,
    required this.queryType,
    this.modelResponse,
    this.taskFilePath,
    this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imagePath': imagePath,
      'processingTimeMs': processingTimeMs,
      'queryType': queryType,
      'modelResponse': modelResponse,
      'taskFilePath': taskFilePath,
      'sessionId': sessionId,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'],
      message: map['message'],
      isUser: map['isUser'] == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      imagePath: map['imagePath'],
      processingTimeMs: map['processingTimeMs'],
      queryType: map['queryType'],
      modelResponse: map['modelResponse'],
      taskFilePath: map['taskFilePath'],
      sessionId: map['sessionId'],
    );
  }

  @override
  String toString() {
    return 'ChatMessageModel(id: $id, message: $message, isUser: $isUser, timestamp: $timestamp, imagePath: $imagePath, processingTimeMs: $processingTimeMs, queryType: $queryType, modelResponse: $modelResponse, taskFilePath: $taskFilePath, sessionId: $sessionId)';
  }
}
