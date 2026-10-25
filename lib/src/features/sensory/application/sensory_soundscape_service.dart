import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/sensory_soundscape.dart';

/// Current playback and timer state of sensory soundscapes.
class SoundscapeState extends Equatable {
  const SoundscapeState({
    this.activeSoundscape,
    this.isPlaying = false,
    this.volume = 0.35,
    this.sleepTimerMinutes,
    this.remainingSeconds,
  });

  /// Currently selected soundscape (null if none selected).
  final SensorySoundscape? activeSoundscape;

  /// Whether audio is actively playing.
  final bool isPlaying;

  /// Output volume clamped between 0.0 and 1.0.
  final double volume;

  /// Selected sleep timer duration in minutes (null if continuous).
  final int? sleepTimerMinutes;

  /// Remaining seconds on the active sleep timer (null if none active).
  final int? remainingSeconds;

  SoundscapeState copyWith({
    SensorySoundscape? activeSoundscape,
    bool? isPlaying,
    double? volume,
    int? sleepTimerMinutes,
    bool clearSleepTimer = false,
    int? remainingSeconds,
    bool clearRemainingSeconds = false,
  }) => SoundscapeState(
    activeSoundscape: activeSoundscape ?? this.activeSoundscape,
    isPlaying: isPlaying ?? this.isPlaying,
    volume: volume ?? this.volume,
    sleepTimerMinutes: clearSleepTimer
        ? null
        : (sleepTimerMinutes ?? this.sleepTimerMinutes),
    remainingSeconds: clearRemainingSeconds
        ? null
        : (remainingSeconds ?? this.remainingSeconds),
  );

  @override
  List<Object?> get props => [
    activeSoundscape,
    isPlaying,
    volume,
    sleepTimerMinutes,
    remainingSeconds,
  ];
}

/// Abstract audio player interface allowing zero-dependency testing and pluggable audio engines.
abstract interface class SoundscapeAudioPlayer {
  Future<void> play(SensorySoundscape soundscape, double volume);
  Future<void> pause();
  Future<void> stop();
  Future<void> setVolume(double volume);
}

/// Lightweight, in-memory audio player for headless testing and offline resilient mock playback.
class InMemorySoundscapeAudioPlayer implements SoundscapeAudioPlayer {
  bool isPlaying = false;
  SensorySoundscape? currentSoundscape;
  double currentVolume = 0.35;

  @override
  Future<void> play(SensorySoundscape soundscape, double volume) async {
    isPlaying = true;
    currentSoundscape = soundscape;
    currentVolume = volume;
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
    currentSoundscape = null;
  }

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
  }
}

/// Provider for the audio player implementation.
final soundscapeAudioPlayerProvider = Provider<SoundscapeAudioPlayer>(
  (ref) => InMemorySoundscapeAudioPlayer(),
);

/// Riverpod StateNotifier controlling sensory soundscape playback and sleep timer.
class SensorySoundscapeNotifier extends StateNotifier<SoundscapeState> {
  SensorySoundscapeNotifier(this._audioPlayer)
    : super(
        SoundscapeState(
          activeSoundscape: SensorySoundscape.curatedSoundscapes.first,
          volume: SensorySoundscape.curatedSoundscapes.first.defaultVolume,
        ),
      );

  final SoundscapeAudioPlayer _audioPlayer;
  Timer? _countdownTimer;

  /// Select a soundscape and begin playing.
  Future<void> selectSoundscape(SensorySoundscape soundscape) async {
    final newVolume = soundscape.defaultVolume;
    await _audioPlayer.play(soundscape, newVolume);
    state = state.copyWith(
      activeSoundscape: soundscape,
      isPlaying: true,
      volume: newVolume,
    );
  }

  /// Toggle play and pause.
  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await _audioPlayer.pause();
      _countdownTimer?.cancel();
      state = state.copyWith(isPlaying: false, clearRemainingSeconds: true);
    } else {
      final target =
          state.activeSoundscape ?? SensorySoundscape.curatedSoundscapes.first;
      await _audioPlayer.play(target, state.volume);
      state = state.copyWith(activeSoundscape: target, isPlaying: true);
      if (state.sleepTimerMinutes != null) {
        _startTimer(state.sleepTimerMinutes!);
      }
    }
  }

  /// Set volume smoothly clamped between 0.0 and 1.0.
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(clamped);
    state = state.copyWith(volume: clamped);
  }

  /// Configure sleep timer in minutes (15, 30, 45, 60 or null to cancel).
  void setSleepTimer(int? minutes) {
    _countdownTimer?.cancel();
    if (minutes == null || minutes <= 0) {
      state = state.copyWith(
        clearSleepTimer: true,
        clearRemainingSeconds: true,
      );
      return;
    }

    state = state.copyWith(
      sleepTimerMinutes: minutes,
      remainingSeconds: minutes * 60,
    );

    if (state.isPlaying) {
      _startTimer(minutes);
    }
  }

  void _startTimer(int minutes) {
    _countdownTimer?.cancel();
    state = state.copyWith(remainingSeconds: minutes * 60);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.remainingSeconds ?? 0;
      if (current <= 1) {
        timer.cancel();
        _audioPlayer.stop();
        state = state.copyWith(
          isPlaying: false,
          clearRemainingSeconds: true,
          clearSleepTimer: true,
        );
      } else {
        state = state.copyWith(remainingSeconds: current - 1);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _audioPlayer.stop();
    super.dispose();
  }
}

/// Provider exposing the soundscape state notifier.
final sensorySoundscapeNotifierProvider =
    StateNotifierProvider<SensorySoundscapeNotifier, SoundscapeState>((ref) {
      final player = ref.watch(soundscapeAudioPlayerProvider);
      return SensorySoundscapeNotifier(player);
    });
