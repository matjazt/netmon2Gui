import 'package:flutter/material.dart';

import 'errors.dart';

/// Shows a simple error dialog with [title] and the message derived from [error].
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required Object error,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(errorMessage(error)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Shows a text-input dialog and returns the trimmed value, or null if cancelled.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  String? initialValue,
}) {
  final ctrl = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
