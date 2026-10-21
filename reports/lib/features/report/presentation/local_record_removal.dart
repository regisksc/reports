import 'package:flutter/material.dart';

Future<void> confirmLocalRemoval(
  BuildContext context, {
  required String title,
  required Future<void> Function() remove,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    animationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: const Text(
        'This removes only the local record. It does not cancel a City Service Request.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await remove();
    if (context.mounted) Navigator.pop(context);
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove this local record. Try again.'),
        ),
      );
    }
  }
}
