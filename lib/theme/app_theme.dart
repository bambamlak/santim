import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Soft Material You Seed Color (Slate / Blue-Grey)
  static const Color seedColor = Color(0xFFD97706);

  // Softer Status Colors
  static const Color statusIncome = Color(0xFF66BB6A); // Soft Green
  static const Color statusExpense = Color(0xFFEF5350); // Soft Red
  static const Color statusWarning = Color(0xFFFFCA28); // Soft Amber

  // Spacing
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Predefined Color Palettes - Removed the last three as requested
  static const Map<String, Color> palettes = {
    'Amber Glow': Color(0xFFD97706),
    'Teal Zen': Color(0xFF0D9488),
    'Ocean Blue': Color(0xFF0061A4),
    'Forest Zen': Color(0xFF15803D),
  };

  // Typography
  static TextTheme _buildTextTheme(Color color, String langCode) {
    TextStyle baseStyle;
    if (langCode == 'am') {
      baseStyle = GoogleFonts.getFont('Menbere');
    } else {
      baseStyle = GoogleFonts.plusJakartaSans();
    }

    return TextTheme(
      displayLarge: baseStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: langCode == 'am' ? 0 : -0.32,
        color: color,
      ),
      headlineMedium: baseStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: langCode == 'am' ? 0 : -0.09,
        color: color,
      ),
      bodyMedium: baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: color,
      ),
      labelSmall: baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: langCode == 'am' ? 0 : 0.5,
      ),
    );
  }

  static Decoration cardDecoration(
    BuildContext context, {
    bool showShadow = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    return BoxDecoration(
      color: isDark
          ? (isAmoled
                ? Colors.grey[900]?.withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.9))
          : Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.15),
      ),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  // Light Theme
  static ThemeData lightTheme(Color seed, String langCode) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      textTheme: _buildTextTheme(colorScheme.onSurface, langCode),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF1F5F9),
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle:
            (langCode == 'am'
                    ? GoogleFonts.getFont('Menbere')
                    : GoogleFonts.plusJakartaSans())
                .copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          (langCode == 'am'
                  ? GoogleFonts.getFont('Menbere')
                  : GoogleFonts.plusJakartaSans())
              .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle:
            (langCode == 'am'
                    ? GoogleFonts.getFont('Menbere')
                    : GoogleFonts.plusJakartaSans())
                .copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
        labelStyle:
            (langCode == 'am'
                    ? GoogleFonts.getFont('Menbere')
                    : GoogleFonts.plusJakartaSans())
                .copyWith(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme(
    Color seed,
    String langCode, {
    bool isAmoled = false,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    // Default dark bg should be deeper and adapt to seed
    // Using a deep mix of neutral and seed color
    final defaultBg = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.05),
      const Color(0xFF0B0F1A),
    );
    final scaffoldBg = isAmoled ? Colors.black : defaultBg;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: _buildTextTheme(colorScheme.onSurface, langCode),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle:
            (langCode == 'am'
                    ? GoogleFonts.getFont('Menbere')
                    : GoogleFonts.plusJakartaSans())
                .copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
      ),
      cardTheme: CardThemeData(
        color: isAmoled
            ? const Color(0xFF121212)
            : colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle:
            (langCode == 'am'
                    ? GoogleFonts.getFont('Menbere')
                    : GoogleFonts.plusJakartaSans())
                .copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
        labelStyle:
            (langCode == 'am'
                    ? GoogleFonts.getFont('Menbere')
                    : GoogleFonts.plusJakartaSans())
                .copyWith(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.4),
            width: 1.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.4),
            width: 1.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          (langCode == 'am'
                  ? GoogleFonts.getFont('Menbere')
                  : GoogleFonts.plusJakartaSans())
              .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
