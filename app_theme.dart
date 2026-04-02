import 'package:flutter/material.dart';

class AppTheme {
  // ─── Colors ───────────────────────────────────────────────────────────────
  static const Color bg           = Color(0xFF17212B);
  static const Color bgSecondary  = Color(0xFF1C2733);
  static const Color bgTertiary   = Color(0xFF242F3D);
  static const Color surface      = Color(0xFF1E2D3D);
  static const Color surfaceLight = Color(0xFF2B5278);

  static const Color accent       = Color(0xFF2AABEE);
  static const Color accentDark   = Color(0xFF1A8CC8);
  static const Color green        = Color(0xFF4CAF50);
  static const Color red          = Color(0xFFFF5252);
  static const Color orange       = Color(0xFFFF9800);

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B9DAD);
  static const Color textHint      = Color(0xFF5D7487);

  static const Color bubbleOut  = Color(0xFF2B5278);
  static const Color bubbleIn   = Color(0xFF1E2D3D);
  static const Color divider    = Color(0xFF0D1821);

  // ─── Text styles ──────────────────────────────────────────────────────────
  static const TextStyle title = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: textHint,
  );
  static const TextStyle message = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 1.4,
  );
  static const TextStyle time = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: textHint,
  );

  // ─── Theme data ───────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    primaryColor: accent,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accentDark,
      surface: bgSecondary,
      background: bg,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgSecondary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      iconTheme: IconThemeData(color: accent),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgSecondary,
      selectedItemColor: accent,
      unselectedItemColor: textHint,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textHint, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    ),
    dividerColor: divider,
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
  );
}
