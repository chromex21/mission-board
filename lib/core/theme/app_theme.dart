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

  // Light theme colors
  static const lightBg = Color(0xFFE8ECEF); // Softer grey background
  static const lightCard = Color(0xFFF6F8FA); // Off-white cards for less glare
  static const lightBorder = Color(0xFFD0D7DE); // Light border
  static const lightText = Color(0xFF1F2328); // Darker text for better contrast
  static const lightSubtext = Color(0xFF656D76); // Darker muted text

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: primaryPurple,
      colorScheme: ColorScheme.light(
        primary: primaryPurple,
        secondary: primaryPurple,
        surface: lightCard,
        error: errorRed,
        onPrimary: white,
        onSecondary: white,
        onSurface: lightText,
        onError: white,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: lightCard,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: lightText),
        toolbarHeight: 56,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: lightBorder),
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
        labelStyle: TextStyle(color: lightSubtext),
        hintStyle: TextStyle(color: lightSubtext),
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
          foregroundColor: lightText,
          side: BorderSide(color: lightBorder),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: lightText,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          color: lightText,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: TextStyle(
          color: lightText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: lightText,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: lightText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: lightText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: lightText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: lightText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: lightText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: lightText,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: lightSubtext,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: lightText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: lightSubtext,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: lightSubtext,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: primaryPurple,
        unselectedItemColor: lightSubtext,
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
        unselectedLabelColor: lightSubtext,
        indicatorColor: primaryPurple,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),

      // Icon theme
      iconTheme: IconThemeData(color: lightText, size: 20),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: lightBg,
        labelStyle: TextStyle(color: lightText, fontSize: 12),
        side: BorderSide(color: lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

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

  static ThemeData get blueTheme {
    // A cool blue aurora theme with rich blue accents
    const deepBlue = Color(0xFF0A1628); // Deep blue-black background
    const blueTint = Color(0xFF1E293B); // Blue-tinted surface
    const brightBlue = Color(0xFF3B82F6); // Rich blue accent
    const skyBlue = Color(0xFF60A5FA); // Lighter blue for highlights

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlue,
      primaryColor: brightBlue,
      colorScheme: const ColorScheme.dark(
        primary: brightBlue,
        secondary: skyBlue,
        surface: blueTint,
        error: errorRed,
        onPrimary: white,
        onSecondary: white,
        onSurface: grey200,
        onError: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: blueTint,
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
      cardTheme: CardThemeData(
        color: blueTint,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: brightBlue, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: blueTint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: brightBlue, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: brightBlue, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: skyBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: grey400),
        hintStyle: const TextStyle(color: grey600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightBlue,
          foregroundColor: white,
          elevation: 4,
          shadowColor: brightBlue.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brightBlue,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: grey200,
          side: const BorderSide(color: grey700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      textTheme: darkTheme.textTheme,
      dividerTheme: const DividerThemeData(
        color: brightBlue,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: blueTint,
        selectedItemColor: brightBlue,
        unselectedItemColor: grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: brightBlue,
        unselectedLabelColor: grey400,
        indicatorColor: brightBlue,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
      iconTheme: const IconThemeData(color: grey200, size: 20),
      chipTheme: ChipThemeData(
        backgroundColor: blueTint,
        labelStyle: const TextStyle(color: grey200, fontSize: 12),
        side: const BorderSide(color: brightBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
