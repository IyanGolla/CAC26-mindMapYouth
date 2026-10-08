import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/state.dart';
import '../../widgets/pin_pad.dart';

class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  final _pad = GlobalKey<PinPadState>();
  String? _first;
  bool _mismatch = false;
  bool _saving = false;

  Future<void> _entered(String pin) async {
    if (_first == null) {
      _pad.currentState?.clear();
      setState(() {
        _first = pin;
        _mismatch = false;
      });
      return;
    }
    if (pin != _first) {
      _pad.currentState?.clear();
      setState(() {
        _first = null;
        _mismatch = true;
      });
      return;
    }
    setState(() => _saving = true);
    await ref.read(lockProvider.notifier).setPin(pin);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('PIN set.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set a PIN')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                _first == null ? 'Choose a 4-digit PIN' : 'Enter it again',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 24,
                child: Text(_mismatch ? 'Those didn\'t match. Start again.' : ''),
              ),
              const SizedBox(height: 8),
              PinPad(key: _pad, enabled: !_saving, onCompleted: _entered),
            ],
          ),
        ),
      ),
    );
  }
}
