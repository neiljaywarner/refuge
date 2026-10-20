import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/sensory/application/sensory_soundscape_service.dart';
import 'package:refuge4serverpod/src/features/sensory/domain/sensory_soundscape.dart';
import 'package:refuge4serverpod/src/features/sensory/presentation/calm_soundscape_sheet.dart';

void main() {
  Widget buildTestWidget({SoundscapeAudioPlayer? audioPlayer}) {
    return ProviderScope(
      overrides: [
        if (audioPlayer != null)
          soundscapeAudioPlayerProvider.overrideWithValue(audioPlayer),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: CalmSoundscapeSheet(),
        ),
      ),
    );
  }

  group('CalmSoundscapeSheet Widget Tests', () {
    testWidgets('Renders all curated soundscape cards and title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Calm Sensory Soundscapes'), findsOneWidget);
      expect(find.text('Warm Brown Noise'), findsOneWidget);
      expect(find.text('Gentle Rain on Leaves'), findsOneWidget);
      expect(find.text('Quiet Forest Stream'), findsOneWidget);
      expect(find.text('Calm Ocean Shallows'), findsOneWidget);

      expect(find.byKey(const Key('soundscape_volume_slider')), findsOneWidget);
      expect(find.byKey(const Key('toggle_soundscape_playback_button')), findsOneWidget);
    });

    testWidgets('Tapping soundscape card selects it and starts playback', (tester) async {
      final mockPlayer = InMemorySoundscapeAudioPlayer();
      await tester.pumpWidget(buildTestWidget(audioPlayer: mockPlayer));
      await tester.pumpAndSettle();

      final rainCard = find.byKey(const Key('soundscape_card_gentle_rain'));
      expect(rainCard, findsOneWidget);

      await tester.tap(rainCard);
      await tester.pumpAndSettle();

      expect(mockPlayer.isPlaying, isTrue);
      expect(mockPlayer.currentSoundscape?.id, equals('gentle_rain'));
      expect(find.text('Pause Soundscape'), findsOneWidget);
    });

    testWidgets('Tapping sleep timer chip configures duration', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final chip15 = find.byKey(const Key('timer_chip_15'));
      expect(chip15, findsOneWidget);

      await tester.ensureVisible(chip15);
      await tester.pumpAndSettle();

      await tester.tap(chip15);
      await tester.pumpAndSettle();

      final chipChoice = tester.widget<ChoiceChip>(chip15);
      expect(chipChoice.selected, isTrue);
    });

    testWidgets('Master play/pause button toggles playback state', (tester) async {
      final mockPlayer = InMemorySoundscapeAudioPlayer();
      await tester.pumpWidget(buildTestWidget(audioPlayer: mockPlayer));
      await tester.pumpAndSettle();

      final playButton = find.byKey(const Key('toggle_soundscape_playback_button'));
      expect(find.textContaining('Play Warm Brown Noise'), findsOneWidget);

      await tester.ensureVisible(playButton);
      await tester.pumpAndSettle();

      await tester.tap(playButton);
      await tester.pumpAndSettle();

      expect(mockPlayer.isPlaying, isTrue);
      expect(find.text('Pause Soundscape'), findsOneWidget);

      await tester.tap(playButton);
      await tester.pumpAndSettle();

      expect(mockPlayer.isPlaying, isFalse);
      expect(find.textContaining('Play Warm Brown Noise'), findsOneWidget);
    });
  });
}
