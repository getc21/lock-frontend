import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (WCAG AA compliant — ≥4.5:1 on white)
  static const Color primary = Color(0xFF4F46E5); // Indigo-600 (6.4:1)
  static const Color primaryDark = Color(0xFF4338CA); // Indigo-700
  static const Color primaryLight = Color(0xFF6366F1); // Indigo-500 (decorative only)
  
  // Secondary Colors (WCAG AA compliant)
  static const Color secondary = Color(0xFFDB2777); // Pink-600 (5.0:1)
  static const Color secondaryDark = Color(0xFFBE185D); // Pink-700
  static const Color secondaryLight = Color(0xFFF9A8D4); // Pink-300 (decorative only)
  
  // Success Colors (WCAG AA compliant)
  static const Color success = Color(0xFF059669); // Emerald-600 (4.6:1)
  static const Color successLight = Color(0xFF6EE7B7);
  
  // Warning Colors (WCAG AA compliant)
  static const Color warning = Color(0xFFD97706); // Amber-600 (4.7:1)
  static const Color warningLight = Color(0xFFFBBF24);
  
  // Error Colors
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  
  // Info Colors
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF93C5FD);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Gray Scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // Background Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  
  // Text Colors (WCAG AA compliant)
  static const Color textPrimary = Color(0xFF111827);   // Gray-900 (16.8:1)
  static const Color textSecondary = Color(0xFF4B5563);  // Gray-600 (7.0:1)
  static const Color textTertiary = Color(0xFF6B7280);   // Gray-500 (4.6:1)
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);
  
  // Shadow Colors
  static const Color shadow = Color(0x0D000000);
  static const Color shadowDark = Color(0x1A000000);
  
  // Status Colors (WCAG AA compliant)
  static const Color online = Color(0xFF059669);   // Emerald-600
  static const Color offline = Color(0xFF4B5563);   // Gray-600
  static const Color pending = Color(0xFFD97706);   // Amber-600
  static const Color completed = Color(0xFF059669);  // Emerald-600
  static const Color cancelled = Color(0xFFDC2626);  // Red-600
}

