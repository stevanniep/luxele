import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxele/splashScreenPage.dart';
import 'package:luxele/loginPage.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://bnjjclwlxlrtduupunfw.supabase.co',
    anonKey: 'sb_publishable_JL8x0bo17UvFdojemnZipw_CBSYxfY9',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Final Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF8D6E63)),
        useMaterial3: true,
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return _showSplash
        ? SplashScreen(
            onFinish: () {
              setState(() => _showSplash = false);
            },
          )
        : const LoginPage();
  }
}
