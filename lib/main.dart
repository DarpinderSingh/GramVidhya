import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'ai/inference_controller.dart';
import 'core/i18n.dart';
import 'data/auth_service.dart';
import 'data/store.dart';
import 'data/translation_service.dart';
import 'screens/chat.dart';
import 'screens/curriculum.dart';
import 'screens/home.dart';
import 'screens/scholarships.dart';
import 'screens/share.dart';
import 'screens/mentor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('app');
  await restoreLanguage();
  _restoreTheme();
  await TranslationService.init();
  final ai = InferenceController();
  await ai.init();
  final auth = AuthService();
  runApp(GramVidyaApp(ai: ai, auth: auth));
}

/// Global theme mode notifier — persisted via Store.
final appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

void _restoreTheme() {
  final saved = Store.themeMode;
  switch (saved) {
    case 'light': appThemeMode.value = ThemeMode.light; break;
    case 'dark':  appThemeMode.value = ThemeMode.dark;  break;
    default:      appThemeMode.value = ThemeMode.system; break;
  }
}

Future<void> setThemeMode(ThemeMode mode) async {
  appThemeMode.value = mode;
  final s = mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system';
  await Store.setThemeMode(s);
}

class GramVidyaApp extends StatelessWidget {
  const GramVidyaApp({super.key, required this.ai, required this.auth});
  final InferenceController ai;
  final AuthService auth;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: appLang,
        builder: (_, __, ___) => ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeMode,
          builder: (_, themeMode, ___) => MaterialApp(
            title: tr('app_title'),
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: Shell(ai: ai, auth: auth),
          ),
        ),
      );

  ThemeData _buildTheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAF7F0), // Warm beige
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAF7F0),
          elevation: 0,
          foregroundColor: Color(0xFF1C1917),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFFFDF8),
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2563EB), // Restrained blue accent
          secondary: Color(0xFF3B82F6),
          surface: Color(0xFFFFFDF8),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFFFDF8),
          indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
        ),
      );
    }
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep navy
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        elevation: 0,
        foregroundColor: Color(0xFFF8FAFC),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6), // Restrained blue accent
        secondary: Color(0xFF6366F1),
        surface: Color(0xFF1E293B),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.ai, required this.auth});
  final InferenceController ai;
  final AuthService auth;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: IndexedStack(index: i, children: [
            HomeScreen(ai: widget.ai, auth: widget.auth),
            const CurriculumScreen(),
            ChatScreen(ai: widget.ai),
            const ScholarshipScreen(),
            MentorScreen(ai: widget.ai),
            ShareScreen(ai: widget.ai),
          ]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => setState(() => i = v),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: tr('nav_home')),
            NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: tr('nav_learn')),
            NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: tr('nav_ask')),
            NavigationDestination(icon: const Icon(Icons.school_outlined), selectedIcon: const Icon(Icons.school), label: tr('nav_schol')),
            NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: tr('nav_mentor')),
            NavigationDestination(icon: const Icon(Icons.share_outlined), selectedIcon: const Icon(Icons.share), label: tr('nav_share')),
          ],
        ),
      );
}
