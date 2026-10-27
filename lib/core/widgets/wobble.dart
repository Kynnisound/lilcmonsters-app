import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Oscillation de +-4 degres en 300 ms (element verrouille, essai rate).
/// Declencher en changeant [trigger].
class Wobble extends StatefulWidget {
  const Wobble({super.key, required this.trigger, required this.child});

  /// Chaque changement de valeur declenche une oscillation.
  final int trigger;
  final Widget child;

  @override
  State<Wobble> createState() => _WobbleState();
}

class _WobbleState extends State<Wobble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.wobble,
  );

  @override
  void didUpdateWidget(Wobble old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Transform.rotate(
      angle:
          sin(_c.value * pi * 3) *
          (1 - _c.value) *
          AppMotion.wobbleAngleDeg *
          pi /
          180,
      child: child,
    ),
    child: widget.child,
  );
}
