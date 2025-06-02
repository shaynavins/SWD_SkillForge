import 'package:flutter/material.dart';

class AppTheme {
  // Main Colors
  static const primaryColor = Color(0xFF4A90E2);    // Bright blue
  static const secondaryColor = Color(0xFF5C6BC0);  // Indigo
  static const accentColor = Color(0xFF7C4DFF);     // Vibrant purple
  static const backgroundColor = Color(0xFFF5F7FA);  // Light grey-blue background
  
  // Text Colors
  static const textColor = Color(0xFF2C3E50);       // Dark blue-grey text
  static const textColorSecondary = Color(0xFF546E7A); // Medium blue-grey
  static const textColorLight = Color(0xFFFFFFFF);   // White text
  
  // UI Element Colors
  static const cardColor = Color(0xFFFFFFFF);       // White cards
  static const dividerColor = Color(0xFFE0E7FF);    // Light blue divider
  static const errorColor = Color(0xFFE74C3C);      // Bright red
  static const successColor = Color(0xFF2ECC71);    // Bright green
  static const warningColor = Color(0xFFF39C12);    // Bright orange
  
  // Button Colors
  static const buttonColor = Color(0xFF4A90E2);     // Bright blue
  static const buttonColorSecondary = Color(0xFF5C6BC0); // Indigo
  static const iconColor = Color(0xFF4A90E2);       // Bright blue

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: 0.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textColorSecondary,
    letterSpacing: 0.2,
  );

  // Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.1),
        spreadRadius: 0,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static InputDecoration textFieldDecoration({
    required String labelText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: textColorSecondary),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: iconColor) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: buttonColor,
    foregroundColor: textColorLight,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 2,
    shadowColor: buttonColor.withOpacity(0.4),
  );

  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: textColorLight,
        onSecondary: textColorLight,
        onSurface: textColor,
        onBackground: textColor,
        onError: textColorLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textColorLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColorLight),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColorSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: elevatedButtonStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
      ),
      iconTheme: const IconThemeData(
        color: iconColor,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 24,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: textColorLight,
        elevation: 4,
        splashColor: accentColor.withOpacity(0.3),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle: TextStyle(color: textColorLight),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: headingStyle,
        contentTextStyle: bodyStyle,
      ),
      listTileTheme: ListTileThemeData(
        textColor: textColor,
        iconColor: iconColor,
        tileColor: Colors.transparent,
        selectedTileColor: primaryColor.withOpacity(0.1),
      ),
    );
  }
} 