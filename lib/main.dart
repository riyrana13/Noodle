import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/import_screen.dart';
import 'screens/task_manager_screen.dart';
import 'screens/chat_sessions_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noodle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/import': (context) => const ImportScreen(),
        '/task-manager': (context) => const TaskManagerScreen(),
        '/chat-sessions': (context) => const ChatSessionsScreen(),
      },
    );
  }
}
