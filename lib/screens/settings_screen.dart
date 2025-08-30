import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';
import '../services/database_service.dart';
import '../services/task_file_service.dart';
import '../services/preferences_service.dart';
import 'import_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  String _selectedQueryType = 'cpu';
  bool _isLoadingPreferences = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoadingPreferences = true;
    });

    try {
      final queryType = await PreferencesService.getQueryType();
      setState(() {
        _selectedQueryType = queryType;
      });
    } catch (e) {
      print('Error loading preferences: $e');
    } finally {
      setState(() {
        _isLoadingPreferences = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.titleLarge),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Settings Section
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'App Settings',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Manage your preferences and data',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Settings Options
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              // Data Management Section
                              _buildSectionHeader('Data Management'),
                              const SizedBox(height: 16),

                              // Delete All Sessions
                              _buildSettingTile(
                                icon: Icons.delete_sweep,
                                title: 'Delete All Chat Sessions',
                                subtitle:
                                    'Remove all conversations and start fresh',
                                onTap: _showDeleteAllSessionsConfirmation,
                                isDestructive: true,
                              ),

                              const SizedBox(height: 16),

                              // Clean Inactive Sessions
                              _buildSettingTile(
                                icon: Icons.cleaning_services,
                                title: 'Clean Inactive Sessions',
                                subtitle: 'Remove sessions with only 1 message',
                                onTap: _cleanInactiveSessions,
                              ),

                              const SizedBox(height: 24),

                              // Processing Preferences Section
                              _buildSectionHeader('Processing Preferences'),
                              const SizedBox(height: 16),

                              // Query Type Selection
                              _buildQueryTypeSelector(),

                              const SizedBox(height: 24),

                              // Task File Section
                              _buildSectionHeader('Task File'),
                              const SizedBox(height: 16),

                              // Delete Task File
                              _buildSettingTile(
                                icon: Icons.delete_forever,
                                title: 'Delete Task File',
                                subtitle:
                                    'Remove current task file and all sessions',
                                onTap: _showDeleteTaskFileConfirmation,
                                isDestructive: true,
                              ),

                              const SizedBox(height: 24),

                              // App Info Section
                              _buildSectionHeader('App Information'),
                              const SizedBox(height: 16),

                              // App Version
                              _buildSettingTile(
                                icon: Icons.info_outline,
                                title: 'App Version',
                                subtitle: '1.0.0',
                                onTap: null,
                                showTrailing: false,
                              ),

                              // Build Date
                              _buildSettingTile(
                                icon: Icons.calendar_today,
                                title: 'Build Date',
                                subtitle: DateTime.now().toString().split(
                                  ' ',
                                )[0],
                                onTap: null,
                                showTrailing: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQueryTypeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.speed,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Method',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how to process your requests',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingPreferences)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryLight,
                  ),
                ),
              )
            else
              ...PreferencesService.getAvailableQueryTypes().map((queryType) {
                final isSelected = _selectedQueryType == queryType;
                final displayName = PreferencesService.getDisplayName(
                  queryType,
                );
                final description = PreferencesService.getDescription(
                  queryType,
                );
                final icon = PreferencesService.getIcon(queryType);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: queryType,
                    groupValue: _selectedQueryType,
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedQueryType = value;
                        });
                        await PreferencesService.setQueryType(value);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Processing method updated to ${PreferencesService.getDisplayName(value)}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    title: Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          displayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    activeColor: AppColors.primaryLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
    bool showTrailing = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.shade100
                : AppColors.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : AppColors.primaryLight,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red.shade700 : AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDestructive
                ? Colors.red.shade600
                : AppColors.textSecondary,
          ),
        ),
        trailing: showTrailing && onTap != null
            ? Icon(
                Icons.arrow_forward_ios,
                color: isDestructive
                    ? Colors.red.shade400
                    : AppColors.textSecondary,
                size: 16,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showDeleteAllSessionsConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Sessions'),
          content: const Text(
            'This will permanently delete ALL chat sessions and their messages. This action cannot be undone. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAllSessions();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.deleteAllChatSessions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All chat sessions deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting sessions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteTaskFileConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task File'),
          content: const Text(
            'This will delete the current task file and ALL associated chat sessions. You will need to import a new task file to continue. This action cannot be undone. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTaskFile();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTaskFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete all sessions first
      await _databaseService.deleteAllChatSessions();

      // Delete the task file
      await TaskFileService.deleteTaskFile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task file and all sessions deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to import screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ImportScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanInactiveSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.deleteSessionsWithOneMessage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inactive sessions cleaned up successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cleaning up sessions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
