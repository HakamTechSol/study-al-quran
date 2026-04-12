import 'package:flutter/material.dart';

/// 🌈 APP COLOR MANAGER CLASS
/// Easily manage light & dark themes + dynamic color switching
class AppColors {
  // 🔹 App Info
  static const String appMainName = 'Study Al Quran';
  static const String appPowerBy = 'Powered By Malik';

  // ------------------------------
  // 🔹 COMMON COLORS (used globally)
  // ------------------------------
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF303030);
  static const Color transparent = Colors.transparent;

  // ------------------------------
  // 🔹 THEME COLOR SETS
  // ------------------------------
  // ✅ Default Green Theme
  static const Color greenPrimary = Color.fromARGB(255, 44, 105, 230);
  static const Color greenLight = Color.fromARGB(255, 44, 105, 230);
  static const Color greenGradient = Color.fromARGB(255, 44, 105, 230);
  static const Color greenOpposite = Color(0xFF3EB4DB);

  // 🔵 Blue Theme
  static const Color bluePrimary = Color(0xFF2D86A4);
  static const Color blueLight = Color(0xFF5BD1F8);
  static const Color blueGradient = Color(0xFF3CA7CA);
  static const Color blueOpposite = Color.fromARGB(255, 114, 178, 230);

  // 🔴 Red Theme
  static const Color redPrimary = Color(0xFFE53935);
  static const Color redLight = Color(0xFFFF6F60);
  static const Color redGradient = Color(0xFFFFA07A);
  static const Color redOpposite = Color(0xFF56CCF2);

  // ------------------------------
  // 🔹 ACTIVE THEME COLORS
  // ------------------------------
  static Color primary = greenPrimary;
  static Color primaryLight = greenLight;
  static Color gradient = greenGradient;
  static Color opposite = greenOpposite;

  static Color card = lightGrey;
  static Color background = white;
  static Color text = black;
  static Color subtitle = grey;
  static Color border = const Color(0xFFE0E0E0);

  // ------------------------------
  // 🔹 DARK THEME COLORS
  // ------------------------------
  static Color darkBackground = const Color(0xFF121212);
  static Color darkCard = const Color(0xFF1E1E1E);
  static Color darkText = white;
  static Color darkSubtitle = Colors.grey.shade400;
  static Color darkBorder = Colors.grey.shade700;

  // ------------------------------
  // 🔹 STATUS COLORS
  // ------------------------------
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // ------------------------------
  // 🔹 ACCENT COLORS
  // ------------------------------
  static const Color accent = Color(0xFFFF6B9D);
  static const Color secondaryAccent = Color(0xFF00D4AA);

  // ------------------------------
  // 🔹 SURFACE & OVERLAY COLORS
  // ------------------------------
  static Color surface = const Color(0xFFF3F4F8);
  static Color darkSurface = const Color(0xFF232330);
  
  static Color overlay = const Color(0xFF000000).withOpacity(0.5);
  static Color shadow = const Color(0xFF000000).withOpacity(0.1);

  // ------------------------------
  // 🔹 HOVER & FOCUS STATES (for Web)
  // ------------------------------
  static Color hoverPrimary = greenPrimary;
  static Color hoverCard = const Color(0xFFFAFAFD);
  static Color focusBorder = greenPrimary;

  // ------------------------------
  // 🔹 CURRENT MODE FLAGS
  // ------------------------------
  static bool isDarkMode = false;
  static String currentTheme = 'green'; // "green" | "blue" | "red"

  // =======================================================
  // 🔹 FUNCTIONS TO CHANGE THEME DYNAMICALLY
  // =======================================================

  /// Switch between multiple color themes
  static void switchTheme(String theme) {
    currentTheme = theme;

    switch (theme) {
      case 'blue':
        primary = bluePrimary;
        primaryLight = blueLight;
        gradient = blueGradient;
        opposite = blueOpposite;
        hoverPrimary = bluePrimary;
        focusBorder = bluePrimary;
        break;
      case 'red':
        primary = redPrimary;
        primaryLight = redLight;
        gradient = redGradient;
        opposite = redOpposite;
        hoverPrimary = redPrimary;
        focusBorder = redPrimary;
        break;
      default: // green theme
        primary = greenPrimary;
        primaryLight = greenLight;
        gradient = greenGradient;
        opposite = greenOpposite;
        hoverPrimary = greenPrimary;
        focusBorder = greenPrimary;
    }
  }

  /// Toggle light/dark mode
  static void toggleDarkMode(bool enableDark) {
    isDarkMode = enableDark;
    if (enableDark) {
      background = darkBackground;
      card = darkCard;
      text = darkText;
      subtitle = darkSubtitle;
      border = darkBorder;
      surface = darkSurface;
      hoverCard = const Color(0xFF232333);
      overlay = const Color(0xFF000000).withOpacity(0.7);
      shadow = const Color(0xFF000000).withOpacity(0.3);
    } else {
      background = white;
      card = lightGrey;
      text = black;
      subtitle = grey;
      border = const Color(0xFFE0E0E0);
      surface = const Color(0xFFF3F4F8);
      hoverCard = const Color(0xFFFAFAFD);
      overlay = const Color(0xFF000000).withOpacity(0.5);
      shadow = const Color(0xFF000000).withOpacity(0.1);
    }
  }

  // =======================================================
  // 🔹 GRADIENT PRESETS
  // =======================================================
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, gradient],
      );

  static LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, secondaryAccent],
      );

  static LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryLight.withOpacity(0.05),
          background,
          gradient.withOpacity(0.08),
        ],
      );

  // =======================================================
  // 🔹 CHART & BADGE COLORS
  // =======================================================
  static List<Color> get chartColors => [
        primary,
        gradient,
        accent,
        secondaryAccent,
        warning,
        info,
      ];

  static Color get badgeActive => success;
  static Color get badgeInactive => grey;
  static Color get badgePending => warning;

  // =======================================================
  // 🔹 THEME DATA (for MaterialApp)
  // =======================================================
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: card,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: black),
        bodyMedium: TextStyle(color: black),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primary,
      cardColor: darkCard,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: white),
        bodyMedium: TextStyle(color: white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// 💡 How to Use in App

// import 'color_constants.dart';

// // 🌈 To change theme
// AppColors.switchTheme('blue'); // or 'red' / 'green'

// // 🌙 To enable dark mode
// AppColors.toggleDarkMode(true);

// // In your MaterialApp:
// MaterialApp(
//   theme: AppColors.lightTheme,
//   darkTheme: AppColors.darkTheme,
//   themeMode: AppColors.isDarkMode ? ThemeMode.dark : ThemeMode.light,
// )