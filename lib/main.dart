import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'ai/inference_controller.dart';
import 'core/i18n.dart';
import 'core/theme.dart';
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
    final tok = brightness == Brightness.light ? AppThemeTokens.light : AppThemeTokens.dark;
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: tok.backgroundPrimary,
      appBarTheme: AppBarTheme(
        backgroundColor: tok.backgroundPrimary,
        elevation: 0,
        foregroundColor: tok.textPrimary,
        iconTheme: IconThemeData(color: tok.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: tok.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tok.border),
        ),
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: tok.primary,
        onPrimary: isLight ? Colors.white : tok.textPrimary,
        secondary: tok.secondaryAccent,
        onSecondary: isLight ? Colors.white : tok.textPrimary,
        error: tok.error,
        onError: Colors.white,
        surface: tok.surface,
        onSurface: tok.textPrimary,
        outline: tok.border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tok.navSurface,
        indicatorColor: tok.navIndicator,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: tok.primary);
          }
          return IconThemeData(color: tok.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tok.primary);
          }
          return TextStyle(fontSize: 12, color: tok.textSecondary);
        }),
      ),
      dividerColor: tok.border,
      dialogTheme: DialogThemeData(
        backgroundColor: tok.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tok.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tok.surface,
        modalBackgroundColor: tok.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? tok.textPrimary : tok.surfaceElevated,
        contentTextStyle: TextStyle(color: isLight ? tok.backgroundPrimary : tok.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tok.surface,
        hintStyle: TextStyle(color: tok.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tok.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tok.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tok.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tok.buttonPrimary,
          foregroundColor: tok.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tok.primary,
          side: BorderSide(color: tok.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tok.primary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tok.chipBackground,
        selectedColor: tok.primary.withValues(alpha: 0.18),
        side: BorderSide(color: tok.border),
        labelStyle: TextStyle(color: tok.textPrimary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  Widget build(BuildContext context) => PopScope(
        canPop: i == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (i != 0) {
            setState(() => i = 0);
          }
        },
        child: Scaffold(
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
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: tr('nav_home')),
              NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: tr('nav_learn')),
              NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: tr('nav_ask')),
              NavigationDestination(icon: const Icon(Icons.school_outlined), selectedIcon: const Icon(Icons.school), label: tr('nav_schol')),
              NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: tr('nav_mentor')),
              NavigationDestination(icon: const Icon(Icons.share_outlined), selectedIcon: const Icon(Icons.share), label: tr('nav_share')),
            ],
          ),
        ),
      );
}
