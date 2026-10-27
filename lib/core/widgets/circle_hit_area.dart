import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Limite les touchers a un cercle centre de diametre [ratio] x le plus
/// petit cote. Le dessin de l'enfant n'est pas rogne.
class CircleHitArea extends SingleChildRenderObjectWidget {
  const CircleHitArea({super.key, required this.ratio, super.child});

  final double ratio;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCircleHitArea(ratio);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) => (renderObject as _RenderCircleHitArea).ratio = ratio;
}

class _RenderCircleHitArea extends RenderProxyBox {
  _RenderCircleHitArea(this.ratio);
  double ratio;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final r = size.shortestSide * ratio / 2;
    if ((position - size.center(Offset.zero)).distance > r) return false;
    return super.hitTest(result, position: position);
  }
}
