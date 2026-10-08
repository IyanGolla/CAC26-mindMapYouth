import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/state.dart';
import '../../data/app_database.dart';
import '../../domain/risk_signal_detector.dart';
import '../../widgets/support_prompt.dart';
import 'mood_scale.dart';

class ThoughtRecordScreen extends ConsumerStatefulWidget {
  const ThoughtRecordScreen({super.key});

  @override
  ConsumerState<ThoughtRecordScreen> createState() => _ThoughtRecordScreenState();
}

class _ThoughtRecordScreenState extends ConsumerState<ThoughtRecordScreen> {
  static const _steps = 6;
  int _step = 0;
  bool _saving = false;

  final _situation = TextEditingController();
  final _thought = TextEditingController();
  final _feeling = TextEditingController();
  final _for = TextEditingController();
  final _against = TextEditingController();
  final _balanced = TextEditingController();
  double? _before;
  double? _after;
  String? _trap;

  @override
  void dispose() {
    for (final c in [_situation, _thought, _feeling, _for, _against, _balanced]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    setState(() => _saving = true);
    final record = ThoughtRecord(
      createdAt: DateTime.now(),
      situation: _text(_situation),
      automaticThought: _text(_thought),
      feeling: _text(_feeling),
      intensityBefore: _before?.round(),
      trap: _trap,
      evidenceFor: _text(_for),
      evidenceAgainst: _text(_against),
      balancedThought: _text(_balanced),
      intensityAfter: _after?.round(),
    );
    await ref.read(servicesProvider).db.addThoughtRecord(record);
    ref.invalidate(thoughtRecordsProvider);
    if (!mounted) return;
    const detector = RiskSignalDetector();
    final offerSupport = [
      record.situation,
      record.automaticThought,
      record.feeling,
      record.evidenceFor,
      record.evidenceAgainst,
      record.balancedThought,
    ].any(detector.textHasSignal);
    if (offerSupport) await showSupportPrompt(context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved. That took effort.')));
    context.pop();
  }

  Widget _field(TextEditingController c, String label, {String? hint}) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: c,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            alignLabelWithHint: true,
          ),
        ),
      );

  Widget _intensity(double? value, ValueChanged<double> onChanged) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value == null
              ? 'How strong is it? (0 to 100)'
              : 'How strong is it? ${value.round()} out of 100'),
          Slider(
            value: value ?? 50,
            max: 100,
            divisions: 20,
            label: '${(value ?? 50).round()}',
            onChanged: onChanged,
          ),
        ],
      );

  (String, String, Widget) _content() => switch (_step) {
        0 => (
            'What happened?',
            'Just the facts, like a camera would see it.',
            _field(_situation, 'The situation'),
          ),
        1 => (
            'What went through your mind?',
            'The first thought that showed up, even if it sounds harsh.',
            _field(_thought, 'The thought'),
          ),
        2 => (
            'What did you feel?',
            'Name the feeling, then rate it.',
            Column(children: [
              _field(_feeling, 'The feeling', hint: 'anxious, embarrassed, angry...'),
              const SizedBox(height: 16),
              _intensity(_before, (v) => setState(() => _before = v)),
            ]),
          ),
        3 => (
            'Does a thinking trap fit?',
            'Everyone\'s brain does these. Noticing one isn\'t a flaw.',
            Column(
              children: [
                for (final trap in thinkingTraps)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        selected: _trap == trap.name,
                        title: Text(trap.name),
                        subtitle: Text(trap.example),
                        trailing: _trap == trap.name
                            ? const Icon(Icons.check_circle)
                            : const Icon(Icons.circle_outlined),
                        onTap: () => setState(() =>
                            _trap = _trap == trap.name ? null : trap.name),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        4 => (
            'Look at the evidence',
            'Like you would for a friend.',
            Column(children: [
              _field(_for, 'What supports the thought?'),
              _field(_against, 'What doesn\'t fit with it?'),
            ]),
          ),
        _ => (
            'A more balanced thought',
            'Not fake-positive. Just fairer.',
            Column(children: [
              _field(_balanced, 'A fairer way to see it'),
              const SizedBox(height: 16),
              _intensity(_after, (v) => setState(() => _after = v)),
            ]),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (title, hint, body) = _content();
    final last = _step == _steps - 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Thought record')),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / _steps,
            semanticsLabel: 'Step ${_step + 1} of $_steps',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                Text('Step ${_step + 1} of $_steps', style: t.bodySmall),
                const SizedBox(height: 4),
                Text(title, style: t.titleLarge),
                const SizedBox(height: 4),
                Text(hint),
                body,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                if (!last)
                  TextButton(
                    onPressed: () => setState(() => _step++),
                    child: const Text('Skip'),
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : last
                          ? _save
                          : () => setState(() => _step++),
                  child: Text(last ? 'Save' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
