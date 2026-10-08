import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../core/launch.dart';
import '../../widgets/decor.dart';
import '../../widgets/pin_pad.dart';

/// Shown above the whole app while locked.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pad = GlobalKey<PinPadState>();
  bool _checking = false;
  bool _wrong = false;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _submit(String pin) async {
    setState(() => _checking = true);
    final ok = await ref.read(lockProvider.notifier).unlock(pin);
    if (!mounted) return;
    _pad.currentState?.clear();
    setState(() {
      _checking = false;
      _wrong = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final until = ref.watch(lockProvider).lockedUntil;
    final waiting = until != null && DateTime.now().isBefore(until);
    if (waiting) {
      // Rebuild once the wait is over.
      _tick ??= Timer(until.difference(DateTime.now()), () {
        _tick = null;
        if (mounted) setState(() {});
      });
    }
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: LeafCorners(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Enter PIN',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 24,
                  child: Text(
                    waiting
                        ? 'Too many tries. Wait 30 seconds.'
                        : _wrong
                        ? 'That PIN didn\'t match.'
                        : '',
                  ),
                ),
                const SizedBox(height: 8),
                PinPad(
                  key: _pad,
                  enabled: !_checking && !waiting,
                  onCompleted: _submit,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => open(
                    context,
                    telUri('988'),
                    fallback: 'Dial 988 on any phone.',
                  ),
                  child: const Text('Need help now? Call 988'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
