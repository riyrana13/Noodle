import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class TaskFileService {
  static Future<bool> doesTaskFileExist() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final taskFilePath = path.join(appDir.path, 'model.task');
      final taskFile = File(taskFilePath);

      return await taskFile.exists();
    } catch (e) {
      // If there's any error checking the file, assume it doesn't exist
      return false;
    }
  }

  static Future<String?> getTaskFilePath() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final taskFilePath = path.join(appDir.path, 'model.task');
      final taskFile = File(taskFilePath);

      if (await taskFile.exists()) {
        return taskFilePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteTaskFile() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final taskFilePath = path.join(appDir.path, 'model.task');
      final taskFile = File(taskFilePath);

      if (await taskFile.exists()) {
        await taskFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
