import 'package:flutter/material.dart';

import '../content/monsters.dart';
import '../l10n/strings.dart';
import '../theme/app_tokens.dart';

/// Placeholder clair pour un module en preparation : un monstre, un
/// sablier anime, et une note discrete pour les adultes.
class ComingSoonCard extends StatefulWidget {
  const ComingSoonCard({
    super.key,
    required this.monster,
    required this.parentNote,
  });

  final Monster monster;
  final String parentNote;

  @override
  State<ComingSoonCard> createState() => _ComingSoonCardState();
}

class _ComingSoonCardState extends State<ComingSoonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${S.comingSoon}. ${widget.parentNote}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paper.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(AppRadii.l),
          border: Border.all(color: widget.monster.color, width: 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -6 * AppMotion.io.transform(_c.value)),
                child: child,
              ),
              child: Image.asset(widget.monster.asset, height: 96),
            ),
            const SizedBox(width: 12),
            RotationTransition(
              turns: CurvedAnimation(parent: _c, curve: AppMotion.io),
              child: Icon(
                Icons.hourglass_bottom_rounded,
                size: 48,
                color: widget.monster.color,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.parentNote,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.inkSoft, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
