import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'noodle_chat.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create chat_sessions table
    await db.execute('''
      CREATE TABLE chat_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        lastActivity INTEGER NOT NULL,
        taskFilePath TEXT NOT NULL,
        messageCount INTEGER NOT NULL,
        lastMessage TEXT
      )
    ''');

    // Create chat_messages table
    await db.execute('''
      CREATE TABLE chat_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        isUser INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        imagePath TEXT,
        processingTimeMs INTEGER NOT NULL,
        queryType TEXT NOT NULL,
        modelResponse TEXT,
        taskFilePath TEXT,
        sessionId INTEGER,
        FOREIGN KEY (sessionId) REFERENCES chat_sessions (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate from version 1 to 2: rename taskFileName to taskFilePath
      try {
        // Rename columns in chat_sessions table
        await db.execute(
          'ALTER TABLE chat_sessions RENAME TO chat_sessions_old',
        );
        await db.execute('''
          CREATE TABLE chat_sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            lastActivity INTEGER NOT NULL,
            taskFilePath TEXT NOT NULL,
            messageCount INTEGER NOT NULL,
            lastMessage TEXT
          )
        ''');
        await db.execute('''
          INSERT INTO chat_sessions (id, title, createdAt, lastActivity, taskFilePath, messageCount, lastMessage)
          SELECT id, title, createdAt, lastActivity, taskFileName, messageCount, lastMessage
          FROM chat_sessions_old
        ''');
        await db.execute('DROP TABLE chat_sessions_old');

        // Rename columns in chat_messages table
        await db.execute(
          'ALTER TABLE chat_messages RENAME TO chat_messages_old',
        );
        await db.execute('''
          CREATE TABLE chat_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            imagePath TEXT,
            processingTimeMs INTEGER NOT NULL,
            queryType TEXT NOT NULL,
            modelResponse TEXT,
            taskFilePath TEXT,
            sessionId INTEGER,
            FOREIGN KEY (sessionId) REFERENCES chat_sessions (id)
          )
        ''');
        await db.execute('''
          INSERT INTO chat_messages (id, message, isUser, timestamp, imagePath, processingTimeMs, queryType, modelResponse, taskFilePath, sessionId)
          SELECT id, message, isUser, timestamp, imagePath, processingTimeMs, queryType, modelResponse, taskFileName, sessionId
          FROM chat_messages_old
        ''');
        await db.execute('DROP TABLE chat_messages_old');
      } catch (e) {
        print('Migration error: $e');
        // If migration fails, recreate tables
        await db.execute('DROP TABLE IF EXISTS chat_sessions_old');
        await db.execute('DROP TABLE IF EXISTS chat_messages_old');
        await _onCreate(db, newVersion);
      }
    }
  }

  // Insert a new chat message
  Future<int> insertChatMessage(ChatMessageModel message) async {
    final db = await database;
    return await db.insert('chat_messages', message.toMap());
  }

  // Get all chat messages
  Future<List<ChatMessageModel>> getAllChatMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessageModel.fromMap(maps[i]));
  }

  // Get chat messages for a specific task file
  Future<List<ChatMessageModel>> getChatMessagesForTask(
    String taskFilePath,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'taskFilePath = ?',
      whereArgs: [taskFilePath],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessageModel.fromMap(maps[i]));
  }

  // Get messages with images
  Future<List<ChatMessageModel>> getMessagesWithImages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'imagePath IS NOT NULL',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ChatMessageModel.fromMap(maps[i]));
  }

  // Get processing time statistics
  Future<Map<String, dynamic>> getProcessingTimeStats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        AVG(processingTimeMs) as avgProcessingTime,
        MIN(processingTimeMs) as minProcessingTime,
        MAX(processingTimeMs) as maxProcessingTime,
        COUNT(*) as totalMessages,
        queryType
      FROM chat_messages 
      GROUP BY queryType
    ''');

    Map<String, dynamic> stats = {};
    for (var map in maps) {
      stats[map['queryType']] = {
        'avgProcessingTime': map['avgProcessingTime']?.round() ?? 0,
        'minProcessingTime': map['minProcessingTime'] ?? 0,
        'maxProcessingTime': map['maxProcessingTime'] ?? 0,
        'totalMessages': map['totalMessages'] ?? 0,
      };
    }
    return stats;
  }

  // Get recent messages (last N messages)
  Future<List<ChatMessageModel>> getRecentMessages(int limit) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => ChatMessageModel.fromMap(maps[i]));
  }

  // Update model response for a message
  Future<int> updateModelResponse(int messageId, String modelResponse) async {
    final db = await database;
    return await db.update(
      'chat_messages',
      {'modelResponse': modelResponse},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Delete a specific message
  Future<int> deleteMessage(int messageId) async {
    final db = await database;
    return await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Delete all messages for a task file
  Future<int> deleteMessagesForTask(String taskFilePath) async {
    final db = await database;
    return await db.delete(
      'chat_messages',
      where: 'taskFilePath = ?',
      whereArgs: [taskFilePath],
    );
  }

  // Clear all messages
  Future<int> clearAllMessages() async {
    final db = await database;
    return await db.delete('chat_messages');
  }

  // Get message count
  Future<int> getMessageCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM chat_messages',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Search messages by text
  Future<List<ChatMessageModel>> searchMessages(String searchTerm) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'message LIKE ? OR modelResponse LIKE ?',
      whereArgs: ['%$searchTerm%', '%$searchTerm%'],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ChatMessageModel.fromMap(maps[i]));
  }

  // Get messages by date range
  Future<List<ChatMessageModel>> getMessagesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessageModel.fromMap(maps[i]));
  }

  // Chat Session Management
  Future<int> createChatSession(ChatSessionModel session) async {
    final db = await database;
    return await db.insert('chat_sessions', session.toMap());
  }

  Future<List<ChatSessionModel>> getAllChatSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      orderBy: 'lastActivity DESC',
    );
    return List.generate(maps.length, (i) => ChatSessionModel.fromMap(maps[i]));
  }

  // Delete chat sessions with only 1 message and their associated messages
  Future<void> deleteSessionsWithOneMessage() async {
    final db = await database;

    // First, get all sessions with message count = 1
    final List<Map<String, dynamic>> sessionsToDelete = await db.query(
      'chat_sessions',
      where: 'messageCount = ?',
      whereArgs: [1],
    );

    // Delete messages for these sessions first (due to foreign key constraint)
    for (var session in sessionsToDelete) {
      await db.delete(
        'chat_messages',
        where: 'sessionId = ?',
        whereArgs: [session['id']],
      );
    }

    // Delete the sessions with message count = 1
    await db.delete('chat_sessions', where: 'messageCount = ?', whereArgs: [1]);
  }

  Future<ChatSessionModel?> getChatSession(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    if (maps.isNotEmpty) {
      return ChatSessionModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateChatSession(ChatSessionModel session) async {
    final db = await database;
    return await db.update(
      'chat_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteChatSession(int sessionId) async {
    final db = await database;
    // First delete all messages in this session
    await db.delete(
      'chat_messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
    // Then delete the session
    return await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteAllChatSessions() async {
    final db = await database;
    // Delete all messages first (due to foreign key constraint)
    await db.delete('chat_messages');
    // Then delete all sessions
    await db.delete('chat_sessions');
  }

  Future<List<ChatMessageModel>> getMessagesForSession(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessageModel.fromMap(maps[i]));
  }

  Future<List<ChatMessageModel>> getUserMessagesForSession(
    int sessionId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'sessionId = ? AND isUser = 1',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessageModel.fromMap(maps[i]));
  }

  Future<void> updateSessionActivity(int sessionId, String lastMessage) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      {
        'lastActivity': DateTime.now().millisecondsSinceEpoch,
        'lastMessage': lastMessage,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> incrementMessageCount(int sessionId) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE chat_sessions 
      SET messageCount = messageCount + 1 
      WHERE id = ?
    ''',
      [sessionId],
    );
  }

  Future<void> updateSessionTitle(int sessionId, String title) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      {'title': title},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<Map<String, dynamic>>> getSessionsNeedingTitleUpdate() async {
    final db = await database;
    // Get sessions that have "New Chat" title but have messages
    return await db.rawQuery('''
      SELECT cs.*, cm.message as firstMessage
      FROM chat_sessions cs
      LEFT JOIN (
        SELECT sessionId, message, ROW_NUMBER() OVER (PARTITION BY sessionId ORDER BY timestamp ASC) as rn
        FROM chat_messages 
        WHERE isUser = 1
      ) cm ON cs.id = cm.sessionId AND cm.rn = 1
      WHERE cs.title = 'New Chat' 
      AND cs.messageCount > 0
      AND cm.message IS NOT NULL
    ''');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
