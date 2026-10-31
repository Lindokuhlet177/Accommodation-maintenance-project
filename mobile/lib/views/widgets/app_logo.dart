import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// The StudentStayFix logo, with a text version until logo.png is added.
class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({super.key, this.height = 110});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      errorBuilder: (_, __, ___) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_repair_service,
              size: height * 0.55, color: AppColors.navy),
          Text(
            'StudentStayFix',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: height * 0.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}