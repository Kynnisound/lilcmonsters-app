import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/audio/sound_effect.dart';
import 'package:seamonsters/core/config/app_config.dart';
import 'package:seamonsters/core/l10n/strings.dart';
import 'package:seamonsters/core/progress/progress.dart';
import 'package:seamonsters/core/theme/app_tokens.dart';
import 'package:seamonsters/core/widgets/locked_badge.dart';
import 'package:seamonsters/features/beach/beach_screen.dart';
import 'package:seamonsters/features/lighthouse/lighthouse_screen.dart';
import 'package:seamonsters/features/map/island_map_screen.dart';
import 'package:seamonsters/features/map/island_place.dart';
import 'package:seamonsters/features/parents/parents_screen.dart';
import 'package:seamonsters/features/puzzle/puzzle_screen.dart';
import 'package:seamonsters/features/shadows/shadows_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('la carte affiche les 7 lieux, cibles de 120 a 140 dp', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(IslandMapScreen), findsOneWidget);
    for (final p in IslandPlace.values) {
      final size = tester.getSize(find.byKey(Key('place-${p.name}')));
      expect(
        size.width,
        inInclusiveRange(AppSizes.mapSpotMin, AppSizes.mapSpotMax),
      );
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(p.label))),
        findsWidgets,
      );
    }
    // Puzzle et ombres verrouilles au depart.
    expect(find.byType(PadlockBadge), findsNWidgets(2));
  });

  testWidgets('cibles tactiles conformes (guideline Android 48 dp)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('un ilot verrouille oscille et reste sur la carte', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('place-puzzle')));
    await settle(tester);
    expect(find.byType(PuzzleScreen), findsNothing);
    expect(h.audio.played, contains(SoundEffect.boing));
  });

  testWidgets('bac a sable : les sons jouent et 3 sons ouvrent le puzzle', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('place-beach')));
    await settle(tester);
    expect(find.byType(BeachScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('pad-fuzzle')));
    await tester.tap(find.byKey(const Key('pad-wave')));
    await tester.tap(find.byKey(const Key('pad-star')));
    await settle(tester);
    expect(
      h.audio.played,
      containsAll([SoundEffect.noteDo, SoundEffect.wave, SoundEffect.chime]),
    );
    expect(h.container.read(progressProvider).puzzleUnlocked, isTrue);

    await tester.tap(find.byKey(const Key('home-button')));
    await settle(tester);
    expect(find.byType(IslandMapScreen), findsOneWidget);
    expect(find.byType(PadlockBadge), findsOneWidget);
  });

  testWidgets('puzzle 2 x 2 jouable au toucher, puis ombres debloquees', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      config: const AppConfig(unlockAllIslets: false),
    );
    for (var i = 0; i < 3; i++) {
      h.container.read(progressProvider.notifier).beachSoundPlayed();
    }
    await settle(tester, 2);
    await tester.tap(find.byKey(const Key('place-puzzle')));
    await settle(tester);
    expect(find.byType(PuzzleScreen), findsOneWidget);

    for (var piece = 0; piece < 4; piece++) {
      await tester.tap(find.byKey(Key('tray-$piece')));
      await tester.pump();
      await tester.tap(find.byKey(Key('slot-$piece')));
      await tester.pump();
    }
    await settle(tester, 20);
    expect(h.audio.played, contains(SoundEffect.success));
    expect(find.byKey(const Key('puzzle-next')), findsOneWidget);
    expect(h.container.read(progressProvider).shadowsUnlocked, isTrue);
  });

  testWidgets("jeu d'ombres : toucher la bonne ombre reussit", (tester) async {
    final h = await pumpApp(
      tester,
      config: const AppConfig(unlockAllIslets: true),
    );
    await tester.tap(find.byKey(const Key('place-shadows')));
    await settle(tester);
    expect(find.byType(ShadowsScreen), findsOneWidget);

    final target = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('shadow-target-'),
    );
    final name = (tester.widget(target).key as ValueKey<String>).value
        .replaceFirst('shadow-target-', '');
    await tester.tap(find.byKey(Key('shadow-$name')));
    await settle(tester, 20);
    expect(h.audio.played, contains(SoundEffect.success));
  });

  testWidgets('phare : porte parentale, mauvaise reponse refusee', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('place-lighthouse')));
    await settle(tester);
    expect(find.byKey(const Key('parental-question')), findsOneWidget);

    await tester.tap(find.byKey(const Key('parental-choice-11')));
    await settle(tester);
    expect(find.byType(LighthouseScreen), findsNothing);

    await tester.tap(find.byKey(const Key('parental-choice-12')));
    await settle(tester);
    expect(find.byType(LighthouseScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-channel')));
    await settle(tester);
    expect(h.links.opened.single.toString(), AppConfig.youtubeChannelUrl);
  });

  testWidgets(
    'grotte : contenu du pass verrouille puis ouvert par achat simule',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('place-cave')));
      await settle(tester);
      expect(find.byType(CrownBadge), findsWidgets);
      expect(find.byKey(const Key('coloring-0')), findsNothing);

      // Toucher un contenu verrouille ouvre la porte parentale puis l'espace parents.
      await tester.tap(find.bySemanticsLabel(S.premium).first);
      await settle(tester);
      await tester.tap(find.byKey(const Key('parental-choice-12')));
      await settle(tester);
      expect(find.byType(ParentsScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('fake-purchase')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('parents-close')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('place-cave')));
      await settle(tester);
      expect(find.byKey(const Key('coloring-0')), findsOneWidget);
    },
  );

  testWidgets('PREMIUM_UNLOCKED ouvre la bibliotheque', (tester) async {
    await pumpApp(tester, config: const AppConfig(premiumUnlocked: true));
    await tester.tap(find.byKey(const Key('place-library')));
    await settle(tester);
    expect(find.byKey(const Key('book-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('book-0')));
    await settle(tester);
    expect(find.byKey(const Key('book-play')), findsOneWidget);
  });
}
