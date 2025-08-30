import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileService {
  static Future<String?> pickAndStoreTaskFile({
    Function(double progress, int bytesCopied, int totalBytes)? onProgress,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['task'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileExtension = path.extension(filePath).toLowerCase();

        if (fileExtension != '.task') {
          throw Exception(
            'Please select a .task file. Selected file has extension: $fileExtension',
          );
        }

        // Check if file exists and is readable
        final pickedFile = File(filePath);
        if (!await pickedFile.exists()) {
          throw Exception('Selected file does not exist');
        }

        try {
          await pickedFile.openRead().first;
        } catch (e) {
          throw Exception('Selected file is not readable');
        }

        String pickedPath = filePath;
        String fileName = path.basename(pickedPath);

        final appDir = await getApplicationDocumentsDirectory();
        final targetFilePath = path.join(appDir.path, 'model.task');
        final targetFile = File(targetFilePath);

        // Delete existing file if it exists
        if (await targetFile.exists()) {
          await targetFile.delete();
        }

        // Copy file with progress tracking
        final sourceFile = File(pickedPath);
        final totalBytes = await sourceFile.length();
        final sourceStream = sourceFile.openRead();
        final sink = targetFile.openWrite();

        int bytesCopied = 0;
        await for (final chunk in sourceStream) {
          bytesCopied += chunk.length;
          sink.add(chunk);

          // Report progress
          if (onProgress != null) {
            onProgress(bytesCopied / totalBytes, bytesCopied, totalBytes);
          }
        }

        await sink.close();
        return 'model.task';
      }
      return null;
    } catch (e) {
      throw Exception(e);
    }
  }

  static Future<List<String>> getStoredTaskFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync();

      return files
          .where((file) => file is File && path.extension(file.path) == '.task')
          .map((file) => path.basename(file.path))
          .toList();
    } catch (e) {
      throw Exception('Error getting stored files: $e');
    }
  }
}
