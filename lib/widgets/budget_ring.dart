import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'animated_money.dart';

/// Colour that reflects how healthy today's budget is.
Color budgetColor(double fraction, double amountLeft) {
  if (amountLeft < 0) return AppColors.danger;
  if (fraction > .4) return AppColors.secondary;
  if (fraction > .15) return AppColors.warning;
  return AppColors.danger;
}

/// The hero of the app: a glowing ring that drains as you spend.
class BudgetRing extends StatelessWidget {
  const BudgetRing({
    super.key,
    required this.fraction,
    required this.amountLeft,
    this.size = 220,
  });

  final double fraction;
  final double amountLeft;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = budgetColor(fraction, amountLeft);
    final over = amountLeft < 0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (_, f, __) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size.square(size), painter: _RingPainter(f, color)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  over ? 'Over today by' : 'Left today',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                AnimatedMoney(
                  amountLeft.abs(),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: over ? AppColors.danger : AppColors.text,
                    letterSpacing: -.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withOpacity(.06),
    );

    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    // glow
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke + 6
        ..color = color.withOpacity(.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}
