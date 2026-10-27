import 'premium_feature.dart';

/// Resultat d'un achat ou d'une restauration.
enum PurchaseOutcome { success, cancelled, unavailable, error }

/// Frontiere avec le futur SDK d'achats (RevenueCat, phase 3).
/// Aucun ecran ne doit appeler un SDK d'achat directement.
abstract interface class EntitlementService {
  /// Droits actifs pour l'appareil ou le compte courant.
  Future<Set<PremiumFeature>> activeEntitlements();

  /// Achat du pass (un seul produit envisage : "Pass Monstres").
  Future<PurchaseOutcome> purchasePass();

  Future<PurchaseOutcome> restorePurchases();

  /// Vrai quand une vraie boutique est branchee.
  bool get isStoreAvailable;
}

/// Implementation factice, sans aucun SDK : tout le contenu payant est
/// verrouille ou deverrouille selon un drapeau (PREMIUM_UNLOCKED).
/// `purchasePass` simule un achat reussi pour tester les parcours.
class FakeEntitlementService implements EntitlementService {
  FakeEntitlementService({required bool premiumUnlocked})
    : _active = premiumUnlocked ? {...PremiumFeature.values} : {};

  Set<PremiumFeature> _active;

  @override
  bool get isStoreAvailable => false;

  @override
  Future<Set<PremiumFeature>> activeEntitlements() async => {..._active};

  @override
  Future<PurchaseOutcome> purchasePass() async {
    _active = {...PremiumFeature.values};
    return PurchaseOutcome.success;
  }

  @override
  Future<PurchaseOutcome> restorePurchases() async => PurchaseOutcome.success;

  /// Aide de developpement : remet le contenu payant sous cle.
  void reset() => _active = {};
}
