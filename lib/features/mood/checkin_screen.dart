import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/state.dart';
import '../../data/app_database.dart';
import '../../domain/risk_signal_detector.dart';
import '../../widgets/support_prompt.dart';
import 'mood_scale.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  int _mood = 3;
  final _emotions = <String>{};
  final _contexts = <String>{};
  double? _sleep;
  int? _energy;
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final db = ref.read(servicesProvider).db;
    final note = _note.text.trim();
    await db.addMoodEntry(MoodEntry(
      createdAt: DateTime.now(),
      mood: _mood,
      energy: _energy,
      sleepHours: _sleep,
      note: note.isEmpty ? null : note,
      emotions: _emotions.toList(),
      contexts: _contexts.toList(),
    ));
    ref.invalidate(moodEntriesProvider);
    final entries = await db.moodEntries();
    if (!mounted) return;

    const detector = RiskSignalDetector();
    final offerSupport = detector.textHasSignal(note) ||
        detector.moodPatternHasSignal(
          [for (final e in entries) (at: e.createdAt, mood: e.mood)],
          now: DateTime.now(),
        );
    if (offerSupport) {
      await showSupportPrompt(context);
      if (mounted) context.pop();
      return;
    }
    final goOn = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Saved'),
        content: const Text('Want to work through a thought?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Not now')),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Yes')),
        ],
      ),
    );
    if (!mounted) return;
    if (goOn == true) {
      context.pushReplacement('/thought');
    } else {
      context.pop();
    }
  }

  Widget _chips(List<String> all, Set<String> picked) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final tag in all)
            FilterChip(
              label: Text(tag),
              selected: picked.contains(tag),
              onSelected: (on) => setState(
                  () => on ? picked.add(tag) : picked.remove(tag)),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Check in')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('How are you feeling right now?', style: t.titleLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in moodLabels.keys)
                Semantics(
                  button: true,
                  selected: _mood == m,
                  label: moodLabels[m],
                  excludeSemantics: true,
                  child: InkResponse(
                    onTap: () => setState(() => _mood = m),
                    radius: 32,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _mood == m ? scheme.primaryContainer : null,
                        border: _mood == m
                            ? Border.all(color: scheme.primary, width: 2)
                            : null,
                      ),
                      child: Icon(moodIcons[m], size: 36),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Center(child: Text(moodLabels[_mood]!, style: t.titleMedium)),
          const SizedBox(height: 20),
          Text('Any of these fit? (optional)', style: t.titleSmall),
          const SizedBox(height: 6),
          _chips(emotionTags, _emotions),
          const SizedBox(height: 16),
          Text('What\'s it about? (optional)', style: t.titleSmall),
          const SizedBox(height: 6),
          _chips(contextTags, _contexts),
          const SizedBox(height: 16),
          Text(
            _sleep == null
                ? 'Sleep last night (optional)'
                : 'Sleep last night: ${_sleep!.toStringAsFixed(1)} hours',
            style: t.titleSmall,
          ),
          Slider(
            value: _sleep ?? 0,
            max: 12,
            divisions: 24,
            label: _sleep?.toStringAsFixed(1),
            semanticFormatterCallback: (v) => '${v.toStringAsFixed(1)} hours',
            onChanged: (v) => setState(() => _sleep = v),
          ),
          Text(
            _energy == null ? 'Energy (optional)' : 'Energy: $_energy of 5',
            style: t.titleSmall,
          ),
          Slider(
            value: (_energy ?? 1).toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _energy?.toString(),
            onChanged: (v) => setState(() => _energy = v.round()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Anything you want to add? (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
