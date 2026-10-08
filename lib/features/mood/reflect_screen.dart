import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/state.dart';
import '../../app/theme.dart';
import '../../data/app_database.dart';
import 'mood_scale.dart';

class ReflectScreen extends ConsumerWidget {
  const ReflectScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Delete this entry?'),
          content: const Text('This can\'t be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Keep')),
            FilledButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final moods = ref.watch(moodEntriesProvider).value ?? const <MoodEntry>[];
    final thoughts =
        ref.watch(thoughtRecordsProvider).value ?? const <ThoughtRecord>[];
    final db = ref.read(servicesProvider).db;

    final items = <(DateTime, Widget)>[
      for (final e in moods)
        (
          e.createdAt,
          Card(
            child: ListTile(
              leading: Icon(moodIcons[e.mood], size: 32),
              title: Text(moodLabels[e.mood]!),
              subtitle: Text([
                formatWhen(e.createdAt),
                if (e.emotions.isNotEmpty || e.contexts.isNotEmpty)
                  [...e.emotions, ...e.contexts].join(', '),
                if (e.note != null) e.note!,
              ].join('\n')),
              isThreeLine: e.note != null,
              trailing: IconButton(
                tooltip: 'Delete entry',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await _confirmDelete(context)) {
                    await db.deleteMoodEntry(e.id!);
                    ref.invalidate(moodEntriesProvider);
                  }
                },
              ),
            ),
          ),
        ),
      for (final r in thoughts)
        (
          r.createdAt,
          Card(
            child: ListTile(
              leading: const Icon(Icons.psychology_alt_outlined, size: 32),
              title: Text(r.balancedThought ?? r.automaticThought ?? 'Thought record'),
              subtitle: Text([
                formatWhen(r.createdAt),
                if (r.trap != null) r.trap!,
                if (r.intensityBefore != null && r.intensityAfter != null)
                  'Feeling: ${r.intensityBefore} → ${r.intensityAfter}',
              ].join('\n')),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Delete entry',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await _confirmDelete(context)) {
                    await db.deleteThoughtRecord(r.id!);
                    ref.invalidate(thoughtRecordsProvider);
                  }
                },
              ),
            ),
          ),
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 96),
            child: Text('Reflect', style: t.headlineMedium),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.mood),
                  label: const Text('Check in'),
                  onPressed: () => context.push('/checkin'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  style: tonalButtonStyle(context),
                  icon: const Icon(Icons.psychology_alt_outlined),
                  label: const Text('Thought'),
                  onPressed: () => context.push('/thought'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Your entries', style: t.titleMedium),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Nothing here yet. Entries you save show up here, and only here.',
              ),
            ),
          for (final (_, card) in items) ...[card, const SizedBox(height: 10)],
        ],
      ),
    );
  }
}
