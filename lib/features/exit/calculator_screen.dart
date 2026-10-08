import 'package:flutter/material.dart';

/// Neutral screen shown after Quick Exit: a plain working calculator.
/// Press and hold the display area above the keys to go back to the app.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.onReturn});

  final VoidCallback onReturn;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  double? _stored;
  String? _op;
  bool _fresh = true;

  void _digit(String d) => setState(() {
    if (_fresh) {
      _display = d == '.' ? '0.' : d;
      _fresh = false;
    } else if (d == '.' && _display.contains('.')) {
      return;
    } else if (_display.length < 12) {
      _display = _display == '0' && d != '.' ? d : _display + d;
    }
  });

  double _apply(double a, double b, String op) => switch (op) {
    '+' => a + b,
    '−' => a - b,
    '×' => a * b,
    _ => b == 0 ? double.nan : a / b,
  };

  String _format(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    var s = v.toStringAsFixed(8);
    s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return s.length > 12 ? v.toStringAsPrecision(8) : s;
  }

  void _operator(String op) => setState(() {
    final current = double.tryParse(_display) ?? 0;
    if (_stored != null && _op != null && !_fresh) {
      _stored = _apply(_stored!, current, _op!);
      _display = _format(_stored!);
    } else {
      _stored = current;
    }
    _op = op;
    _fresh = true;
  });

  void _equals() => setState(() {
    if (_stored == null || _op == null) return;
    final result = _apply(_stored!, double.tryParse(_display) ?? 0, _op!);
    _display = _format(result);
    _stored = null;
    _op = null;
    _fresh = true;
  });

  void _clear() => setState(() {
    _display = '0';
    _stored = null;
    _op = null;
    _fresh = true;
  });

  @override
  Widget build(BuildContext context) {
    // Plain greys on purpose: the disguise should not share the app's look.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF121212) : const Color(0xFFF4F4F4);
    final ink = dark ? Colors.white : const Color(0xFF1C1C1C);
    final digitStyle = FilledButton.styleFrom(
      backgroundColor: dark ? const Color(0xFF2E2E2E) : const Color(0xFFDFDFDF),
      foregroundColor: ink,
    );
    final operatorStyle = FilledButton.styleFrom(
      backgroundColor: dark ? const Color(0xFFBDBDBD) : const Color(0xFF3A3A3A),
      foregroundColor: dark ? const Color(0xFF1C1C1C) : Colors.white,
    );
    Widget key(String label, VoidCallback onTap, {bool accent = false}) =>
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
              height: 68,
              child: accent
                  ? FilledButton(
                      style: operatorStyle,
                      onPressed: onTap,
                      child: Text(label, style: const TextStyle(fontSize: 26)),
                    )
                  : FilledButton(
                      style: digitStyle,
                      onPressed: onTap,
                      child: Text(label, style: const TextStyle(fontSize: 24)),
                    ),
            ),
          ),
        );
    Widget d(String x) => key(x, () => _digit(x));
    Widget o(String x) => key(x, () => _operator(x), accent: true);

    return Material(
      color: background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: widget.onReturn,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 24,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        maxLines: 1,
                        style: TextStyle(fontSize: 56, color: ink),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  key('C', _clear),
                  const Spacer(),
                  const Spacer(),
                  o('÷'),
                ],
              ),
              Row(children: [d('7'), d('8'), d('9'), o('×')]),
              Row(children: [d('4'), d('5'), d('6'), o('−')]),
              Row(children: [d('1'), d('2'), d('3'), o('+')]),
              Row(
                children: [
                  Expanded(flex: 2, child: Row(children: [d('0')])),
                  d('.'),
                  key('=', _equals, accent: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
