import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';

class FileDropZone extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDragOver;
  final bool isLoading;
  final bool isSmallScreen;
  final bool isCopying;
  final double copyProgress;
  final String copyStatus;

  const FileDropZone({
    super.key,
    required this.onTap,
    this.isDragOver = false,
    this.isLoading = false,
    this.isSmallScreen = false,
    this.isCopying = false,
    this.copyProgress = 0.0,
    this.copyStatus = '',
  });

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: widget.isSmallScreen ? 120 : 140,
          maxHeight: widget.isSmallScreen ? 160 : 180,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isDragOver
                ? AppColors.primaryLight
                : AppColors.borderLight,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: widget.isDragOver
              ? AppColors.borderLight.withOpacity(0.3)
              : Colors.transparent,
        ),
        child: (widget.isLoading || widget.isCopying)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isCopying) ...[
                      CircularProgressIndicator(
                        value: widget.copyProgress,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Copying file... ${(widget.copyProgress * 100).toInt()}%',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.copyStatus.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.copyStatus,
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ] else ...[
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    size: widget.isSmallScreen ? 36 : 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: widget.isSmallScreen ? 12 : 16),
                  Text(
                    'Click here or drag your .task file',
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: widget.isSmallScreen ? 12 : 16),
                  ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Browse Files',
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
