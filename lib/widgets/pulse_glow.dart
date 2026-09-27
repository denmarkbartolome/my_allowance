import 'package:flutter/material.dart';

/// Wraps a child in a glow that gently breathes.
class PulseGlow extends StatefulWidget {
  const PulseGlow({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = 20,
  });

  final Widget child;
  final Color color;
  final double borderRadius;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(.22 + .25 * t),
                blurRadius: 18 + 18 * t,
                spreadRadius: 1 + 3 * t,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
