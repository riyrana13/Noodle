import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';
import '../services/task_file_service.dart';
import '../services/database_service.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import '../services/preferences_service.dart';
import 'chat_sessions_screen.dart';
import 'settings_screen.dart';

class TaskManagerScreen extends StatefulWidget {
  final int? sessionId;

  const TaskManagerScreen({super.key, this.sessionId});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  String? _error;
  String? _attachedImagePath;
  String _currentTaskFile = 'model.task';
  String _queryType = 'cpu'; // Will be loaded from preferences
  int? _currentSessionId;
  bool _showChatCreation = false; // Track if we should show chat creation UI
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _loadPreferences();
    _loadInitialMessage();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Screen is focused, refresh preferences
      _loadPreferences();
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final queryType = await PreferencesService.getQueryType();
      setState(() {
        _queryType = queryType;
      });
    } catch (e) {
      print('Error loading preferences: $e');
      // Keep default value
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessage() async {
    try {
      final exists = await TaskFileService.doesTaskFileExist();
      if (exists) {
        if (_currentSessionId != null) {
          // Load messages for specific session
          final dbMessages = await _databaseService.getMessagesForSession(
            _currentSessionId!,
          );

          if (dbMessages.isEmpty) {
            // Add welcome message if no previous messages
            final welcomeMessage = ChatMessageModel(
              message:
                  "Hello! I'm Noodle, your task management assistant. I can help you with your tasks. What would you like to know?",
              isUser: false,
              timestamp: DateTime.now(),
              processingTimeMs: 0,
              queryType: _queryType,
              taskFilePath: _currentTaskFile,
              sessionId: _currentSessionId,
            );

            await _databaseService.insertChatMessage(welcomeMessage);

            // Update session activity for welcome message
            if (_currentSessionId != null) {
              await _databaseService.updateSessionActivity(
                _currentSessionId!,
                welcomeMessage.message,
              );
              await _databaseService.incrementMessageCount(_currentSessionId!);
            }

            setState(() {
              _messages.add(
                ChatMessageModel(
                  message: welcomeMessage.message,
                  isUser: false,
                  timestamp: welcomeMessage.timestamp,
                  processingTimeMs: 0,
                  queryType: _queryType,
                  taskFilePath: _currentTaskFile,
                  sessionId: _currentSessionId,
                ),
              );
            });
          } else {
            // Load existing messages
            setState(() {
              _messages.clear();
              for (var dbMessage in dbMessages) {
                _messages.add(
                  ChatMessageModel(
                    message: dbMessage.message,
                    isUser: dbMessage.isUser,
                    timestamp: dbMessage.timestamp,
                    imagePath: dbMessage.imagePath,
                    processingTimeMs: dbMessage.processingTimeMs,
                    queryType: dbMessage.queryType,
                    taskFilePath: dbMessage.taskFilePath,
                    sessionId: dbMessage.sessionId,
                  ),
                );
              }
            });
          }
        } else {
          // No session provided, show chat creation UI
          setState(() {
            _showChatCreation = true;
          });
        }
      } else {
        setState(() {
          _error = 'Task file not found';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading task file: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    // Enable wake lock to prevent device from sleeping during processing
    WakelockPlus.enable();

    final message = _messageController.text.trim();
    if (message.isEmpty && _attachedImagePath == null) {
      WakelockPlus.disable(); // Disable wake lock if returning early
      return;
    }

    final startTime = DateTime.now();

    final userMessage = ChatMessageModel(
      message: message.isEmpty ? 'Image sent' : message,
      isUser: true,
      timestamp: startTime,
      imagePath: _attachedImagePath,
      processingTimeMs: 0,
      queryType: _queryType,
      taskFilePath: _currentTaskFile,
      sessionId: _currentSessionId,
    );

    // Check if this is the first user message in the session BEFORE inserting
    if (_currentSessionId != null) {
      print(
        '🔍 [_sendMessage] Checking session $_currentSessionId for title update...',
      );
      final session = await _databaseService.getChatSession(_currentSessionId!);
      print(
        '🔍 [_sendMessage] Retrieved session: ${session?.title} (messageCount: ${session?.messageCount})',
      );

      // Check if this is the first USER message (not counting AI welcome messages)
      final userMessages = await _databaseService.getUserMessagesForSession(
        _currentSessionId!,
      );
      final isFirstUserMessage = userMessages.isEmpty;
      print(
        '🔍 [_sendMessage] User messages count: ${userMessages.length}, isFirstUserMessage: $isFirstUserMessage',
      );

      if (session != null && isFirstUserMessage) {
        // This is the first USER message, update the session title
        print(
          '🔄 [_sendMessage] First USER message detected, updating session title...',
        );
        print(
          '📊 [_sendMessage] Current messageCount: ${session.messageCount}, User messages: ${userMessages.length}',
        );

        String newTitle;
        if (message.isNotEmpty && message.trim().isNotEmpty) {
          // Use the first user message as title (truncate if too long)
          final cleanMessage = message.trim();
          newTitle = cleanMessage.length > 50
              ? '${cleanMessage.substring(0, 50)}...'
              : cleanMessage;
          print('📝 [_sendMessage] Setting title to user message: "$newTitle"');
        } else if (_attachedImagePath != null) {
          // If only image is attached, use "Image Chat"
          newTitle = 'Image Chat';
          print('🖼️ [_sendMessage] Setting title to: "$newTitle"');
        } else {
          // Fallback to "New Chat"
          newTitle = 'New Chat';
          print('💬 [_sendMessage] Setting title to: "$newTitle"');
        }

        print('💾 [_sendMessage] Updating session title in database...');
        await _databaseService.updateSessionTitle(_currentSessionId!, newTitle);
        print(
          '✅ [_sendMessage] Session title updated successfully to: "$newTitle"',
        );

        // Verify the update by fetching the session again
        final updatedSession = await _databaseService.getChatSession(
          _currentSessionId!,
        );
        print(
          '🔍 [_sendMessage] Verification - Updated session title: ${updatedSession?.title}',
        );
      } else {
        print(
          'ℹ️ [_sendMessage] Not first USER message (messageCount: ${session?.messageCount}, userMessages: ${userMessages.length}), keeping existing title',
        );
        print(
          '🔍 [_sendMessage] Session details: title="${session?.title}", createdAt=${session?.createdAt}, lastActivity=${session?.lastActivity}',
        );
      }
    }

    // Save user message to database
    final userMessageId = await _databaseService.insertChatMessage(userMessage);

    // Update session activity and increment message count
    if (_currentSessionId != null) {
      await _databaseService.updateSessionActivity(
        _currentSessionId!,
        userMessage.message,
      );
      await _databaseService.incrementMessageCount(_currentSessionId!);
    }

    setState(() {
      _messages.add(
        ChatMessageModel(
          message: userMessage.message,
          isUser: true,
          timestamp: userMessage.timestamp,
          imagePath: _attachedImagePath,
          processingTimeMs: 0,
          queryType: _queryType,
          taskFilePath: _currentTaskFile,
          sessionId: _currentSessionId,
        ),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Call method channel to get AI response
    await _getAIResponse(message, startTime, userMessageId);
  }

  Future<void> _getAIResponse(
    String userMessage,
    DateTime startTime,
    int userMessageId,
  ) async {
    try {
      // Call method channel to get AI response
      const platform = MethodChannel('noodle_channel');

      final taskFilePath = await TaskFileService.getTaskFilePath();
      print(taskFilePath);
      // Prepare the data to send to native side
      final Map<String, dynamic> arguments = {
        'message': userMessage,
        'taskFilePath': taskFilePath,
        'sessionId': _currentSessionId,
        'queryType': _queryType,
        'hasImage': _attachedImagePath != null,
        'imagePath': _attachedImagePath,
        'type': _queryType,
      };

      // Call the method channel
      final String response = await platform.invokeMethod(
        'giveResponse',
        arguments,
      );

      if (!mounted) return;

      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;

      // Create AI response model
      final aiMessage = ChatMessageModel(
        message: response,
        isUser: false,
        timestamp: endTime,
        processingTimeMs: processingTime,
        queryType: _queryType,
        modelResponse: response,
        taskFilePath: _currentTaskFile,
        sessionId: _currentSessionId,
      );

      // Save AI response to database
      await _databaseService.insertChatMessage(aiMessage);

      // Update session activity and increment message count for AI response
      if (_currentSessionId != null) {
        await _databaseService.updateSessionActivity(
          _currentSessionId!,
          aiMessage.message,
        );
        await _databaseService.incrementMessageCount(_currentSessionId!);
      }

      setState(() {
        _messages.add(
          ChatMessageModel(
            message: response,
            isUser: false,
            timestamp: endTime,
            processingTimeMs: processingTime,
            queryType: _queryType,
            modelResponse: response,
            taskFilePath: _currentTaskFile,
            sessionId: _currentSessionId,
          ),
        );
        _isLoading = false;
        _attachedImagePath = null;
      });

      _scrollToBottom();

      // Disable wake lock after successful AI response processing
      WakelockPlus.disable();
    } catch (e) {
      if (!mounted) return;

      // Handle error - show fallback response
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;

      String fallbackResponse =
          "I'm sorry, I encountered an error processing your request. Please try again.";

      // Create AI response model with fallback
      final aiMessage = ChatMessageModel(
        message: fallbackResponse,
        isUser: false,
        timestamp: endTime,
        processingTimeMs: processingTime,
        queryType: _queryType,
        modelResponse: fallbackResponse,
        taskFilePath: _currentTaskFile,
        sessionId: _currentSessionId,
      );

      // Save AI response to database
      await _databaseService.insertChatMessage(aiMessage);

      // Update session activity and increment message count for AI response
      if (_currentSessionId != null) {
        await _databaseService.updateSessionActivity(
          _currentSessionId!,
          aiMessage.message,
        );
        await _databaseService.incrementMessageCount(_currentSessionId!);
      }

      setState(() {
        _messages.add(
          ChatMessageModel(
            message: fallbackResponse,
            isUser: false,
            timestamp: endTime,
            processingTimeMs: processingTime,
            queryType: _queryType,
            modelResponse: fallbackResponse,
            taskFilePath: _currentTaskFile,
            sessionId: _currentSessionId,
          ),
        );
        _isLoading = false;
      });

      _scrollToBottom();

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting AI response: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Always disable wake lock when AI response processing is complete
      WakelockPlus.disable();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _createNewChat() async {
    try {
      final now = DateTime.now();
      final sessionTitle = 'New Chat';

      final newSession = ChatSessionModel(
        title: sessionTitle,
        createdAt: now,
        lastActivity: now,
        taskFilePath: _currentTaskFile,
        messageCount: 0,
        lastMessage: null,
      );

      final sessionId = await _databaseService.createChatSession(newSession);

      setState(() {
        _currentSessionId = sessionId;
        _showChatCreation = false;
      });

      // Load the new session
      await _loadInitialMessage();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating chat: $e')));
    }
  }

  Widget _buildChatCreationUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large chat icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Welcome text
          const Text(
            'Welcome to Noodle',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          const Text(
            'Your AI Task Management Assistant',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Create new chat button
          Container(
            width: 200,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: _createNewChat,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Start New Chat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // View existing chats button
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChatSessionsScreen(),
                ),
              );
            },
            child: const Text(
              'View Existing Chats',
              style: TextStyle(fontSize: 14, color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primaryLight,
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primaryLight,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Save image to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'task_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File(path.join(appDir.path, fileName));

        // Copy the picked image to app directory
        await File(image.path).copy(savedImage.path);

        // Store the image path for the next message
        setState(() {
          _attachedImagePath = savedImage.path;
        });

        // Show preview in input area
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
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
      final deleted = await TaskFileService.deleteTaskFile();
      if (deleted && mounted) {
        Navigator.of(context).pushReplacementNamed('/import');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error deleting file')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SafeArea(
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _showChatCreation ? 'Noodle' : 'Noodle Chat',
            style: AppTextStyles.titleLarge,
          ),
          centerTitle: true,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        drawer: Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.only(top: 8)),
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
                                builder: (context) =>
                                    const ChatSessionsScreen(),
                              ),
                            );
                          },
                        ),

                        const Divider(height: 1),

                        // Task File Info
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.file_present,
                              color: Colors.green,
                            ),
                          ),
                          title: const Text(
                            'Task File',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text('$_currentTaskFile'),
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
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: _showChatCreation
              ? _buildChatCreationUI()
              : Column(
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 8)),
                    // Chat Messages
                    Expanded(
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              // Messages List
                              Expanded(
                                child: _messages.isEmpty
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.primaryLight,
                                              ),
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.all(16),
                                        itemCount:
                                            _messages.length +
                                            (_isLoading ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index == _messages.length) {
                                            return _buildTypingIndicator();
                                          }
                                          return _buildMessage(
                                            _messages[index],
                                          );
                                        },
                                      ),
                              ),

                              // Input Area
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Image Preview
                                    if (_attachedImagePath != null) ...[
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                File(_attachedImagePath!),
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        width: 60,
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                          size: 24,
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Image attached',
                                                    style: AppTextStyles
                                                        .bodyMedium
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                  Text(
                                                    'Tap to remove',
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _attachedImagePath = null;
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              tooltip: 'Remove Image',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    // Message Input
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _addImage,
                                          icon: const Icon(
                                            Icons.camera_alt_outlined,
                                            color: AppColors.primaryDark,
                                          ),
                                          tooltip: 'Add Image',
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: _messageController,
                                            decoration: InputDecoration(
                                              hintText:
                                                  _attachedImagePath != null
                                                  ? 'Type your message...'
                                                  : 'Ask me anything...',
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            maxLines: null,
                                            textInputAction:
                                                TextInputAction.send,
                                            onSubmitted: (_) => _sendMessage(),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _sendMessage,
                                          icon: const Icon(
                                            Icons.send,
                                            color: AppColors.primaryDark,
                                          ),
                                          tooltip: 'Send Message',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessageModel message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primaryLight
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: message.isUser
                          ? AppColors.textDark
                          : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
