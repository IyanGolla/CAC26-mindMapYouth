import 'dart:math';

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Leafy sprigs growing in from the screen corners, drawn behind [child].
class LeafCorners extends StatelessWidget {
  const LeafCorners({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
  });

  final Widget child;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LeafCornerPainter(
        top: top,
        bottom: bottom,
        topInset: MediaQuery.paddingOf(context).top,
        faded: Theme.of(context).brightness == Brightness.dark,
      ),
      child: child,
    );
  }
}

void _sprig(Canvas canvas, Offset root, double angle, double length,
    {double opacity = 1}) {
  canvas.save();
  canvas.translate(root.dx, root.dy);
  canvas.rotate(angle);
  final stem = Paint()
    ..color = leafGreenDark.withValues(alpha: opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset.zero, Offset(length, 0), stem);
  const pairs = 5;
  for (var i = 0; i < pairs; i++) {
    final t = (i + 1) / (pairs + 0.6);
    final size = length * 0.26 * (1 - t * 0.45);
    for (final side in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(length * t, 0);
      canvas.rotate(side * 0.85);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(size * 0.5, -size * 0.38, size, 0)
        ..quadraticBezierTo(size * 0.5, size * 0.38, 0, 0);
      canvas.drawPath(
        leaf,
        Paint()
          ..color = (i.isEven ? leafGreen : leafGreenDark)
              .withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }
  // Tip leaf.
  final tip = length * 0.2;
  canvas.drawPath(
    Path()
      ..moveTo(length, 0)
      ..quadraticBezierTo(length + tip * 0.5, -tip * 0.4, length + tip, 0)
      ..quadraticBezierTo(length + tip * 0.5, tip * 0.4, length, 0),
    Paint()..color = leafGreen.withValues(alpha: opacity),
  );
  canvas.restore();
}

class _LeafCornerPainter extends CustomPainter {
  const _LeafCornerPainter({
    required this.top,
    required this.bottom,
    required this.topInset,
    required this.faded,
  });

  final bool top;
  final bool bottom;
  final double topInset;
  final bool faded;

  @override
  void paint(Canvas canvas, Size size) {
    final o = faded ? 0.55 : 0.9;
    void corner(Offset at, double base) {
      _sprig(canvas, at, base - 0.42, 62, opacity: o);
      _sprig(canvas, at, base, 78, opacity: o);
      _sprig(canvas, at, base + 0.42, 58, opacity: o);
    }

    if (top) {
      corner(Offset(-6, topInset - 4), pi / 4);
      corner(Offset(size.width + 6, topInset - 4), pi * 3 / 4);
    }
    if (bottom) {
      corner(Offset(-6, size.height + 6), -pi / 4);
      corner(Offset(size.width + 6, size.height + 6), -pi * 3 / 4);
    }
  }

  @override
  bool shouldRepaint(_LeafCornerPainter old) =>
      old.top != top ||
      old.bottom != bottom ||
      old.topInset != topInset ||
      old.faded != faded;
}

/// Decorative brain with a lightbulb and gears, for the welcome screen.
class BrainIllustration extends StatelessWidget {
  const BrainIllustration({super.key, this.height = 230});
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: AspectRatio(
          aspectRatio: 300 / 230,
          child: CustomPaint(painter: _BrainPainter()),
        ),
      ),
    );
  }
}

class _BrainPainter extends CustomPainter {
  static const _pink = Color(0xFFF6B0A8);
  static const _pinkLine = Color(0xFFD9695F);
  static const _grey = Color(0xFF55504B);
  static const _yellow = Color(0xFFF7CE3E);

  void _gear(Canvas canvas, Offset c, double r, double turn) {
    const teeth = 8;
    final path = Path();
    for (var i = 0; i < teeth * 2; i++) {
      final a = turn + i * pi / teeth;
      final rr = i.isEven ? r : r * 0.74;
      for (final da in const [-0.11, 0.11]) {
        final p = c + Offset(cos(a + da), sin(a + da)) * rr;
        if (i == 0 && da < 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
    }
    path
      ..close()
      ..addOval(Rect.fromCircle(center: c, radius: r * 0.34))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = _grey);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 300, size.height / 230);

    final wire = Paint()
      ..color = _grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Wires from the bulb and gears down to the brain.
    canvas.drawPath(
      Path()
        ..moveTo(52, 78)
        ..lineTo(52, 128)
        ..lineTo(84, 128),
      wire,
    );
    canvas.drawPath(
      Path()
        ..moveTo(212, 62)
        ..lineTo(180, 62)
        ..lineTo(180, 92),
      wire,
    );

    // Lightbulb.
    canvas.drawCircle(const Offset(52, 36), 27,
        Paint()..color = _yellow.withValues(alpha: 0.3));
    canvas.drawCircle(const Offset(52, 36), 21, Paint()..color = _yellow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(43, 54, 18, 8), const Radius.circular(2)),
      Paint()..color = _yellow,
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(44, 63.0 + i * 5, 16, 3.4),
            const Radius.circular(1.7)),
        Paint()..color = const Color(0xFFB9B2AA),
      );
    }

    // Gears.
    _gear(canvas, const Offset(238, 50), 22, 0.2);
    _gear(canvas, const Offset(206, 28), 13, 0.5);

    // Leaves peeking out below the brain.
    _sprig(canvas, const Offset(120, 192), pi * 0.72, 44);
    _sprig(canvas, const Offset(190, 190), pi * 0.22, 46);
    _sprig(canvas, const Offset(206, 176), -0.1, 34);

    // Brain: overlapping lobes, outlined together.
    const lobes = <(double, double, double)>[
      (112, 118, 30), (138, 100, 30), (172, 98, 32), (204, 112, 28),
      (220, 138, 26), (202, 164, 26), (168, 172, 28), (132, 168, 28),
      (104, 146, 26), (160, 136, 44),
    ];
    final brain = Path();
    for (final (x, y, r) in lobes) {
      brain.addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
    }
    final outline = Paint()
      ..color = _pinkLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(brain, outline);
    canvas.drawPath(brain, Paint()..color = _pink);

    // Folds.
    final fold = Paint()
      ..color = _pinkLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(160, 74)
        ..cubicTo(148, 100, 172, 120, 158, 146)
        ..cubicTo(150, 162, 164, 180, 160, 196),
      fold,
    );
    for (final (x, y, w, flip) in const <(double, double, double, double)>[
      (100, 128, 34, 1), (118, 152, 30, -1), (124, 104, 28, -1),
      (190, 112, 32, 1), (196, 146, 34, -1), (182, 172, 26, 1),
      (132, 176, 24, 1), (214, 128, 20, 1),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..cubicTo(x + w * 0.3, y - 12 * flip, x + w * 0.6, y + 12 * flip,
              x + w, y - 2 * flip),
        fold,
      );
    }

    // Confetti.
    const dots = <(double, double, Color)>[
      (78, 100, Color(0xFF3C8DAD)), (92, 176, Color(0xFFE2574C)),
      (240, 100, Color(0xFF3C8DAD)), (248, 168, Color(0xFFE2574C)),
      (230, 196, leafGreenDark), (74, 150, leafGreenDark),
      (150, 62, Color(0xFFE2574C)), (258, 132, _yellow),
      (104, 204, Color(0xFF3C8DAD)), (66, 196, _yellow),
    ];
    for (final (x, y, c) in dots) {
      canvas.drawCircle(Offset(x, y), 2.4, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_BrainPainter old) => false;
}
