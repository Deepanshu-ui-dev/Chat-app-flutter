import 'package:chat_app/screens/auth.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/skeleton/chathome.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

// Modern Design System Colors (Zinc/Minimal)
class AppColors {
  static const Color primary = Color(0xFF09090B); // Zinc 950
  static const Color secondary = Color(0xFF71717A); // Zinc 500
  static const Color accent = Color(0xFF09090B);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE4E4E7); // Zinc 200
  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF71717A);
  
  // Chat specific
  static const Color sentBubble = Color(0xFF09090B);
  static const Color sentText = Colors.white;
  static const Color receivedBubble = Color(0xFFF4F4F5); // Zinc 100
  static const Color receivedText = Color(0xFF09090B);
  static const Color inputBg = Color(0xFFF4F4F5);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chatify',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // Assuming standard font or default
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: CircleBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ChatHomeSkeleton();
          }

          final session = snapshot.data?.session;

          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Something went wrong")),
            );
          }

          if (session != null) {
            return const HomeScreen();
          }

          return const AuthScreen();
        },
      ),
    );
  }
}