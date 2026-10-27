/// Reglages a distance (activation d'un module, URL de chaine, saison...).
/// Future implementation : FirebaseRemoteConfigService (firebase_remote_config).
abstract interface class RemoteConfigService {
  Future<void> fetchAndActivate();
  String getString(String key);
  bool getBool(String key);
}

abstract final class RemoteConfigKeys {
  static const youtubeChannelUrl = 'youtube_channel_url';
  static const paywallEnabled = 'paywall_enabled';
  static const forestFreeMonsters = 'forest_free_monsters';
}

class LocalRemoteConfigService implements RemoteConfigService {
  LocalRemoteConfigService([Map<String, Object>? overrides])
    : _values = {..._defaults, ...?overrides};

  static const Map<String, Object> _defaults = {
    RemoteConfigKeys.youtubeChannelUrl: 'https://www.youtube.com/@LilCMonsters',
    RemoteConfigKeys.paywallEnabled: false,
    RemoteConfigKeys.forestFreeMonsters: '3',
  };

  final Map<String, Object> _values;

  @override
  Future<void> fetchAndActivate() async {}

  @override
  String getString(String key) => '${_values[key] ?? ''}';

  @override
  bool getBool(String key) => _values[key] == true;
}
