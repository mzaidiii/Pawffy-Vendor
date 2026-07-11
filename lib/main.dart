import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawffy/features/auth/auth_gate_screen.dart';
import 'package:pawffy/core/config/supabase_config.dart';

final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (!SupabaseConfig.useMockAuth) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => const ProviderScope(child: PawffyApp()),
    ),
  );
}

class PawffyApp extends ConsumerWidget {
  const PawffyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Pawffy',
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: const AuthGateScreen(),
    );
  }
}

class AppColors {
  static const Color orange = Color(0xFFE85D04);
  static const Color orangeLight = Color(0xFFFF6B1A);

  static const Color darkBg = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF232323);

  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111111);
  static const Color grey = Color(0xFF888888);
  static const Color greyLight = Color(0xFFCCCCCC);

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
}

ThemeData _lightTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.lightBg,
    primaryColor: AppColors.orange,
    colorScheme: const ColorScheme.light(
      primary: AppColors.orange,
      secondary: AppColors.orangeLight,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.black,
      onError: AppColors.white,
    ),
    textTheme: GoogleFonts.barlowTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w900,
        color: AppColors.black,
      ),
      displayMedium: GoogleFonts.barlow(
        fontWeight: FontWeight.w800,
        color: AppColors.black,
      ),
      displaySmall: GoogleFonts.barlow(
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
      headlineLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
      headlineMedium: GoogleFonts.barlow(
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
      titleLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      bodyLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w400,
        color: AppColors.black,
      ),
      bodyMedium: GoogleFonts.barlow(
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
      ),
      labelLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: 1.2,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBg,
      foregroundColor: AppColors.black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.barlow(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
        letterSpacing: 1.0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: GoogleFonts.barlow(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F2F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      hintStyle: GoogleFonts.barlow(
        color: AppColors.grey,
        fontWeight: FontWeight.w400,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.orange
            : Colors.transparent,
      ),
      side: const BorderSide(color: AppColors.orange, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}

ThemeData _darkTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.darkBg,
    primaryColor: AppColors.orange,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,
      secondary: AppColors.orangeLight,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
      onError: AppColors.white,
    ),
    textTheme: GoogleFonts.barlowTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w900,
        color: AppColors.white,
      ),
      displayMedium: GoogleFonts.barlow(
        fontWeight: FontWeight.w800,
        color: AppColors.white,
      ),
      displaySmall: GoogleFonts.barlow(
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      headlineLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      headlineMedium: GoogleFonts.barlow(
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      titleLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      bodyLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w400,
        color: AppColors.white,
      ),
      bodyMedium: GoogleFonts.barlow(
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
      ),
      labelLarge: GoogleFonts.barlow(
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: 1.2,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.barlow(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 1.0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: GoogleFonts.barlow(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      hintStyle: GoogleFonts.barlow(
        color: AppColors.grey,
        fontWeight: FontWeight.w400,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.orange
            : Colors.transparent,
      ),
      side: const BorderSide(color: AppColors.orange, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}
