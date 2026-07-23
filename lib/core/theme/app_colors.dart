import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF17171F);
  static const Color surfaceVariant = Color(0xFF1F1F29);
  static const Color border = Color(0xFF2A2A36);

  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryVariant = Color(0xFF5B3FE0);
  static const Color secondary = Color(0xFF33E0C2);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA0A0AC);
  static const Color textDisabled = Color(0xFF5C5C68);

  static const Color error = Color(0xFFFF5A6E);
  static const Color success = Color(0xFF35D07F);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8C6BFF), Color.fromARGB(255, 85, 52, 250)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scrimGradient = LinearGradient(
    colors: [Color(0x000B0B0F), Color(0xFF0B0B0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
