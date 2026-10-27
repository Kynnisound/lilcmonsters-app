import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
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
class ParentsScreen extends ConsumerWidget {
  const ParentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final store = ref.watch(entitlementServiceProvider);
    final active = ref.watch(entitlementsProvider).value ?? const {};
    final muted = ref.watch(mutedProvider);
    final telemetry = ref.watch(telemetryProvider);

    void leave() {
      ref.read(parentalSessionProvider.notifier).revoke();
      context.go(Routes.map);
    }

    return Scaffold(
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
                    if (context.mounted && outcome == PurchaseOutcome.success) {
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
              '(implementation vide, rien n\'est envoye). Les liens externes '
              'et les achats passent toujours par cette porte parentale.',
              style: t.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
