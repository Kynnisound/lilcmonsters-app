/// Contenus telechargeables (livres audio, pages de coloriage, videos de la
/// marque). Future implementation : FirebaseStorageService (firebase_storage).
abstract interface class StorageService {
  /// Renvoie une URI lisible (https:// en production, asset:// en local).
  Future<Uri?> resolve(String path);
}

/// Resout les chemins vers les assets embarques dans l'appli.
class LocalAssetStorageService implements StorageService {
  const LocalAssetStorageService();

  @override
  Future<Uri?> resolve(String path) async => Uri(scheme: 'asset', path: path);
}
