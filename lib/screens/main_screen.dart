import 'package:flutter/material.dart';
import '../services/task_file_service.dart';
import 'import_screen.dart';
import 'task_manager_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isLoading = true;
  bool _taskFileExists = false;

  @override
  void initState() {
    super.initState();
    _checkTaskFile();
  }

  Future<void> _checkTaskFile() async {
    try {
      final exists = await TaskFileService.doesTaskFileExist();
      setState(() {
        _taskFileExists = exists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _taskFileExists = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _taskFileExists ? const TaskManagerScreen() : const ImportScreen();
  }
}
