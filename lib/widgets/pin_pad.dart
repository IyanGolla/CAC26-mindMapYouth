import 'package:flutter/material.dart';

import '../app/theme.dart';

const pinLength = 4;

/// Digit pad that needs no keyboard, so it works above the navigator.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onCompleted, this.enabled = true});

  final ValueChanged<String> onCompleted;
  final bool enabled;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';

  void clear() => setState(() => _pin = '');

  void _tap(String d) {
    if (!widget.enabled || _pin.length >= pinLength) return;
    setState(() => _pin += d);
    if (_pin.length == pinLength) widget.onCompleted(_pin);
  }

  void _back() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget key(String label, {VoidCallback? onTap, Widget? child}) => Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            width: 72,
            height: 64,
            child: FilledButton.tonal(
              style: tonalButtonStyle(context),
              onPressed: widget.enabled ? onTap ?? () => _tap(label) : null,
              child: child ?? Text(label, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '${_pin.length} of $pinLength digits entered',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < pinLength; i++)
                Container(
                  margin: const EdgeInsets.all(8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? scheme.primary : null,
                    border: Border.all(color: scheme.outline, width: 2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) key(d)]),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 84),
            key('0'),
            key(
              'Delete',
              onTap: _back,
              child: Semantics(
                label: 'Delete',
                child: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
