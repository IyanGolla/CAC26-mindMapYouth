import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../core/launch.dart';

/// Calm offer of support. Shown once, nothing is recorded, easy to dismiss.
Future<void> showSupportPrompt(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("You don't have to go through this alone.",
                style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'It sounds like things are heavy right now. A trained person is '
              'there to listen any time, for free. Only you can see what you '
              'wrote here.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: crisisButtonStyle(sheet),
              icon: const Icon(Icons.call),
              label: const Text('Call 988'),
              onPressed: () => open(sheet, telUri('988'),
                  fallback: 'Dial 988 on any phone.'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: crisisButtonStyle(sheet),
              icon: const Icon(Icons.sms),
              label: const Text('Text 988'),
              onPressed: () => open(sheet, smsUri('988'),
                  fallback: 'Text 988 from any phone.'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.of(sheet).pop();
                context.push('/crisis');
              },
              child: const Text('See more options'),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheet).pop(),
              child: const Text('Not right now'),
            ),
          ],
        ),
      ),
    ),
  );
}
