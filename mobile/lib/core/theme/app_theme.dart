import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      surface: AppColors.white,

    ),


    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.navy,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.navy,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    // Text: navy headings and body
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
              color: AppColors.navy, fontSize: 26, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(
              color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: AppColors.navy, fontSize: 14),
          bodySmall: TextStyle(color: AppColors.greyText, fontSize: 12),
        ),

        // Solid navy buttons: Login, Next, Submit, Report a problem
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Outlined buttons: Back to Home, Confirm Resolution
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppColors.navy, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // White rounded input fields: Login, Sign up
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
        ),

        // White rounded cards: request cards, profile sections
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),

        // Bottom navigation: Home, My Requests, Profile
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.navy,
          unselectedItemColor: AppColors.inactive,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
  
  
}