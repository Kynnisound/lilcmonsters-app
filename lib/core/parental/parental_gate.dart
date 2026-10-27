import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Question pour adulte : une multiplication et trois reponses.
class ParentalChallenge {
  const ParentalChallenge(this.a, this.b, this.choices);
  final int a;
  final int b;
  final List<int> choices;
  int get answer => a * b;

  factory ParentalChallenge.random(Random rng) {
    final a = 3 + rng.nextInt(7);
    final b = 3 + rng.nextInt(7);
    final answer = a * b;
    final choices = <int>{answer};
    while (choices.length < 3) {
      final delta = (1 + rng.nextInt(9)) * (rng.nextBool() ? 1 : -1);
      if (answer + delta > 0) choices.add(answer + delta);
    }
    return ParentalChallenge(a, b, choices.toList()..shuffle(rng));
  }
}

final parentalChallengeFactoryProvider = Provider<ParentalChallenge Function()>(
  (ref) {
    final rng = Random();
    return () => ParentalChallenge.random(rng);
  },
);

/// Session parentale courte : apres une reussite, l'adulte n'a pas a
/// repondre de nouveau pendant [validity].
class ParentalSessionNotifier extends Notifier<DateTime?> {
  static const validity = Duration(minutes: 3);

  @override
  DateTime? build() => null;

  bool get isValid {
    if (!ref.read(appConfigProvider).parentalGateEnabled) return true;
    final at = state;
    return at != null && DateTime.now().difference(at) < validity;
  }

  void grant() => state = DateTime.now();
  void revoke() => state = null;
}

final parentalSessionProvider =
    NotifierProvider<ParentalSessionNotifier, DateTime?>(
      ParentalSessionNotifier.new,
    );

/// Ouvre la porte parentale. Renvoie vrai si l'adulte a repondu juste.
Future<bool> requestParentalAccess(BuildContext context, WidgetRef ref) async {
  final session = ref.read(parentalSessionProvider.notifier);
  if (session.isValid) return true;
  final ok =
      await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const Dialog(
          backgroundColor: AppColors.paper,
          child: ParentalGateView(),
        ),
      ) ??
      false;
  if (ok) session.grant();
  return ok;
}

/// Contenu de la porte parentale, utilisable en dialogue ou en plein ecran.
class ParentalGateView extends ConsumerStatefulWidget {
  const ParentalGateView({super.key, this.onResult});

  /// Si nul, le resultat est renvoye par Navigator.pop.
  final ValueChanged<bool>? onResult;

  @override
  ConsumerState<ParentalGateView> createState() => _ParentalGateViewState();
}

class _ParentalGateViewState extends ConsumerState<ParentalGateView> {
  late ParentalChallenge _challenge;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _challenge = ref.read(parentalChallengeFactoryProvider)();
  }

  void _finish(bool ok) {
    if (widget.onResult != null) {
      if (ok) ref.read(parentalSessionProvider.notifier).grant();
      widget.onResult!(ok);
    } else {
      Navigator.of(context).pop(ok);
    }
  }

  void _answer(int value) {
    if (value == _challenge.answer) {
      _finish(true);
    } else {
      setState(() {
        _wrong = true;
        _challenge = ref.read(parentalChallengeFactoryProvider)();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Porte parentale',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.family_restroom_rounded,
                  size: 48,
                  color: AppColors.plum2,
                ),
                const SizedBox(height: 8),
                Text('Reserve aux parents', style: t.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Combien font ${_challenge.a} x ${_challenge.b} ?',
                  key: const Key('parental-question'),
                  style: t.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (_wrong)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Ce n\'est pas la bonne reponse.',
                      style: t.bodyLarge?.copyWith(color: AppColors.bitsy),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final c in _challenge.choices)
                      FilledButton(
                        key: Key('parental-choice-$c'),
                        onPressed: () => _answer(c),
                        style: AppTheme.parentButton.copyWith(
                          minimumSize: const WidgetStatePropertyAll(
                            Size(96, 72),
                          ),
                        ),
                        child: Text('$c'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('parental-cancel'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      AppSizes.minTouch,
                      AppSizes.minTouch,
                    ),
                  ),
                  onPressed: () => _finish(false),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
