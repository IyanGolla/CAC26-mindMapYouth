import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/launch.dart';
import 'crisis_lines.dart';

class CrisisHubScreen extends StatelessWidget {
  const CrisisHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Help now')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text("You don't have to go through this alone.", style: t.headlineSmall),
          const SizedBox(height: 8),
          Text(lifeline988.about, style: t.bodyLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: crisisButtonStyle(context),
                  icon: const Icon(Icons.call),
                  label: const Text('Call 988'),
                  onPressed: () => open(context, telUri('988'),
                      fallback: 'Dial 988 on any phone.'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: crisisButtonStyle(context),
                  icon: const Icon(Icons.sms),
                  label: const Text('Text 988'),
                  onPressed: () => open(context, smsUri('988'),
                      fallback: 'Text 988 from any phone.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.emergency),
            label: const Text('In immediate danger? Call 911'),
            onPressed: () =>
                open(context, telUri('911'), fallback: 'Dial 911.'),
          ),
          const SizedBox(height: 20),
          const _WhatHappens(),
          const SizedBox(height: 20),
          Text('More people to reach', style: t.titleMedium),
          const SizedBox(height: 8),
          for (final line in otherCrisisLines) ...[
            _LineCard(line),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Text(
            'This app can\'t see what you write and can\'t contact anyone for '
            'you. Reaching out is always your choice.',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _WhatHappens extends StatelessWidget {
  const _WhatHappens();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        title: const Text('What will happen if I call or text?'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('• A trained person will listen. They won\'t judge you.'),
          SizedBox(height: 6),
          Text('• You don\'t need a plan, or a reason that feels "big enough."'),
          SizedBox(height: 6),
          Text('• You can stay anonymous with the person on the line.'),
          SizedBox(height: 6),
          Text('• You can end the call or text any time.'),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard(this.line);
  final CrisisLine line;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line.name, style: t.titleMedium),
            const SizedBox(height: 4),
            Text(line.about),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (line.call != null)
                  FilledButton.tonalIcon(
                    style: tonalButtonStyle(context),
                    icon: const Icon(Icons.call),
                    label: Text('Call ${line.callLabel ?? line.call}'),
                    onPressed: () => open(context, telUri(line.call!),
                        fallback: 'Call ${line.call}.'),
                  ),
                if (line.text != null)
                  FilledButton.tonalIcon(
                    style: tonalButtonStyle(context),
                    icon: const Icon(Icons.sms),
                    label: Text(line.textBody == null
                        ? 'Text ${line.text}'
                        : 'Text ${line.textBody} to ${line.text}'),
                    onPressed: () => open(
                      context,
                      smsUri(line.text!, body: line.textBody),
                      fallback: line.textBody == null
                          ? 'Text ${line.text}.'
                          : 'Text ${line.textBody} to ${line.text}.',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
