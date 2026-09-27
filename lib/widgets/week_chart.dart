import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../providers/budget_controller.dart';

/// Animated Mon-Sun bar chart with a dashed daily-budget line.
class WeekChart extends StatelessWidget {
  const WeekChart({super.key, required this.days, required this.dailyBudget});

  final List<DaySpend> days;
  final double dailyBudget;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _labelH = 28.0;

  @override
  Widget build(BuildContext context) {
    var maxV = dailyBudget;
    for (final d in days) {
      if (d.spent > maxV) maxV = d.spent;
    }
    if (maxV <= 0) maxV = 1;
    maxV *= 1.15;

    return SizedBox(
      height: 180,
      child: LayoutBuilder(
        builder: (context, cons) {
          final chartH = cons.maxHeight - _labelH;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (dailyBudget > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _labelH + chartH * dailyBudget / maxV,
                  child: CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _DashPainter(),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: _Bar(
                        day: days[i],
                        label: _labels[i],
                        index: i,
                        height: days[i].spent <= 0 ? 4 : chartH * days[i].spent / maxV,
                        overBudget: dailyBudget > 0 && days[i].spent > dailyBudget,
                        labelHeight: _labelH,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.label,
    required this.index,
    required this.height,
    required this.overBudget,
    required this.labelHeight,
  });

  final DaySpend day;
  final String label;
  final int index;
  final double height;
  final bool overBudget;
  final double labelHeight;

  @override
  Widget build(BuildContext context) {
    final empty = day.spent <= 0;
    final color = empty
        ? Colors.white.withOpacity(day.isFuture ? .04 : .09)
        : overBudget
            ? AppColors.danger
            : AppColors.secondary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: height),
          duration: Duration(milliseconds: 650 + index * 90),
          curve: Curves.easeOutCubic,
          builder: (_, h, __) => Container(
            width: 26,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: empty
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, color.withOpacity(.5)],
                    ),
              color: empty ? color : null,
              boxShadow: day.isToday && !empty
                  ? AppTheme.glow(color, opacity: .55, blur: 18, spread: 0)
                  : null,
            ),
          ),
        ),
        SizedBox(
          height: labelHeight,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w500,
                color: day.isToday ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.warning.withOpacity(.7)
      ..strokeWidth = 1.2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), p);
      x += 10;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
