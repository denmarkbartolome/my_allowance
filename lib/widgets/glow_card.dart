import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A rounded surface with an optional coloured glow.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.glowColor,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.radius = 28,
  });

  final Widget child;
  final Color? glowColor;
  final EdgeInsets padding;
  final Gradient? gradient;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (glowColor ?? Colors.white).withOpacity(glowColor == null ? .06 : .22),
        ),
        boxShadow: glowColor == null ? null : AppTheme.glow(glowColor!, opacity: .22),
      ),
      child: child,
    );
  }
}
