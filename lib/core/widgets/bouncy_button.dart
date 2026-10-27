import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Cible tactile d'enfant : au moins [AppSizes.minTouch], s'enfonce a
/// l'appui puis rebondit (courbe "boing"), declenche au relachement.
/// Libelle accessible obligatoire (aucun texte visible requis).
class BouncyButton extends StatefulWidget {
  const BouncyButton({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.size,
    this.enabled = true,
  });

  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget child;
  final Size? size;
  final bool enabled;

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    const minSide = AppSizes.minTouch;
    final child = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: size?.width ?? minSide,
        minHeight: size?.height ?? minSide,
        maxWidth: size?.width ?? double.infinity,
        maxHeight: size?.height ?? double.infinity,
      ),
      child: widget.child,
    );
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: _down ? AppMotion.press : AppMotion.t1,
          curve: _down ? Curves.easeOut : AppMotion.boing,
          child: _Pressed(down: _down, child: child),
        ),
      ),
    );
  }
}

/// Transmet l'etat "enfonce" aux decors (tranche du bouton).
class _Pressed extends InheritedWidget {
  const _Pressed({required this.down, required super.child});
  final bool down;

  @override
  bool updateShouldNotify(_Pressed old) => old.down != down;
}

bool isPressed(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_Pressed>()?.down ?? false;
