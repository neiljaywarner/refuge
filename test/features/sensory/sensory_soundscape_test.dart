import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/sensory/application/sensory_soundscape_service.dart';
import 'package:refuge4serverpod/src/features/sensory/domain/sensory_soundscape.dart';

void main() {
  group('SensorySoundscape Domain Tests', () {
    test('Curated soundscapes list contains essential calm textures', () {
      final soundscapes = SensorySoundscape.curatedSoundscapes;
      expect(soundscapes.length, greaterThanOrEqualTo(4));

      final ids = soundscapes.map((s) => s.id).toList();
      expect(ids, contains('brown_noise'));
      expect(ids, contains('gentle_rain'));
      expect(ids, contains('forest_stream'));
      expect(ids, contains('ocean_shallows'));
    });

    test('SensorySoundscape props supports value equality', () {
      const a = SensorySoundscape(
        id: 'test_sound',
        title: 'Test Sound',
        description: 'Test description',
        iconEmoji: '🎵',
        category: SoundscapeCategory.ambient,
      );
      const b = SensorySoundscape(
        id: 'test_sound',
        title: 'Test Sound',
        description: 'Test description',
        iconEmoji: '🎵',
        category: SoundscapeCategory.ambient,
      );

      expect(a, equals(b));
    });
  });

  group('SensorySoundscapeNotifier Tests', () {
    late InMemorySoundscapeAudioPlayer mockPlayer;
    late SensorySoundscapeNotifier notifier;

    setUp(() {
      mockPlayer = InMemorySoundscapeAudioPlayer();
      notifier = SensorySoundscapeNotifier(mockPlayer);
    });

    tearDown(() {
      notifier.dispose();
    });

    test(
      'Initial state is not playing and has default soundscape selected',
      () {
        expect(notifier.state.isPlaying, isFalse);
        expect(notifier.state.activeSoundscape, isNotNull);
        expect(notifier.state.volume, greaterThan(0.0));
      },
    );

    test('togglePlay plays and pauses audio', () async {
      await notifier.togglePlay();
      expect(notifier.state.isPlaying, isTrue);
      expect(mockPlayer.isPlaying, isTrue);

      await notifier.togglePlay();
      expect(notifier.state.isPlaying, isFalse);
      expect(mockPlayer.isPlaying, isFalse);
    });

    test('selectSoundscape switches active soundscape and plays', () async {
      final rain = SensorySoundscape.curatedSoundscapes.firstWhere(
        (s) => s.id == 'gentle_rain',
      );
      await notifier.selectSoundscape(rain);

      expect(notifier.state.activeSoundscape, equals(rain));
      expect(notifier.state.isPlaying, isTrue);
      expect(mockPlayer.currentSoundscape, equals(rain));
    });

    test('setVolume clamps between 0.0 and 1.0', () async {
      await notifier.setVolume(1.5);
      expect(notifier.state.volume, equals(1.0));
      expect(mockPlayer.currentVolume, equals(1.0));

      await notifier.setVolume(-0.2);
      expect(notifier.state.volume, equals(0.0));
      expect(mockPlayer.currentVolume, equals(0.0));

      await notifier.setVolume(0.45);
      expect(notifier.state.volume, equals(0.45));
      expect(mockPlayer.currentVolume, equals(0.45));
    });

    test('setSleepTimer updates sleepTimerMinutes and countdown', () {
      notifier.setSleepTimer(15);
      expect(notifier.state.sleepTimerMinutes, equals(15));
      expect(notifier.state.remainingSeconds, equals(900));

      notifier.setSleepTimer(null);
      expect(notifier.state.sleepTimerMinutes, isNull);
      expect(notifier.state.remainingSeconds, isNull);
    });
  });
}
