import 'package:flutter/material.dart';

extension SnackBarExtension on BuildContext {
  void showErrorSnackBar(String message , Color color) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
