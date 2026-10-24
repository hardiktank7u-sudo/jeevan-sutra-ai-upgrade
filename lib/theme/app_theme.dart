// Jeevan Sutra - Living Intelligence Theme System
// Botanical Ayurvedic Design System from Google AI Studio
import 'package:flutter/material.dart';

class JeevanSutraColors {
  // Brand Color Palette
  static const Color forestGreen = Color(0xFF174C3C);
  static const Color deepBotanical = Color(0xFF10382E);
  static const Color freshLeaf = Color(0xFF75B98A);
  static const Color warmIvory = Color(0xFFF7F6F0);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softSage = Color(0xFFE5EEE4);
  static const Color mutedGold = Color(0xFFC6A76A);
  static const Color mainText = Color(0xFF202A25);
  static const Color secondaryText = Color(0xFF737C74);
  static const Color subtleBorder = Color(0xFFE4E8E0);

  // Dark Theme Palette
  static const Color darkCanvas = Color(0xFF0C1914);
  static const Color darkSurface = Color(0xFF13251E);
  static const Color darkSurfaceElevated = Color(0xFF1A332A);
  static const Color darkTextPrimary = Color(0xFFE8EEE9);
  static const Color darkTextSecondary = Color(0xFF9EAAA2);
  static const Color darkBorder = Color(0xFF1F3B30);

  // Functional Accents
  static const Color vataColor = Color(0xFF5B8FB9);
  static const Color pittaColor = Color(0xFFE27D60);
  static const Color kaphaColor = Color(0xFF85A389);
}

class JeevanSutraTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: JeevanSutraColors.forestGreen,
      scaffoldBackgroundColor: JeevanSutraColors.warmIvory,
      cardColor: JeevanSutraColors.pureWhite,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: JeevanSutraColors.forestGreen,
        onPrimary: JeevanSutraColors.pureWhite,
        secondary: JeevanSutraColors.freshLeaf,
        onSecondary: JeevanSutraColors.deepBotanical,
        tertiary: JeevanSutraColors.mutedGold,
        onTertiary: JeevanSutraColors.pureWhite,
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        surface: JeevanSutraColors.pureWhite,
        onSurface: JeevanSutraColors.mainText,
        outline: JeevanSutraColors.subtleBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: JeevanSutraColors.forestGreen),
        titleTextStyle: TextStyle(
          color: JeevanSutraColors.forestGreen,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: JeevanSutraColors.forestGreen,
          foregroundColor: JeevanSutraColors.pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: JeevanSutraColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: JeevanSutraColors.subtleBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: JeevanSutraColors.subtleBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: JeevanSutraColors.freshLeaf,
      scaffoldBackgroundColor: JeevanSutraColors.darkCanvas,
      cardColor: JeevanSutraColors.darkSurface,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: JeevanSutraColors.freshLeaf,
        onPrimary: JeevanSutraColors.deepBotanical,
        secondary: JeevanSutraColors.softSage,
        onSecondary: JeevanSutraColors.darkCanvas,
        tertiary: JeevanSutraColors.mutedGold,
        onTertiary: JeevanSutraColors.darkCanvas,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        surface: JeevanSutraColors.darkSurface,
        onSurface: JeevanSutraColors.darkTextPrimary,
        outline: JeevanSutraColors.darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: JeevanSutraColors.freshLeaf),
        titleTextStyle: TextStyle(
          color: JeevanSutraColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: JeevanSutraColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: JeevanSutraColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}

/// Backwards compatibility bridge for any existing references
class AppTheme {
  AppTheme._();

  static const Color bgDark = JeevanSutraColors.darkCanvas;
  static const Color bgSurface = JeevanSutraColors.darkSurface;
  static const Color bgSurfaceElevated = JeevanSutraColors.darkSurfaceElevated;
  static const Color bgCard = JeevanSutraColors.pureWhite;
  static const Color bgCardLight = JeevanSutraColors.softSage;

  static const Color gold = JeevanSutraColors.mutedGold;
  static const Color goldLight = JeevanSutraColors.mutedGold;
  static const Color goldBright = JeevanSutraColors.mutedGold;
  static const Color goldDark = Color(0xFFA67C1E);
  static const Color goldMuted = Color(0xFF8A6E27);

  static const Color emerald = JeevanSutraColors.freshLeaf;
  static const Color emeraldLight = JeevanSutraColors.freshLeaf;
  static const Color emeraldDeep = JeevanSutraColors.deepBotanical;
  static const Color forestGreen = JeevanSutraColors.forestGreen;

  static const Color textPrimary = JeevanSutraColors.mainText;
  static const Color textSecondary = JeevanSutraColors.secondaryText;
  static const Color textMuted = JeevanSutraColors.secondaryText;
  static const Color textGold = JeevanSutraColors.mutedGold;

  static const Color borderGold = JeevanSutraColors.subtleBorder;
  static const Color borderGoldSubtle = JeevanSutraColors.subtleBorder;
  static const Color borderEmerald = JeevanSutraColors.subtleBorder;

  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33174C3C);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [JeevanSutraColors.mutedGold, Color(0xFFB59355)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [JeevanSutraColors.forestGreen, JeevanSutraColors.deepBotanical],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [JeevanSutraColors.forestGreen, JeevanSutraColors.deepBotanical],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkLuxuryTheme => JeevanSutraTheme.darkTheme;
}
