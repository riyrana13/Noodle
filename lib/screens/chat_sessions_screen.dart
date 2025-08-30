import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';
import '../models/chat_session_model.dart';
import '../services/database_service.dart';
import 'task_manager_screen.dart';
import 'settings_screen.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<ChatSessionModel> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      await _databaseService.deleteSessionsWithOneMessage();

      // Fix existing sessions that need title updates
      await _fixExistingSessionTitles();

      final sessions = await _databaseService.getAllChatSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading sessions: $e')));
    }
  }

  Future<void> _fixExistingSessionTitles() async {
    try {
      final sessionsNeedingUpdate = await _databaseService
          .getSessionsNeedingTitleUpdate();

      for (final sessionData in sessionsNeedingUpdate) {
        final sessionId = sessionData['id'] as int;
        final firstMessage = sessionData['firstMessage'] as String?;

        if (firstMessage != null && firstMessage.isNotEmpty) {
          String newTitle;
          if (firstMessage.length > 50) {
            newTitle = '${firstMessage.substring(0, 50)}...';
          } else {
            newTitle = firstMessage;
          }

          await _databaseService.updateSessionTitle(sessionId, newTitle);
          print(
            '🔄 [ChatSessionsScreen] Fixed session $sessionId title to: "$newTitle"',
          );
        }
      }

      if (sessionsNeedingUpdate.isNotEmpty) {
        print(
          '✅ [ChatSessionsScreen] Fixed ${sessionsNeedingUpdate.length} session titles',
        );
      }
    } catch (e) {
      print('❌ [ChatSessionsScreen] Error fixing session titles: $e');
    }
  }

  Future<void> _createNewSession() async {
    final now = DateTime.now();
    final sessionTitle = 'New Chat';

    final newSession = ChatSessionModel(
      title: sessionTitle,
      createdAt: now,
      lastActivity: now,
      taskFilePath: 'model.task',
      messageCount: 0,
    );

    try {
      final sessionId = await _databaseService.createChatSession(newSession);

      // Navigate to the new chat session
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TaskManagerScreen(sessionId: sessionId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating session: $e')));
    }
  }

  Future<void> _deleteSession(ChatSessionModel session) async {
    try {
      await _databaseService.deleteChatSession(session.id!);
      await _loadSessions(); // Reload the list
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session deleted')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting session: $e')));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCleanupConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clean Up Sessions'),
          content: const Text(
            'This will remove all chat sessions with only 1 message (inactive sessions). This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cleanupInactiveSessions();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Clean Up'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cleanupInactiveSessions() async {
    try {
      await _databaseService.deleteSessionsWithOneMessage();
      await _loadSessions(); // Reload the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inactive sessions cleaned up successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cleaning up sessions: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task File'),
          content: const Text(
            'Are you sure you want to delete the current task file? This action cannot be undone and will remove all associated chat sessions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTaskFile();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTaskFile() async {
    try {
      // Navigate back to import screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/import');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Sessions', style: AppTextStyles.titleLarge),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _fixExistingSessionTitles();
              await _loadSessions();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session titles refreshed!')),
                );
              }
            },
            tooltip: 'Refresh Session Titles',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: Column(
            children: [
              // Drawer Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Noodle',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Task Management Assistant',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer Items
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Chat Sessions
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.list,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        title: const Text(
                          'Chat Sessions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: const Text('View all conversations'),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ChatSessionsScreen(),
                            ),
                          );
                        },
                      ),

                      const Divider(height: 1),

                      // Clean Up Sessions
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cleaning_services,
                            color: Colors.blue,
                          ),
                        ),
                        title: const Text(
                          'Clean Up Sessions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: const Text('Remove inactive sessions'),
                        onTap: () {
                          Navigator.pop(context);
                          _showCleanupConfirmation();
                        },
                      ),

                      const Divider(height: 1),

                      // Settings
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.orange,
                          ),
                        ),
                        title: const Text(
                          'Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: const Text('App preferences'),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),

                      const Spacer(),

                      // Delete Task File
                      Container(
                        margin: const EdgeInsets.all(16),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                          ),
                          title: const Text(
                            'Delete Task File',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          subtitle: const Text('Remove current task file'),
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            _showDeleteConfirmation();
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Sessions List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryLight,
                              ),
                            ),
                          )
                        : _sessions.isEmpty
                        ? _buildEmptyState()
                        : _buildSessionsList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No chat sessions yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation to get started',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _createNewSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: AppColors.buttonText,
            ),
            child: const Text('Start New Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                session.title == 'New Chat'
                    ? 'N'
                    : session.title == 'Image Chat'
                    ? 'I'
                    : session.title[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              session.title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.lastMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    session.lastMessage!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.message,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${session.messageCount} messages',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _formatTime(session.lastActivity),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteSession(session);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      TaskManagerScreen(sessionId: session.id!),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
