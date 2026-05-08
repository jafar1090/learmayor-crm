import 'package:flutter/material.dart';

class Globals {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  static void showSnackBar(String message, {bool isError = false}) {
    // Small delay ensures the message appears after screen transitions complete
    Future.delayed(const Duration(milliseconds: 100), () {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}
