import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_providers.dart';
import 'audio_service.dart';
import 'sound_effect.dart';

/// Joue l'ambiance d'un lieu tant que l'ecran est affiche, la coupe quand
/// l'appli passe en arriere-plan et la reprend au retour.
class AmbienceScope extends ConsumerStatefulWidget {
  const AmbienceScope({super.key, required this.ambience, required this.child});

  final Ambience ambience;
  final Widget child;

  @override
  ConsumerState<AmbienceScope> createState() => _AmbienceScopeState();
}

class _AmbienceScopeState extends ConsumerState<AmbienceScope> {
  late final AudioService _audio = ref.read(audioServiceProvider);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _audio.playAmbience(widget.ambience);
    _lifecycle = AppLifecycleListener(
      onHide: () => _audio.stopAmbience(widget.ambience),
      onShow: () => _audio.playAmbience(widget.ambience),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _audio.stopAmbience(widget.ambience);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
