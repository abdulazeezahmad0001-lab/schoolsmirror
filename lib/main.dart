import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'screens/login_screen.dart';
import 'screens/student_home.dart';
import 'screens/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.loadToken();
  runApp(const SchoolsMirrorApp());
}

class SchoolsMirrorApp extends StatelessWidget {
  const SchoolsMirrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchoolsMirror',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A57A5)),
      ),
      initialRoute: '/',
      routes: {
        '/':        (_) => const LoginScreen(),
        '/student': (_) => const StudentHome(),
        '/admin':   (_) => const AdminHome(),
      },
    );
  }
}
