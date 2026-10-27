import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
import 'remote_config_service.dart';
import 'storage_service.dart';

/// Implementations locales factices. Une fois le projet Firebase cree,
/// les remplacer dans `lib/app/bootstrap.dart` (voir README).
final authServiceProvider = Provider<AuthService>((ref) => LocalAuthService());

final storageServiceProvider = Provider<StorageService>(
  (ref) => const LocalAssetStorageService(),
);

final remoteConfigProvider = Provider<RemoteConfigService>(
  (ref) => LocalRemoteConfigService(),
);
