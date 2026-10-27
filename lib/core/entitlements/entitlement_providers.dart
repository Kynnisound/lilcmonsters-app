import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config_providers.dart';
import 'entitlement_service.dart';
import 'premium_feature.dart';

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  final config = ref.watch(appConfigProvider);
  return FakeEntitlementService(premiumUnlocked: config.premiumUnlocked);
});

class EntitlementsNotifier extends AsyncNotifier<Set<PremiumFeature>> {
  EntitlementService get _service => ref.read(entitlementServiceProvider);

  @override
  Future<Set<PremiumFeature>> build() =>
      ref.watch(entitlementServiceProvider).activeEntitlements();

  Future<PurchaseOutcome> purchasePass() async {
    final outcome = await _service.purchasePass();
    state = AsyncData(await _service.activeEntitlements());
    return outcome;
  }

  Future<PurchaseOutcome> restore() async {
    final outcome = await _service.restorePurchases();
    state = AsyncData(await _service.activeEntitlements());
    return outcome;
  }

  /// Developpement uniquement (implementation factice).
  Future<void> resetFake() async {
    final s = _service;
    if (s is FakeEntitlementService) {
      s.reset();
      state = AsyncData(await s.activeEntitlements());
    }
  }
}

final entitlementsProvider =
    AsyncNotifierProvider<EntitlementsNotifier, Set<PremiumFeature>>(
      EntitlementsNotifier.new,
    );

/// Acces a un contenu payant. Faux tant que les droits se chargent.
final hasAccessProvider = Provider.family<bool, PremiumFeature>((ref, feature) {
  return ref.watch(entitlementsProvider).value?.contains(feature) ?? false;
});
