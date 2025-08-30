import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color primaryDark = Color(0xFF5C3E9E);
  static const Color primaryLight = Color(0xFFFFC0CB);

  // Background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,

    end: Alignment.bottomCenter,
    colors: [primaryDark, primaryLight],
  );

  // Card colors
  static const Color cardBackground = Colors.white;
  static const Color cardShadow = Color(0x1A000000);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF666666);
  static const Color textDark = Color(0xFF333333);

  // Border colors
  static const Color borderLight = Color(0xFFD8CFF0);

  // Button colors
  static const Color buttonPrimary = primaryDark;
  static const Color buttonText = Colors.white;
}
