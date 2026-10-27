import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effect.dart';
import '../../core/content/scenes.dart';
import '../../core/entitlements/entitlement_providers.dart';
import '../../core/entitlements/entitlement_service.dart';
import '../../core/entitlements/premium_feature.dart';
import '../../core/parental/parental_gate.dart';
import '../../core/router/routes.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';

/// Espace parents (atteint uniquement apres la porte parentale) :
/// pass, restauration, son, confidentialite. Texte adulte autorise ici.
///
/// L'espace se referme a toute sortie : croix, retour systeme Android,
/// passage en arriere-plan, ou n'importe quelle navigation qui retire
/// l'ecran (BUG-003), et apres [idleTimeout] sans toucher l'ecran
/// (suggestion QA du 27/10). La porte est redemandee a l'entree suivante.
///
/// Sans laissez-passer valide (historique du navigateur, BUG-013), l'ecran
/// n'affiche rien et renvoie a la carte, en plus de la garde du routeur.
class ParentsScreen extends ConsumerStatefulWidget {
  const ParentsScreen({super.key});

  /// Fermeture automatique apres une minute sans toucher l'ecran.
  static const idleTimeout = Duration(seconds: 60);

  @override
  ConsumerState<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends ConsumerState<ParentsScreen> {
  late final ParentalAccess _access = ref.read(parentalAccessProvider);
  late final AppLifecycleListener _lifecycle;
  bool _left = false;
  late final bool _allowed;
  Timer? _idle;

  @override
  void initState() {
    super.initState();
    // Le laissez-passer de la porte ne sert qu'une fois.
    _allowed =
        _access.consumePass(ParentalPurpose.parentsSpace) ||
        _access.parentsSpaceOpen ||
        !_access.gateEnabled;
    _lifecycle = AppLifecycleListener(onHide: _leave);
    if (!_allowed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leave());
      return;
    }
    _access.openParentsSpace();
    _resetIdle();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _lifecycle.dispose();
    _access.closeParentsSpace();
    super.dispose();
  }

  void _resetIdle() {
    _idle?.cancel();
    _idle = Timer(ParentsScreen.idleTimeout, _leave);
  }

  void _leave() {
    _idle?.cancel();
    _access.closeParentsSpace();
    if (_left || !mounted) return;
    _left = true;
    context.go(Routes.map);
  }

  @override
  Widget build(BuildContext context) {
    if (!_allowed) return const ColoredBox(color: AppColors.cream);
    final t = Theme.of(context).textTheme;
    final store = ref.watch(entitlementServiceProvider);
    final active = ref.watch(entitlementsProvider).value ?? const {};
    final muted = ref.watch(mutedProvider);
    final telemetry = ref.watch(telemetryProvider);

    void leave() {
      ref.read(audioServiceProvider).play(SoundEffect.uiBack);
      _leave();
    }

    return PopScope(
      canPop: false,
      // Retour systeme : meme sortie que la croix.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leave();
      },
      // Tout toucher, glisser, defilement ou survol relance le minuteur.
      // Phase 3 : ne jamais fermer l'espace pendant une feuille d'achat
      // native (voir README).
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetIdle(),
        onPointerMove: (_) => _resetIdle(),
        onPointerSignal: (_) => _resetIdle(),
        // Ordinateur : le survol de la souris compte aussi (un parent qui
        // lit sans cliquer n'est pas renvoye a la carte).
        onPointerHover: (_) => _resetIdle(),
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const Key('parents-close'),
                      tooltip: 'Retour a la carte',
                      icon: const Icon(Icons.close_rounded, size: 36),
                      onPressed: leave,
                    ),
                    const SizedBox(width: 8),
                    Text('ESPACE PARENTS', style: t.headlineMedium),
                  ],
                ),
                const SizedBox(height: 16),
                // Bandeau : la bande des monstres (illustration du site).
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.m),
                    child: Image.asset(
                      Scenes.parents,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -.2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Pass Monstres', style: t.titleLarge),
                Text(
                  store.isStoreAvailable
                      ? 'Achat via la boutique.'
                      : 'Boutique non branchee (phase 3, RevenueCat). '
                            'Implementation factice : rien n\'est facture.',
                  style: t.bodyLarge,
                ),
                const SizedBox(height: 8),
                for (final f in PremiumFeature.values)
                  ListTile(
                    leading: Icon(
                      active.contains(f)
                          ? Icons.lock_open_rounded
                          : Icons.lock_rounded,
                      color: AppColors.plum2,
                    ),
                    title: Text(f.parentLabel, style: t.bodyLarge),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      key: const Key('fake-purchase'),
                      style: AppTheme.parentButton,
                      onPressed: () async {
                        final outcome = await ref
                            .read(entitlementsProvider.notifier)
                            .purchasePass();
                        if (context.mounted &&
                            outcome == PurchaseOutcome.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Simulation : pass active.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Simuler l\'achat du pass'),
                    ),
                    FilledButton(
                      style: AppTheme.parentButton,
                      onPressed: () =>
                          ref.read(entitlementsProvider.notifier).restore(),
                      child: const Text('Restaurer les achats'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(entitlementsProvider.notifier).resetFake(),
                      child: const Text('Reverrouiller (developpement)'),
                    ),
                  ],
                ),
                const Divider(height: 40),
                SwitchListTile(
                  title: Text('Son', style: t.bodyLarge),
                  value: !muted,
                  onChanged: (_) => ref.read(mutedProvider.notifier).toggle(),
                ),
                const Divider(height: 40),
                Text('Confidentialite', style: t.titleLarge),
                Text(
                  'Aucune publicite, aucun SDK d\'analytics ou de suivi, aucun '
                  'compte enfant. Mesures d\'usage : '
                  '${telemetry.enabled ? 'activees' : 'desactivees'} '
                  '(implementation vide, rien n\'est envoye). Chaque lien externe '
                  'redemande la porte parentale, et cet espace se referme des '
                  'que vous le quittez.',
                  style: t.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
