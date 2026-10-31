import  'package:flutter/material.dart';

class AppColors {
   AppColors._();

  // Base colors
  static const Color background =Color(0xFF85A1BC);
  static const Color navy = Color(0xFF0B1D51);
  static const Color white =  Color(0xFFFFFFFF);
  static const Color greyText = Color(0xFF5F6B7A);
  static const Color inactive = Color(0xFF8A93A3);

  // Status chips (background + text)
  static const Color openBg = Color(0xFFF8C6C6);
  static const Color openText = Color(0xFFC62828);
  static const Color inProgressBg = Color(0xFFB9CCF2);
  static const Color inProgressText = Color(0xFF1E3A8A);
  static const Color closedBg = Color(0xFF9BE39B);
  static const Color closedText = Color(0xFF1B5E20);

  // Priority buttons (Report a problem, step 1)
  static const Color normalPriority = Color(0xFF5B84D9);
  static const Color urgentPriority = Color(0xFFD98A8F);
  static const Color urgentText = Color(0xFFE53935);

  // Confirm Resolution buttons
  static const Color success = Color(0xFF10A310);
  static const Color danger = Color(0xFFD00F0F);

}