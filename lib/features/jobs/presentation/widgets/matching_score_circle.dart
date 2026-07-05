import 'dart:math' as math;
import 'package:flutter/material.dart';

class MatchingScoreCircle extends StatelessWidget {
  const MatchingScoreCircle({super.key, required this.score, this.size = 46});
  final double score; // 0-100
  final double size;

  Color get _color {
    if (score < 40) return const Color(0xFFE63946);
    if (score < 75) return const Color(0xFFFF7A00);
    return const Color(0xFF22A45D);
  }

  @override
  Widget build(BuildContext context) {
    final pct = score.clamp(0, 100).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(pct, _color),
        child: Center(
          child: Text('${pct.round()}%',
              style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.bold,
                  color: _color)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.pct, this.color);
  final double pct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.10;
    final radius = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final bg = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bg);
    final sweep = 2 * math.pi * (pct / 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.pct != pct || old.color != color;
}
