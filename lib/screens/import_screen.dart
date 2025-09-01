import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';
import '../widgets/file_drop_zone.dart';
import '../services/file_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  bool _isCopying = false;
  double _copyProgress = 0.0;
  String _copyStatus = '';
  String? _status;
  bool _isSuccess = false;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _handleFileImport() async {
    // Enable wake lock to prevent device from sleeping
    WakelockPlus.enable();

    setState(() {
      _isLoading = true;
      _isCopying = false;
      _copyProgress = 0.0;
      _copyStatus = '';
      _status = null;
    });

    try {
      final fileName = await FileService.pickAndStoreTaskFile(
        onProgress: (progress, bytesCopied, totalBytes) {
          setState(() {
            _isCopying = true;
            _copyProgress = progress;
            _copyStatus =
                '${_formatBytes(bytesCopied)} / ${_formatBytes(totalBytes)}';
          });
        },
      );

      if (fileName != null) {
        setState(() {
          _status = 'Task file imported successfully!';
          _isSuccess = true;
        });

        // Navigate to task manager screen after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/task-manager');
          }
        });
      } else {
        setState(() {
          _status = 'No file selected.';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = e.toString().replaceAll('Exception: ', '');
        _isSuccess = false;
      });
    } finally {
      // Disable wake lock when process is complete
      WakelockPlus.disable();

      setState(() {
        _isLoading = false;
        _isCopying = false;
        _copyProgress = 0.0;
        _copyStatus = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Noodle', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Import your .task files and let Noodle manage your workflow with intelligence and elegance.',
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Card
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Container(
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: isSmallScreen ? 16 : 20),

                          // Import Title
                          const Text(
                            'Import .task file',
                            style: AppTextStyles.titleMedium,
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),

                          // Instruction Text
                          const Text(
                            'Drag and drop your .task file here or click to browse',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 24),

                          // File Drop Zone
                          FileDropZone(
                            onTap: _handleFileImport,
                            isLoading: _isLoading,
                            isSmallScreen: isSmallScreen,
                            isCopying: _isCopying,
                            copyProgress: _copyProgress,
                            copyStatus: _copyStatus,
                          ),

                          // Status Message
                          if (_status != null) ...[
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _isSuccess
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isSuccess
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _status!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _isSuccess
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
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
}
