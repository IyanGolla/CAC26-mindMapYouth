import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../app/theme.dart';
import '../../core/launch.dart';
import 'locator_screen.dart' show verifiedLabel;

/// Where "Report a problem" drafts go. Leave empty to hide the link.
const reportEmail = '';

class ResourceDetailScreen extends ConsumerWidget {
  const ResourceDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches =
        ref.watch(servicesProvider).resources.where((r) => r.id == id);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('That listing isn\'t available.')),
      );
    }
    final r = matches.first;
    final t = Theme.of(context).textTheme;

    Widget fact(IconData icon, String? value) => value == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(value)),
              ],
            ),
          );

    final cost = switch (r.cost) {
      'free' => 'Free',
      'sliding' => 'Sliding scale (pay what you can)',
      'insurance' => 'Takes insurance',
      _ => r.cost,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(r.name, style: t.headlineSmall),
          const SizedBox(height: 4),
          Text(r.statewide ? 'Statewide' : '${r.county} County'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final type in r.types) Chip(label: Text(type)),
              if (r.telehealth) const Chip(label: Text('phone or video')),
              if (r.lgbtqAffirming) const Chip(label: Text('LGBTQ+ affirming')),
            ],
          ),
          const SizedBox(height: 12),
          fact(Icons.schedule, r.hours),
          fact(Icons.cake_outlined, r.ages == null ? null : 'Ages ${r.ages}'),
          fact(Icons.payments_outlined, cost),
          fact(
            Icons.translate,
            r.languages.isEmpty
                ? null
                : r.languages
                    .map((l) => const {'en': 'English', 'es': 'Spanish'}[l] ?? l)
                    .join(', '),
          ),
          fact(Icons.info_outline, r.notes),
          const SizedBox(height: 8),
          if (r.phone != null) ...[
            FilledButton.icon(
              icon: const Icon(Icons.call),
              label: Text('Call ${r.phone}'),
              onPressed: () => open(context, telUri(r.phone!),
                  fallback: 'Call ${r.phone}.'),
            ),
            const SizedBox(height: 10),
          ],
          if (r.text != null) ...[
            FilledButton.tonalIcon(
              style: tonalButtonStyle(context),
              icon: const Icon(Icons.sms),
              label: Text(r.textBody == null
                  ? 'Text ${r.text}'
                  : 'Text ${r.textBody} to ${r.text}'),
              onPressed: () => open(
                  context, smsUri(r.text!, body: r.textBody),
                  fallback: 'Text ${r.text}.'),
            ),
            const SizedBox(height: 10),
          ],
          if (r.hasLocation) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.directions),
              label: const Text('Directions (opens your maps app)'),
              onPressed: () => open(
                  context, directionsUri(r.lat!, r.lng!, r.name),
                  fallback: 'No maps app found.'),
            ),
            const SizedBox(height: 10),
          ],
          if (r.website != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Website (opens your browser)'),
              onPressed: () => open(context, Uri.parse(r.website!),
                  fallback: r.website!),
            ),
          if (r.whatToExpect != null) ...[
            const SizedBox(height: 20),
            Text('What to expect', style: t.titleMedium),
            const SizedBox(height: 6),
            Text(r.whatToExpect!),
          ],
          const SizedBox(height: 20),
          Text(verifiedLabel(r), style: t.bodySmall),
          if (r.source != null) Text('Source: ${r.source}', style: t.bodySmall),
          if (reportEmail.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => open(
                  context,
                  Uri(
                    scheme: 'mailto',
                    path: reportEmail,
                    query: 'subject=${Uri.encodeComponent('Problem with listing ${r.id}')}',
                  ),
                  fallback: 'Email $reportEmail.',
                ),
                child: const Text('Report a problem'),
              ),
            ),
        ],
      ),
    );
  }
}
