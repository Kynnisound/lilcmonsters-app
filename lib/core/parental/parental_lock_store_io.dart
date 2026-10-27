import 'package:shared_preferences/shared_preferences.dart';

import 'parental_lock_store.dart';

/// Mobile : une seule instance de l'appli, le cache de shared_preferences
/// suffit (UserDefaults sur iOS, SharedPreferences sur Android).
ParentalLockStore createDeviceLockStore(SharedPreferences prefs) =>
    PrefsParentalLockStore(prefs);
