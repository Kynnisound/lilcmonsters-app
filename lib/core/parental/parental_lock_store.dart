import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Etat de blocage de la porte parentale enregistre sur l'appareil
/// (BUG-011) : compteur d'erreurs, palier de blocage, heure de fin, et
/// changements de question (« Autre question ») deja utilises et question
/// en cours (BUG-019).
/// Aucune donnee personnelle, rien ne quitte l'appareil.
class ParentalLockRecord {
  const ParentalLockRecord({
    this.failures = 0,
    this.lockouts = 0,
    this.lockedUntil,
    this.skipsUsed = 0,
    this.questionA = 0,
    this.questionB = 0,
    this.revision = 0,
  });

  /// Mauvaises reponses de suite depuis le dernier blocage.
  final int failures;

  /// Palier : nombre de blocages depuis la derniere reussite.
  final int lockouts;

  /// Heure de fin du blocage en cours (horloge murale), ou nulle.
  final DateTime? lockedUntil;

  /// « Autre question » deja utilises depuis la derniere reussite (ou la fin
  /// du dernier blocage). Survit a la fermeture de la porte (BUG-019).
  final int skipsUsed;

  /// Question en cours (a fois b), 0 et 0 si aucune : rouvrir la porte
  /// remontre la meme question (BUG-019, retest 6). Elle ne change qu'avec
  /// « Autre question », apres une bonne reponse ou a la fin d'un blocage.
  final int questionA;
  final int questionB;

  bool get hasQuestion => questionA > 0 && questionB > 0;

  /// Numero d'ecriture, croissant : distingue une ecriture plus recente
  /// (autre onglet, BUG-016) d'une plus ancienne.
  final int revision;

  /// Meme etat de blocage (sans le numero d'ecriture).
  bool sameState(ParentalLockRecord o) =>
      o.failures == failures &&
      o.lockouts == lockouts &&
      o.lockedUntil == lockedUntil &&
      o.skipsUsed == skipsUsed &&
      o.questionA == questionA &&
      o.questionB == questionB;

  /// Compteur d'erreurs et blocage a zero (bonne reponse), quels que soient
  /// les changements de question et la question en cours.
  bool get isCleared => failures == 0 && lockouts == 0 && lockedUntil == null;

  @override
  bool operator ==(Object other) =>
      other is ParentalLockRecord &&
      other.failures == failures &&
      other.lockouts == lockouts &&
      other.lockedUntil == lockedUntil &&
      other.skipsUsed == skipsUsed &&
      other.questionA == questionA &&
      other.questionB == questionB &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(
    failures,
    lockouts,
    lockedUntil,
    skipsUsed,
    questionA,
    questionB,
    revision,
  );

  @override
  String toString() =>
      'ParentalLockRecord($failures, $lockouts, '
      '${lockedUntil?.toIso8601String()}, skips $skipsUsed, '
      'q ${questionA}x$questionB, r$revision)';
}

/// Lecture synchrone, ecriture immediate. La porte relit l'etat avant
/// chaque verification (BUG-016 : plusieurs onglets partagent le meme
/// stockage sur le web).
abstract class ParentalLockStore {
  ParentalLockRecord load();
  void save(ParentalLockRecord record);

  /// Ecriture faite ailleurs (autre onglet : evenement storage du
  /// navigateur). Flux vide sur mobile (une seule instance de l'appli).
  Stream<void> get changes => const Stream.empty();
}

/// Memoire seulement : tests, et repli si les preferences sont
/// indisponibles au demarrage.
class MemoryParentalLockStore extends ParentalLockStore {
  MemoryParentalLockStore([this.record = const ParentalLockRecord()]);
  ParentalLockRecord record;
  int saves = 0;
  final _changes = StreamController<void>.broadcast(sync: true);

  @override
  Stream<void> get changes => _changes.stream;

  /// Tests : un autre onglet a ecrit [r].
  void writeFromOtherTab(ParentalLockRecord r) {
    record = r;
    _changes.add(null);
  }

  @override
  ParentalLockRecord load() => record;

  @override
  void save(ParentalLockRecord r) {
    record = r;
    saves++;
  }
}

/// shared_preferences : UserDefaults sur iOS (PrivacyInfo.xcprivacy,
/// raison CA92.1), SharedPreferences sur Android, localStorage sur le web.
/// Local seulement, sans reseau.
class PrefsParentalLockStore extends ParentalLockStore {
  PrefsParentalLockStore(this.prefs);
  final SharedPreferences prefs;

  static const failuresKey = 'parental_gate.failures';
  static const lockoutsKey = 'parental_gate.lockouts';
  static const lockedUntilKey = 'parental_gate.locked_until_ms';
  static const revisionKey = 'parental_gate.revision';
  static const skipsUsedKey = 'parental_gate.skips_used';
  static const questionAKey = 'parental_gate.question_a';
  static const questionBKey = 'parental_gate.question_b';
  static const keys = {
    questionAKey,
    questionBKey,
    failuresKey,
    lockoutsKey,
    lockedUntilKey,
    revisionKey,
    skipsUsedKey,
  };

  @override
  ParentalLockRecord load() {
    int read(String k) {
      final v = prefs.get(k);
      return v is int && v >= 0 ? v : 0;
    }

    final until = read(lockedUntilKey);
    return ParentalLockRecord(
      failures: read(failuresKey),
      lockouts: read(lockoutsKey),
      lockedUntil: until > 0
          ? DateTime.fromMillisecondsSinceEpoch(until)
          : null,
      skipsUsed: read(skipsUsedKey),
      questionA: read(questionAKey),
      questionB: read(questionBKey),
      revision: read(revisionKey),
    );
  }

  @override
  void save(ParentalLockRecord r) {
    // Le cache est mis a jour tout de suite, l'ecriture disque suit.
    prefs.setInt(failuresKey, r.failures);
    prefs.setInt(lockoutsKey, r.lockouts);
    prefs.setInt(skipsUsedKey, r.skipsUsed);
    prefs.setInt(questionAKey, r.questionA);
    prefs.setInt(questionBKey, r.questionB);
    prefs.setInt(revisionKey, r.revision);
    final until = r.lockedUntil;
    if (until == null) {
      prefs.remove(lockedUntilKey);
    } else {
      prefs.setInt(lockedUntilKey, until.millisecondsSinceEpoch);
    }
  }
}

/// Remplace au demarrage par [PrefsParentalLockStore] (app/bootstrap.dart).
final parentalLockStoreProvider = Provider<ParentalLockStore>(
  (ref) => MemoryParentalLockStore(),
);

/// Horloge monotone (ne recule pas, ignore les changements d'heure de
/// l'appareil), remplacable dans les tests.
final parentalMonotonicProvider = Provider<Duration Function()>((ref) {
  final watch = Stopwatch()..start();
  return () => watch.elapsed;
});
