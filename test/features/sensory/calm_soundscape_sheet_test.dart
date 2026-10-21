import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/sensory/application/sensory_soundscape_service.dart';
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
    patrolWidgetTest('Renders all curated soundscape cards and title', ($) async {
      await $.pumpWidgetAndSettle(buildTestWidget());

      expect($('Calm Sensory Soundscapes'), findsOneWidget);
      expect($('Warm Brown Noise'), findsOneWidget);
      expect($('Gentle Rain on Leaves'), findsOneWidget);
      expect($('Quiet Forest Stream'), findsOneWidget);
      expect($('Calm Ocean Shallows'), findsOneWidget);

      expect($(const Key('soundscape_volume_slider')), findsOneWidget);
      expect($(const Key('toggle_soundscape_playback_button')), findsOneWidget);
    });

    patrolWidgetTest('Tapping soundscape card selects it and starts playback', ($) async {
      final mockPlayer = InMemorySoundscapeAudioPlayer();
      await $.pumpWidgetAndSettle(buildTestWidget(audioPlayer: mockPlayer));

      final rainCard = $(const Key('soundscape_card_gentle_rain'));
      expect(rainCard, findsOneWidget);

      await rainCard.tap();

      expect(mockPlayer.isPlaying, isTrue);
      expect(mockPlayer.currentSoundscape?.id, equals('gentle_rain'));
      expect($('Pause Soundscape'), findsOneWidget);
    });

    patrolWidgetTest('Tapping sleep timer chip configures duration', ($) async {
      await $.pumpWidgetAndSettle(buildTestWidget());

      final chip15 = $(const Key('timer_chip_15'));
      expect(chip15, findsOneWidget);

      await chip15.scrollTo();
      await chip15.tap();

      final chipChoice = $.tester.widget<ChoiceChip>(find.byKey(const Key('timer_chip_15')));
      expect(chipChoice.selected, isTrue);
    });

    patrolWidgetTest('Master play/pause button toggles playback state', ($) async {
      final mockPlayer = InMemorySoundscapeAudioPlayer();
      await $.pumpWidgetAndSettle(buildTestWidget(audioPlayer: mockPlayer));

      final playButton = $(const Key('toggle_soundscape_playback_button'));
      expect($(RegExp('Play Warm Brown Noise')), findsOneWidget);

      await playButton.scrollTo();
      await playButton.tap();

      expect(mockPlayer.isPlaying, isTrue);
      expect($('Pause Soundscape'), findsOneWidget);

      await playButton.tap();

      expect(mockPlayer.isPlaying, isFalse);
      expect($(RegExp('Play Warm Brown Noise')), findsOneWidget);
    });
  });
}
