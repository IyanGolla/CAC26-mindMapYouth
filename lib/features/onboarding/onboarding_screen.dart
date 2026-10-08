import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/state.dart';
import '../../data/resource_repository.dart';
import '../../widgets/decor.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String? _county;

  Future<void> _finish({required bool setPin}) async {
    final settings = ref.read(settingsProvider.notifier);
    await settings.setCounty(_county);
    await settings.setOnboarded();
    if (!mounted) return;
    context.go('/');
    if (setPin) context.push('/pin');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pages = [
      _Page(
        illustration: true,
        title: 'Take care of your mind.',
        body: const [
          'No account. No tracking.',
          'Your entries never leave this phone.',
          'Hide the app any time with Exit.',
          'Erase everything any time.',
        ],
        primary: Center(
          child: FilledButton.icon(
            onPressed: () => setState(() => _step = 1),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Start now'),
          ),
        ),
      ),
      _Page(
        icon: Icons.place_outlined,
        title: 'Where should we look for help?',
        body: const [
          'Pick a county to see what\'s close. This stays on your phone. You can skip it.',
        ],
        extra: DropdownButtonFormField<String?>(
          initialValue: _county,
          decoration: const InputDecoration(labelText: 'County (optional)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Skip for now')),
            for (final c in counties.keys)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() => _county = v),
        ),
        primary: FilledButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Continue'),
        ),
      ),
      _Page(
        icon: Icons.lock_outline,
        title: 'Want a PIN?',
        body: const [
          'A 4-digit PIN locks the app whenever you leave it.',
          'There\'s no way to recover a forgotten PIN, because nobody else has your data.',
        ],
        primary: FilledButton(
          onPressed: () => _finish(setPin: true),
          child: const Text('Set a PIN'),
        ),
        secondary: TextButton(
          onPressed: () => _finish(setPin: false),
          child: const Text('Not now'),
        ),
      ),
    ];

    return Scaffold(
      body: LeafCorners(
        child: SafeArea(
          child: Padding(
            // Leaves room for the Exit button.
            padding: const EdgeInsets.fromLTRB(28, 64, 28, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  label: 'MindMap Youth, step ${_step + 1} of ${pages.length}',
                  child: const SizedBox(height: 4),
                ),
                Expanded(child: pages[_step]),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    'Not a medical service and not for emergencies. In danger? Call 911 or 988.',
                    style: t.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    this.icon,
    this.illustration = false,
    required this.title,
    required this.body,
    required this.primary,
    this.extra,
    this.secondary,
  });

  final IconData? icon;
  final bool illustration;
  final String title;
  final List<String> body;
  final Widget primary;
  final Widget? extra;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (illustration)
                  const Center(child: BrainIllustration())
                else ...[
                  const SizedBox(height: 32),
                  Icon(
                    icon,
                    size: 44,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
                SizedBox(height: illustration ? 28 : 16),
                Text(
                  title,
                  style: t.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                for (final line in body)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(line, textAlign: TextAlign.center),
                  ),
                if (extra != null) ...[const SizedBox(height: 16), extra!],
              ],
            ),
          ),
        ),
        primary,
        ?secondary,
        const SizedBox(height: 12),
      ],
    );
  }
}
