import 'package:flutter/material.dart';
import '../core/format.dart';

/// Counts up to [value] whenever it changes.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(
    this.value, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(money(v), style: style),
    );
  }
}
