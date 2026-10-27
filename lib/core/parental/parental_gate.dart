import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

export 'parental_lock_store.dart';

import '../config/config_providers.dart';
import 'parental_lock_store.dart';
import '../router/routes.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Porte parentale (BUG-001, BUG-002, BUG-003 de la QA du 27/10/2026).
///
/// - Question pour adulte ecrite en toutes lettres (« Combien font sept fois
///   huit ? »), reponse de deux chiffres saisie sur un pave numerique puis
///   validee : un enfant qui ne lit pas ne peut pas la resoudre, et un
///   tapotement au hasard a moins d'une chance sur cent par validation.
/// - Trois mauvaises reponses de suite ferment la porte et la bloquent
///   1 min, puis 5 min, puis 15 min (le compteur survit a la fermeture de
///   la porte ; il revient a zero apres une reussite).
/// - Aucune session reutilisable : chaque sortie (lien YouTube) et chaque
///   entree dans l'espace parents redemande la porte. Une reussite donne
///   un laissez-passer a usage unique, valable quelques secondes, pour
///   l'ecran demande ; l'espace parents reste ouvert tant qu'il est affiche
///   et se referme a toute sortie (croix, retour systeme, arriere-plan).
/// - Ni son, ni animation d'erreur.

const _units = [
  'zero',
  'un',
  'deux',
  'trois',
  'quatre',
  'cinq',
  'six',
  'sept',
  'huit',
  'neuf',
  'dix',
  'onze',
  'douze',
  'treize',
  'quatorze',
  'quinze',
  'seize',
];
const _tens = {
  2: 'vingt',
  3: 'trente',
  4: 'quarante',
  5: 'cinquante',
  6: 'soixante',
};

/// Nombre de 0 a 99 en toutes lettres (orthographe traditionnelle).
String frenchNumber(int n) {
  assert(n >= 0 && n < 100);
  if (n <= 16) return _units[n];
  if (n < 20) return 'dix-${_units[n - 10]}';
  if (n < 70) {
    final t = _tens[n ~/ 10]!, u = n % 10;
    if (u == 0) return t;
    return u == 1 ? '$t et un' : '$t-${_units[u]}';
  }
  if (n < 80) {
    final r = n - 60;
    return r == 11 ? 'soixante et onze' : 'soixante-${frenchNumber(r)}';
  }
  if (n == 80) return 'quatre-vingts';
  return 'quatre-vingt-${frenchNumber(n - 80)}';
}

/// Question pour adulte ecrite en lettres (BUG-012, BUG-015, BUG-019).
///
/// - Uniquement des multiplications : une table parmi 6, 7, 8, 9 et 12 par
///   un nombre de 6 a 25, sans 10, 11 ni 20 (« Combien font sept fois
///   dix-huit ? »). Aucun facteur dix, onze ou vingt, d'un cote comme de
///   l'autre : ces tables sont a la portee d'un enfant de 7 ans (BUG-019).
/// - Plus aucune addition (retest 5, BUG-019) : un enfant qui sait additionner
///   pouvait changer de question jusqu'a tomber sur une addition.
/// - La reponse est tiree uniformement parmi les [answers] (61 produits de
///   36 a 300, 1,6 % chacun, saisis sur 3 chiffres au plus), puis ecrite
///   avec l'une de ses multiplications. Sans 10 ni 11, le multiplicateur de
///   6 a 19 ne laisserait que 42 produits (2,4 % par reponse, au-dela du
///   plafond de 2 %) : d'ou la plage elargie jusqu'a 25.
/// - La porte ne repose jamais une question dont la reponse vient d'etre
///   saisie ou vue.
class ParentalChallenge {
  const ParentalChallenge(this.a, this.b);
  final int a;
  final int b;

  /// Tables (premier facteur) et multiplicateurs (second facteur).
  static const tables = [6, 7, 8, 9, 12];
  static const multipliers = [
    6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, //
  ];

  /// Facteurs jamais poses : trop faciles (BUG-019).
  static const easyFactors = {10, 11, 20};

  /// Reponses possibles, toutes equiprobables.
  static final List<int> answers = {
    for (final x in tables)
      for (final y in multipliers) x * y,
  }.toList()..sort();

  static int get minAnswer => answers.first;
  static int get maxAnswer => answers.last;

  int get answer => a * b;

  /// Question lue (lecteur d'ecran, tests) : traits d'union ordinaires.
  String get question =>
      'Combien font ${frenchNumber(a)} fois ${frenchNumber(b)}\u00a0?';

  /// Mots de la question, affiches chacun d'un bloc : la ligne ne se coupe
  /// qu'entre deux mots, jamais au trait d'union de « dix-huit » (BUG-021).
  /// Le « ? » reste colle au dernier mot (espace insecable).
  List<String> get words => question.split(' ');

  static List<ParentalChallenge> multiplications(int answer) => [
    for (final x in tables)
      if (answer % x == 0 && multipliers.contains(answer ~/ x))
        ParentalChallenge(x, answer ~/ x),
  ];

  /// Toutes les ecritures possibles de [answer] (multiplications seules).
  static List<ParentalChallenge> writings(int answer) =>
      multiplications(answer);

  factory ParentalChallenge.random(Random rng) {
    final answer = answers[rng.nextInt(answers.length)];
    final times = multiplications(answer);
    return times[rng.nextInt(times.length)];
  }

  @override
  String toString() => question;
}

final parentalChallengeFactoryProvider = Provider<ParentalChallenge Function()>(
  (ref) {
    final rng = Random.secure();
    return () => ParentalChallenge.random(rng);
  },
);

/// Horloge de la porte (remplacable dans les tests).
final parentalClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Ecrans proteges qui recoivent un laissez-passer a usage unique.
enum ParentalPurpose { parentsSpace, lighthouse }

/// Etat de la porte : echecs, blocage temporise, laissez-passer, ecrans
/// proteges ouverts. Objet simple (personne ne l'ecoute), modifiable a tout
/// moment, y compris pendant un dispose.
///
/// BUG-011 : le compteur d'erreurs, le palier et l'heure de fin du blocage
/// sont enregistres sur l'appareil ([ParentalLockStore]) et relus au
/// lancement : relancer l'appli ne leve pas le blocage. L'heure de fin
/// resiste a une horloge reculee (le reste a attendre ne depasse jamais la
/// duree du palier, et l'heure de fin est recalee sur la nouvelle horloge)
/// et, tant que l'appli tourne, a une horloge avancee (horloge monotone).
class ParentalAccess {
  ParentalAccess({
    required this.now,
    required this.readGateEnabled,
    ParentalLockStore? store,
    this.monotonic,
  }) : store = store ?? MemoryParentalLockStore() {
    final r = this.store.load();
    _failures = min(r.failures, maxFailures - 1);
    _lockouts = r.lockouts;
    _lockedUntil = r.lockedUntil;
    _skipsUsed = min(r.skipsUsed, maxSkips);
    _challenge = _challengeOf(r);
    _revision = r.revision;
    if (_lockedUntil != null) {
      // Relu au lancement : on recale tout de suite (horloge reculee
      // pendant que l'appli etait fermee) et on arme l'horloge monotone.
      final left = _wallLeft();
      if (left > _step) {
        _lockedUntil = now().add(_step);
        _save();
      }
      _armMonotonic(_wallLeft());
    }
  }

  final DateTime Function() now;

  /// Lit le reglage de la porte (toujours vrai en release).
  final bool Function() readGateEnabled;

  /// Etat de blocage enregistre sur l'appareil.
  final ParentalLockStore store;

  /// Horloge monotone de la session (nulle : horloge murale seule).
  final Duration Function()? monotonic;

  /// Mauvaises reponses de suite avant blocage.
  static const maxFailures = 3;

  /// « Autre question » : 3 changements au plus entre deux reussites
  /// (BUG-019). Le compteur est enregistre avec l'etat de blocage : fermer
  /// puis rouvrir la porte ne le remet pas a zero ; seule une reussite, ou
  /// la fin d'un blocage, le fait.
  static const maxSkips = 3;

  /// Durees de blocage successives (la derniere se repete).
  static const lockSteps = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  /// Le laissez-passer ne sert qu'a la navigation qui suit la reussite.
  static const passValidity = Duration(seconds: 10);

  bool get gateEnabled => readGateEnabled();

  int _failures = 0;
  int _lockouts = 0;
  int _skipsUsed = 0;
  ParentalChallenge? _challenge;
  DateTime? _lockedUntil;
  int _revision = 0;
  Duration? _monotonicEnd;
  ParentalPurpose? _pass;
  DateTime? _passAt;
  final _open = <ParentalPurpose>{};

  /// Derniere bonne reponse : jamais reposee juste apres (BUG-012).
  int? lastAnswer;

  int get failures => _failures;

  /// « Autre question » deja utilises (relu dans le stockage : un autre
  /// onglet a pu en utiliser).
  int get skipsUsed {
    sync();
    return _skipsUsed;
  }

  int get skipsLeft => max(0, maxSkips - skipsUsed);

  /// Utilise un changement de question et enregistre la nouvelle question
  /// [next]. Renvoie faux s'il n'en reste plus.
  bool recordSkip([ParentalChallenge? next]) {
    sync();
    if (_skipsUsed >= maxSkips) return false;
    _skipsUsed++;
    if (next != null) _challenge = next;
    _save();
    return true;
  }

  /// Question valide enregistree, ou nulle (valeur abimee ou hors tables).
  static ParentalChallenge? _challengeOf(ParentalLockRecord r) {
    if (!r.hasQuestion) return null;
    if (!ParentalChallenge.tables.contains(r.questionA) ||
        !ParentalChallenge.multipliers.contains(r.questionB)) {
      return null;
    }
    return ParentalChallenge(r.questionA, r.questionB);
  }

  /// Question en cours (relue dans le stockage : un autre onglet a pu la
  /// changer), ou nulle si la prochaine ouverture doit en tirer une.
  ParentalChallenge? get currentChallenge {
    sync();
    return _challenge;
  }

  /// Remplace la question en cours apres une mauvaise reponse, sans
  /// utiliser de changement de question (« Autre question »).
  void replaceChallenge(ParentalChallenge next) {
    sync();
    _challenge = next;
    _save();
  }

  /// Question en cours ; si aucune, tire [draw] et l'enregistre. Rouvrir la
  /// porte remontre donc la meme question (BUG-019, retest 6) : elle ne
  /// change qu'avec « Autre question », apres une bonne ou une mauvaise
  /// reponse, ou a la fin d'un blocage.
  ParentalChallenge ensureChallenge(ParentalChallenge Function() draw) {
    sync();
    final c = _challenge;
    if (c != null) return c;
    final next = draw();
    _challenge = next;
    _save();
    return next;
  }

  /// Palier de blocage (nombre de blocages depuis la derniere reussite).
  int get lockouts => _lockouts;

  /// Heure de fin du blocage en cours (horloge murale), ou nulle.
  DateTime? get lockedUntil => _lockedUntil;

  /// Duree du blocage en cours.
  Duration get _step =>
      lockSteps[(max(_lockouts, 1) - 1).clamp(0, lockSteps.length - 1)];

  Duration _wallLeft() => _lockedUntil!.difference(now());

  void _armMonotonic(Duration left) {
    final m = monotonic;
    _monotonicEnd = m == null ? null : m() + left;
  }

  void _save() {
    _revision = max(_revision, store.load().revision) + 1;
    store.save(
      ParentalLockRecord(
        failures: _failures,
        lockouts: _lockouts,
        lockedUntil: _lockedUntil,
        skipsUsed: _skipsUsed,
        questionA: _challenge?.a ?? 0,
        questionB: _challenge?.b ?? 0,
        revision: _revision,
      ),
    );
  }

  /// BUG-016 : relit l'etat enregistre (un autre onglet a pu ecrire) avant
  /// chaque verification. Le blocage le plus strict gagne toujours ; une
  /// ecriture plus ancienne, ou d'un onglet qui ignorait le blocage, ne
  /// l'efface jamais (il est alors reecrit).
  void sync() {
    final r = store.load();
    final mine = ParentalLockRecord(
      failures: _failures,
      lockouts: _lockouts,
      lockedUntil: _lockedUntil,
      skipsUsed: _skipsUsed,
      questionA: _challenge?.a ?? 0,
      questionB: _challenge?.b ?? 0,
    );
    if (r.revision == _revision && r.sameState(mine)) return;
    final newer = r.revision > _revision;
    final theirs = r.lockedUntil;
    final ours = _lockedUntil;
    final theirsActive = theirs != null && theirs.isAfter(now());
    final oursActive = isLockActiveInMemory;
    if (theirsActive && (ours == null || theirs.isAfter(ours))) {
      // Blocage pose ailleurs, ou plus long : on le prend.
      _lockedUntil = theirs;
      _lockouts = max(_lockouts, r.lockouts);
      final left = _wallLeft();
      _armMonotonic(left > _step ? _step : left);
    }
    if (newer) {
      _revision = r.revision;
      _lockouts = max(_lockouts, r.lockouts);
      // La question en cours suit toujours l'ecriture la plus recente.
      _challenge = _challengeOf(r);
      if (r.isCleared && !oursActive && !theirsActive) {
        // Bonne reponse dans un autre onglet : compteur et palier a zero
        // (l'onglet a pu deja tirer la question suivante, ou changer de
        // question : on reprend ses changements et sa question).
        _failures = 0;
        _lockouts = 0;
        _lockedUntil = null;
        _monotonicEnd = null;
        _skipsUsed = min(r.skipsUsed, maxSkips);
      } else {
        if (!oursActive || theirsActive) {
          _failures = min(r.failures, maxFailures - 1);
        }
        // Changements de question : l'ecriture la plus recente fait foi
        // (elle ne redescend qu'apres une reussite ou une fin de blocage).
        _skipsUsed = min(r.skipsUsed, maxSkips);
      }
    }
    // Notre blocage est plus strict que l'etat enregistre : on le reecrit.
    final stored = theirs;
    if (oursActive && (stored == null || stored.isBefore(_lockedUntil!))) {
      _save();
    } else if (!newer && !r.sameState(mine) && !theirsActive) {
      _save();
    }
  }

  /// Blocage en memoire pas encore echu (sans relire le stockage).
  bool get isLockActiveInMemory {
    final until = _lockedUntil;
    if (until == null) return false;
    final m = monotonic, end = _monotonicEnd;
    return until.isAfter(now()) || (m != null && end != null && end > m());
  }

  /// Temps de blocage restant, ou nul si la porte est utilisable.
  Duration? get lockRemaining {
    sync();
    if (_lockedUntil == null) return null;
    var left = _wallLeft();
    final m = monotonic, end = _monotonicEnd;
    final mono = m == null || end == null ? null : end - m();
    var moved = false;
    if (left > _step) {
      // Horloge reculee : jamais plus que le palier, et l'horloge monotone
      // dit ce qu'il reste vraiment.
      left = mono == null ? _step : (mono > _step ? _step : mono);
      moved = true;
    } else if (mono != null && mono - left > const Duration(seconds: 1)) {
      // Horloge avancee pendant que l'appli tourne : on garde le vrai reste.
      left = mono;
      moved = true;
    }
    if (left <= Duration.zero) {
      _lockedUntil = null;
      _monotonicEnd = null;
      // Fin du blocage : de nouveau 3 changements de question, et une
      // nouvelle question a la prochaine ouverture.
      _skipsUsed = 0;
      _challenge = null;
      _save();
      return null;
    }
    if (moved) {
      // Heure de fin recalee sur la nouvelle horloge, pour la relance.
      _lockedUntil = now().add(left);
      _save();
    }
    return left;
  }

  bool get isLocked => lockRemaining != null;

  /// Enregistre une mauvaise reponse. Renvoie vrai si la porte se bloque.
  bool recordFailure() {
    sync();
    _failures++;
    if (_failures < maxFailures) {
      _save();
      return false;
    }
    _failures = 0;
    _lockouts++;
    _lockedUntil = now().add(_step);
    _armMonotonic(_step);
    _save();
    return true;
  }

  void recordSuccess([int? answer]) {
    sync();
    _failures = 0;
    _lockouts = 0;
    _lockedUntil = null;
    _monotonicEnd = null;
    _skipsUsed = 0;
    // Bonne reponse : nouvelle question a la prochaine ouverture.
    _challenge = null;
    if (answer != null) lastAnswer = answer;
    _save();
  }

  void issuePass(ParentalPurpose purpose) {
    _pass = purpose;
    _passAt = now();
  }

  bool hasPass(ParentalPurpose purpose) {
    if (!gateEnabled) return true;
    final at = _passAt;
    return _pass == purpose &&
        at != null &&
        now().difference(at) < passValidity;
  }

  /// Utilise le laissez-passer (une seule fois).
  bool consumePass(ParentalPurpose purpose) {
    final ok = hasPass(purpose);
    _pass = null;
    _passAt = null;
    return ok;
  }

  /// Ecran protege affiche (le laissez-passer a ete utilise).
  bool isOpen(ParentalPurpose purpose) => _open.contains(purpose);
  void open(ParentalPurpose purpose) => _open.add(purpose);
  void close(ParentalPurpose purpose) {
    _open.remove(purpose);
    if (_pass == purpose) {
      _pass = null;
      _passAt = null;
    }
  }

  bool get parentsSpaceOpen => isOpen(ParentalPurpose.parentsSpace);
  void openParentsSpace() => open(ParentalPurpose.parentsSpace);
  void closeParentsSpace() => close(ParentalPurpose.parentsSpace);

  /// Garde du routeur (BUG-013) : un ecran protege ne s'affiche qu'avec un
  /// laissez-passer frais ou pendant qu'il est deja ouvert. Les boutons
  /// Precedent et Suivant du navigateur repassent par cette garde.
  bool mayShow(ParentalPurpose purpose) =>
      !gateEnabled || isOpen(purpose) || hasPass(purpose);

  bool get mayShowParentsSpace => mayShow(ParentalPurpose.parentsSpace);
}

final parentalAccessProvider = Provider<ParentalAccess>(
  (ref) => ParentalAccess(
    now: ref.read(parentalClockProvider),
    readGateEnabled: () => ref.read(appConfigProvider).parentalGateEnabled,
    store: ref.read(parentalLockStoreProvider),
    monotonic: ref.read(parentalMonotonicProvider),
  ),
);

/// Resultat d'une validation.
enum GateStep { typing, wrong, success, lockedOut }

/// Logique du formulaire de la porte (pave numerique), sans widget :
/// utilisee par [ParentalGateView] et par les tests de tapotement.
class ParentalGateForm {
  ParentalGateForm(this.access, this.nextChallenge) {
    access.ensureChallenge(() => _draw(nextChallenge(), {?access.lastAnswer}));
  }

  final ParentalAccess access;
  final ParentalChallenge Function() nextChallenge;

  /// Question affichee : celle enregistree avec l'etat de la porte (meme
  /// question a chaque ouverture, et dans tous les onglets).
  ParentalChallenge get challenge => access.ensureChallenge(
    () => _draw(nextChallenge(), {?access.lastAnswer}),
  );
  String entry = '';
  bool wrong = false;

  static const maxDigits = 3;

  /// « Autre question » : 3 changements au plus entre deux reussites, pour
  /// ne pas tirer jusqu'a une question qui plait (BUG-019). Le compteur vit
  /// dans [ParentalAccess] et dans le stockage : rouvrir la porte ne rend
  /// pas de changement.
  static const maxSkips = ParentalAccess.maxSkips;
  int get skipsLeft => access.skipsLeft;

  bool get canSkip => !access.isLocked && skipsLeft > 0;

  void type(int digit) {
    if (entry.length < maxDigits) entry += '$digit';
  }

  void erase() {
    if (entry.isNotEmpty) entry = entry.substring(0, entry.length - 1);
  }

  bool get canSubmit => entry.isNotEmpty && !access.isLocked;

  GateStep submit() {
    if (!canSubmit) return GateStep.typing;
    final typed = int.tryParse(entry);
    if (typed == challenge.answer) {
      access.recordSuccess(challenge.answer);
      return GateStep.success;
    }
    entry = '';
    if (access.recordFailure()) return GateStep.lockedOut;
    wrong = true;
    // Nouvelle question apres une erreur (pas de force brute sur la meme
    // question), jamais une question dont la reponse vient d'etre saisie
    // (BUG-012). Enregistree, sans utiliser d'« Autre question ».
    access.replaceChallenge(
      _draw(nextChallenge(), {?typed, challenge.answer, ?access.lastAnswer}),
    );
    return GateStep.wrong;
  }

  /// « Autre question » : nouvelle question, saisie videe. Ne compte pas
  /// comme une erreur et ne remet pas le compteur d'erreurs a zero (seule
  /// une bonne reponse le fait).
  void skip() {
    if (!canSkip) return;
    final next = _draw(nextChallenge(), {challenge.answer, ?access.lastAnswer});
    if (!access.recordSkip(next)) return;
    entry = '';
    wrong = false;
  }

  /// Nouvelle question dont la reponse n'est pas dans [avoid] (quelques
  /// tirages au plus : une fabrique fixe, dans les tests, reste acceptee).
  ParentalChallenge _draw(ParentalChallenge first, Set<int> avoid) {
    var c = first;
    for (var i = 0; i < 16; i++) {
      if (!avoid.contains(c.answer)) return c;
      c = nextChallenge();
    }
    return c;
  }
}

/// Ouvre la porte parentale (toujours, aucune session). Renvoie vrai si
/// l'adulte a repondu juste.
Future<bool> requestParentalAccess(BuildContext context, WidgetRef ref) async {
  if (!ref.read(parentalAccessProvider).gateEnabled) return true;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const Dialog(
          backgroundColor: AppColors.paper,
          insetPadding: EdgeInsets.all(12),
          child: ParentalGateView(),
        ),
      ) ??
      false;
}

/// Porte puis espace parents (carte, contenus du pass).
Future<void> openParentsSpace(BuildContext context, WidgetRef ref) async {
  if (!await requestParentalAccess(context, ref) || !context.mounted) return;
  ref.read(parentalAccessProvider).issuePass(ParentalPurpose.parentsSpace);
  // go et non push : l'adresse /parents passe par la garde du routeur, y
  // compris quand le navigateur la ressort de son historique (BUG-013).
  context.go(Routes.parents);
}

/// Hauteur minimale des boutons adultes de la porte (Annuler, Fermer,
/// Autre question).
const minAdultTarget = 48.0;

/// Ecart entre deux touches du pave.
const keypadGap = 8.0;

/// Contenu de la porte parentale, utilisable en dialogue ou en plein ecran.
class ParentalGateView extends ConsumerStatefulWidget {
  const ParentalGateView({super.key, this.onResult});

  /// Si nul, le resultat est renvoye par Navigator.pop.
  final ValueChanged<bool>? onResult;

  @override
  ConsumerState<ParentalGateView> createState() => _ParentalGateViewState();
}

class _ParentalGateViewState extends ConsumerState<ParentalGateView> {
  late final ParentalAccess _access = ref.read(parentalAccessProvider);
  late final ParentalGateForm _form = ParentalGateForm(
    _access,
    ref.read(parentalChallengeFactoryProvider),
  );
  bool _done = false;
  Timer? _tick;
  StreamSubscription<void>? _otherTab;

  @override
  void initState() {
    super.initState();
    _watchLock();
    // Blocage pose dans un autre onglet (web) : affiche tout de suite.
    _otherTab = _access.store.changes.listen((_) {
      if (!mounted) return;
      setState(_watchLock);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _otherTab?.cancel();
    super.dispose();
  }

  /// Rafraichit le compte a rebours tant que la porte est bloquee.
  void _watchLock() {
    _tick?.cancel();
    if (!_access.isLocked) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_access.isLocked) _tick?.cancel();
      setState(() {});
    });
  }

  void _finish(bool ok) {
    if (_done) return;
    _done = true;
    if (widget.onResult != null) {
      widget.onResult!(ok);
    } else {
      Navigator.of(context).pop(ok);
    }
  }

  void _type(String digit) => setState(() => _form.type(int.parse(digit)));

  void _erase() => setState(_form.erase);

  void _skip() => setState(_form.skip);

  void _submit() {
    switch (_form.submit()) {
      case GateStep.success:
        _finish(true);
      case GateStep.lockedOut:
        // Trop d'erreurs : la porte se ferme, retour a l'ecran precedent.
        _finish(false);
      case GateStep.wrong || GateStep.typing:
        setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final left = _access.lockRemaining;
    return Semantics(
      container: true,
      label: 'Porte parentale',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_compact ? 12 : 16),
          child: left != null ? _locked(t, left) : _formView(t),
        ),
      ),
    );
  }

  // 48 dp de haut au moins (BUG-014) : densite standard, sans le -4 dp du
  // theme (VisualDensity.comfortable).
  Widget _cancel(String label) => TextButton(
    key: const Key('parental-cancel'),
    style: TextButton.styleFrom(
      minimumSize: const Size(120, minAdultTarget),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.padded,
    ),
    onPressed: () => _finish(false),
    child: Text(label),
  );

  // Discret : texte plus petit, meme cible de 48 dp.
  Widget _other(TextTheme t) => TextButton(
    key: const Key('parental-other'),
    style: TextButton.styleFrom(
      minimumSize: const Size(0, minAdultTarget),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: AppColors.plum2,
      textStyle: t.bodyMedium,
    ),
    // Grise apres 3 changements (BUG-019).
    onPressed: _form.canSkip ? _skip : null,
    child: const Text('Autre question'),
  );

  Widget _locked(TextTheme t, Duration left) {
    final s = left.inSeconds + 1;
    final when = s > 60 ? '${(s / 60).ceil()} min' : '$s s';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Reserve aux parents', style: t.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Trop de reponses fausses. Nouvel essai possible dans $when.',
          key: const Key('parental-locked'),
          style: t.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _cancel('Fermer'),
      ],
    );
  }

  /// Tres petits ecrans (568 x 320) : marges et titre reduits pour que
  /// Annuler et Autre question restent entiers a l'ecran (BUG-014, retest 4).
  bool get _compact => MediaQuery.sizeOf(context).height < 400;

  Widget _formView(TextTheme t) {
    final gap = SizedBox(height: _compact ? 4 : 8);
    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reserve aux parents',
          style: _compact
              ? t.headlineMedium?.copyWith(fontSize: 24)
              : t.headlineMedium,
        ),
        gap,
        ParentalQuestionText(
          _form.challenge,
          key: const Key('parental-question'),
          // Telephone en paysage (568 x 320) : un peu plus petit (BUG-021).
          style: _compact ? t.titleLarge?.copyWith(fontSize: 19) : t.titleLarge,
        ),
        gap,
        // Le message d'erreur prend la place de la consigne : la boite garde
        // la meme hauteur apres une erreur.
        if (_form.wrong)
          Text(
            'Ce n\'est pas la bonne reponse.',
            key: const Key('parental-wrong'),
            style: t.bodyLarge?.copyWith(color: AppColors.bitsy),
          )
        else
          Text('Tapez la reponse puis validez.', style: t.bodyLarge),
        gap,
        Semantics(
          label: 'Reponse saisie',
          value: _form.entry,
          child: Container(
            key: const Key('parental-entry'),
            width: 120,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.m),
              border: Border.all(color: AppColors.plum2, width: 2),
            ),
            child: ExcludeSemantics(
              child: Text(_form.entry, style: t.headlineMedium),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [_cancel('Annuler'), _other(t)],
        ),
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(child: info),
        const SizedBox(width: 16),
        _keypad(),
      ],
    );
  }

  static const _key = Size(64, 50);

  /// 8 dp entre deux touches voisines (BUG-014).
  static const _gap = keypadGap;

  Widget _keypad() {
    final style = AppTheme.parentButton.copyWith(
      minimumSize: const WidgetStatePropertyAll(_key),
      fixedSize: const WidgetStatePropertyAll(_key),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );
    Widget digit(int d) => FilledButton(
      key: Key('parental-key-$d'),
      style: style,
      onPressed: () => _type('$d'),
      child: Text('$d'),
    );
    Widget row(List<Widget> keys) => Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            keys[i],
          ],
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit(1), digit(2), digit(3)]),
        row([digit(4), digit(5), digit(6)]),
        row([digit(7), digit(8), digit(9)]),
        row([
          FilledButton(
            key: const Key('parental-erase'),
            style: style.copyWith(
              backgroundColor: const WidgetStatePropertyAll(AppColors.mist),
              foregroundColor: const WidgetStatePropertyAll(AppColors.plum),
            ),
            onPressed: _erase,
            child: const Icon(
              Icons.backspace_rounded,
              semanticLabel: 'Effacer',
            ),
          ),
          digit(0),
          FilledButton(
            key: const Key('parental-submit'),
            // Grise tant que rien n'est saisi, icone toujours visible.
            style: style.copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? AppColors.plum.withValues(alpha: .4)
                    : AppColors.plum,
              ),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
            ),
            onPressed: _form.canSubmit ? _submit : null,
            child: const Icon(Icons.check_rounded, semanticLabel: 'Valider'),
          ),
        ]),
      ],
    );
  }
}

/// Question de la porte (BUG-021) : chaque mot est un bloc insecable, la
/// ligne ne se coupe qu'entre deux mots, jamais au trait d'union de
/// « dix-huit » ou « vingt-quatre ». Pas de trait d'union insecable U+2011 :
/// les polices de l'appli (Baloo 2) ne l'ont pas, il faudrait une police de
/// secours (telechargee sur le web). Un mot trop long pour la largeur est
/// reduit (scaleDown) plutot que coupe.
class ParentalQuestionText extends StatelessWidget {
  const ParentalQuestionText(this.challenge, {super.key, this.style});

  final ParentalChallenge challenge;
  final TextStyle? style;

  /// Texte complet, lu par les lecteurs d'ecran.
  String get question => challenge.question;

  @override
  Widget build(BuildContext context) {
    final words = challenge.words;
    return Semantics(
      label: question,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) => Wrap(
          children: [
            for (var i = 0; i < words.length; i++)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    // Espace de fin dans le mot : Wrap ne l'ajoute pas.
                    i < words.length - 1 ? '${words[i]} ' : words[i],
                    style: style,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
