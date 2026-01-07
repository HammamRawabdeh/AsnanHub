import 'package:flutter/material.dart';

final ThemeData asnanTheme = ThemeData(
  useMaterial3: true,
  primaryColor: const Color(0xFF1A73E8),
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),

  colorScheme: const ColorScheme.light(
    primary: Color(0xFF1A73E8),
    secondary: Color(0xFF009688),
    error: Color(0xFFD32F2F),
  ),
      inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      
    ),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF1A73E8),
    elevation: 0,
    centerTitle: true,
  ),

  // cardTheme: CardTheme(
  //   color: const Color(0xFFFFFFFF),
  //   elevation: 2,
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.circular(16),
  //   ),
  // ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1A73E8),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF009688),
      side: const BorderSide(color: Color(0xFF009688)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
);
