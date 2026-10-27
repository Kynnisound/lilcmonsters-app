import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import 'parental_lock_store.dart';

/// Web : plusieurs onglets partagent le meme localStorage (BUG-016). Le
/// cache de shared_preferences ne voit pas les ecritures des autres
/// onglets ; on lit et ecrit donc localStorage directement, avec les memes
/// prefixe que shared_preferences_web (« flutter. »), et on ecoute
/// l'evenement storage. Local seulement, sans reseau.
ParentalLockStore createDeviceLockStore(SharedPreferences prefs) =>
    WebParentalLockStore();

class WebParentalLockStore extends ParentalLockStore {
  WebParentalLockStore() {
    web.EventStreamProviders.storageEvent.forTarget(web.window).listen((e) {
      final key = e.key;
      if (key == null || key.startsWith('flutter.parental_gate.')) {
        _changes.add(null);
      }
    });
  }

  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  /// Etat complet dans une seule cle : une ecriture est atomique, un autre
  /// onglet ne lit jamais un etat a moitie ecrit (cles separees : lecture
  /// melangee pendant l'ecriture, constatee avec deux onglets).
  static const stateKey = 'flutter.parental_gate.state';

  static String _k(String key) => 'flutter.$key';

  int _legacy(String key) {
    final v = int.tryParse(web.window.localStorage.getItem(_k(key)) ?? '');
    return v != null && v >= 0 ? v : 0;
  }

  static int _int(Object? v) => v is int && v >= 0 ? v : 0;

  @override
  ParentalLockRecord load() {
    final raw = web.window.localStorage.getItem(stateKey);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final until = _int(m['locked_until_ms']);
        return ParentalLockRecord(
          failures: _int(m['failures']),
          lockouts: _int(m['lockouts']),
          lockedUntil: until > 0
              ? DateTime.fromMillisecondsSinceEpoch(until)
              : null,
          skipsUsed: _int(m['skips_used']),
          questionA: _int(m['question_a']),
          questionB: _int(m['question_b']),
          revision: _int(m['revision']),
        );
      } on Object {
        // Valeur abimee : on retombe sur les anciennes cles.
      }
    }
    // Build de 12:33 : trois cles separees (shared_preferences_web).
    final until = _legacy(PrefsParentalLockStore.lockedUntilKey);
    return ParentalLockRecord(
      failures: _legacy(PrefsParentalLockStore.failuresKey),
      lockouts: _legacy(PrefsParentalLockStore.lockoutsKey),
      lockedUntil: until > 0
          ? DateTime.fromMillisecondsSinceEpoch(until)
          : null,
    );
  }

  @override
  void save(ParentalLockRecord r) {
    final s = web.window.localStorage;
    s.setItem(
      stateKey,
      jsonEncode({
        'failures': r.failures,
        'lockouts': r.lockouts,
        'locked_until_ms': r.lockedUntil?.millisecondsSinceEpoch ?? 0,
        'skips_used': r.skipsUsed,
        'question_a': r.questionA,
        'question_b': r.questionB,
        'revision': r.revision,
      }),
    );
    for (final k in PrefsParentalLockStore.keys) {
      s.removeItem(_k(k));
    }
  }
}
