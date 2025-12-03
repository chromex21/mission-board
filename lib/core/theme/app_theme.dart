import 'package:flutter/material.dart';

class AppTheme {
  // GitHub-inspired color palette
  static const primaryPurple = Color(0xFF8B5CF6); // Purple accent
  static const darkGrey = Color(0xFF0D1117); // GitHub dark background
  static const grey900 = Color(0xFF161B22); // Card background
  static const grey800 = Color(0xFF21262D); // Elevated surface
  static const grey700 = Color(0xFF30363D); // Border color
  static const grey600 = Color(0xFF484F58); // Subtle text
  static const grey400 = Color(0xFF8B949E); // Muted text
  static const grey200 = Color(0xFFC9D1D9); // Primary text
  static const white = Color(0xFFF0F6FC); // Bright text

  // Status colors
  static const successGreen = Color(0xFF3FB950);
  static const warningOrange = Color(0xFFDB6D28);
  static const errorRed = Color(0xFFDA3633);
  static const infoBlue = Color(0xFF58A6FF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkGrey,
      primaryColor: primaryPurple,
      colorScheme: ColorScheme.dark(
        primary: primaryPurple,
        secondary: primaryPurple,
        surface: grey900,
        error: errorRed,
        onPrimary: white,
        onSecondary: white,
        onSurface: grey200,
        onError: white,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: grey900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: grey200),
        toolbarHeight: 56,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: grey900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: grey700, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: grey700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: grey700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: errorRed),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: TextStyle(color: grey400),
        hintStyle: TextStyle(color: grey600),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPurple,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: grey200,
          side: BorderSide(color: grey700),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          color: white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: TextStyle(
          color: white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: grey200,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: grey200,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: grey200,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: grey200,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: grey400,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: grey200,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: grey400,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: grey600,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(color: grey700, thickness: 1, space: 1),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: grey900,
        selectedItemColor: primaryPurple,
        unselectedItemColor: grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: primaryPurple,
        unselectedLabelColor: grey400,
        indicatorColor: primaryPurple,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),

      // Icon theme
      iconTheme: IconThemeData(color: grey200, size: 20),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: grey800,
        labelStyle: TextStyle(color: grey200, fontSize: 12),
        side: BorderSide(color: grey700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
