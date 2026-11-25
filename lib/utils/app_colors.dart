import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0E8F86);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0B6E62);
  static const Color primaryExtraLight = Color(0xFFE3F5F3);

  // Manager / Hospital Onboarding & Status Teal Theme (M6-M11)
  static const Color tealPrimary = Color(0xFF0F8C7C);
  static const Color tealDark = Color(0xFF0B6E62);
  static const Color tealLight = Color(0xFFE6F4F1);
  static const Color tealBorder = Color(0xFF14B8A6);

  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);
  static const Color infoText = Color(0xFF1E40AF);

  static const Color rejectedBg = Color(0xFFFEE2E2);
  static const Color rejectedText = Color(0xFFDC2626);

  static const Color suspendedBg = Color(0xFFFEF3C7);
  static const Color suspendedBorder = Color(0xFFFDE68A);
  static const Color suspendedText = Color(0xFFB45309);

  static const Color accent = Color(0xFF0E8F86);
  static const Color accentLight = Color(0xFFE3F5F3);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);

  // Admin Module Palette
  static const Color adminPrimary = Color(0xFF0D6E6E);
  static const Color adminPrimaryLight = Color(0xFFE0F2F1);
  static const Color adminPrimaryDark = Color(0xFF00695C);

  static const Color adminPendingBg = Color(0xFFFEF3C7);
  static const Color adminPendingText = Color(0xFFD97706);

  static const Color adminApprovedBg = Color(0xFFD1FAE5);
  static const Color adminApprovedText = Color(0xFF059669);

  static const Color adminSuspendedBg = Color(0xFFFEE2E2);
  static const Color adminSuspendedText = Color(0xFFDC2626);
  static const Color adminSuspendedBorder = Color(0xFFFCA5A5);

  static const Color adminRejectBg = Color(0xFFFDE8E8);
  static const Color adminRejectText = Color(0xFFDC2626);

  static const Color adminBlue = Color(0xFF2563EB);
  static const Color adminBlueBg = Color(0xFFDBEAFE);
  static const Color adminPurple = Color(0xFF7C3AED);
  static const Color adminPurpleBg = Color(0xFFEDE9FE);
  static const Color adminOrange = Color(0xFFEA580C);


  static const Color darkGreen = Color(0xFF0E8F86);
  static const Color DarkGreen = darkGreen;
  static const Color lightGreenWhistish = Color(0xFFE3F5F3);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
}
