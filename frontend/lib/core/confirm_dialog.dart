import 'package:flutter/material.dart';
import 'theme.dart';

Future<bool> showConfirmDialog(BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  Color confirmColor = CivilTheme.error,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: CivilTheme.surface,
      title: Text(title, style: const TextStyle(color: CivilTheme.textPrimary)),
      content: Text(message, style: const TextStyle(color: CivilTheme.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel, style: const TextStyle(color: CivilTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showToast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? CivilTheme.error : CivilTheme.secondary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
