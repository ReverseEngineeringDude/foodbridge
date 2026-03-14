import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE8630A);
  static const Color secondary = Color(0xFF2D6A4F);
  static const Color accent = Color(0xFFF4A261);
  static const Color background = Color(0xFFFAFAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // Status Colors
  static const Color available = Color(0xFF10B981); // Emerald
  static const Color accepted = Color(0xFF0EA5E9);  // Sky blue
  static const Color pickedUp = Color(0xFFF59E0B);  // Amber
  static const Color delivered = Color(0xFF14B8A6); // Teal
  static const Color expired = Color(0xFF94A3B8);   // Muted grey
}

class AppDesign {
  static const double cardRadius = 24.0;
  static const double buttonRadius = 16.0;
  static const double padding = 20.0;
  static const double margin = 16.0;

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(15),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];
}
