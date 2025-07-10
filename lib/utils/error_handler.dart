import 'package:flutter/material.dart';

/// Utility untuk menampilkan error/alert via SnackBar
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

