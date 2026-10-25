import 'package:equatable/equatable.dart';

/// Categories of soothing soundscapes designed for autistic and ADHD sensory regulation.
enum SoundscapeCategory {
  /// Natural auditory environments (rain, wind, streams).
  nature,

  /// Spectral noise (brown noise, pink noise) masking erratic environmental sounds.
  noise,

  /// Ambient tonal drones and gentle harmonics.
  ambient,
}

/// A sensory soundscape designed to assist members in sensory de-escalation and calm focus.
class SensorySoundscape extends Equatable {
  const SensorySoundscape({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.category,
    this.defaultVolume = 0.35,
    this.audioAssetUri,
  });

  /// Unique identifier (e.g. 'brown_noise').
  final String id;

  /// Human-friendly display title.
  final String title;

  /// Short sensory description explaining the auditory texture.
  final String description;

  /// Visual icon emoji for quick recognition without reading burden.
  final String iconEmoji;

  /// Category of the soundscape.
  final SoundscapeCategory category;

  /// Recommended soft starting volume (0.0 to 1.0) to prevent startle responses.
  final double defaultVolume;

  /// Optional relative asset path or URI for when audio assets are bundled.
  final String? audioAssetUri;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    iconEmoji,
    category,
    defaultVolume,
    audioAssetUri,
  ];

  /// Default curated calm soundscapes for Belong on the Spectrum.
  static const List<SensorySoundscape> curatedSoundscapes = [
    SensorySoundscape(
      id: 'brown_noise',
      title: 'Warm Brown Noise',
      description:
          'Deep, low-frequency soundscape masking unpredictable room noise.',
      iconEmoji: '☕',
      category: SoundscapeCategory.noise,
      defaultVolume: 0.35,
    ),
    SensorySoundscape(
      id: 'gentle_rain',
      title: 'Gentle Rain on Leaves',
      description:
          'Soft, steady rainfall texture with low motion and no thunder.',
      iconEmoji: '🌧️',
      category: SoundscapeCategory.nature,
      defaultVolume: 0.30,
    ),
    SensorySoundscape(
      id: 'forest_stream',
      title: 'Quiet Forest Stream',
      description: 'Rhythmic babbling water with gentle, unhurried flow.',
      iconEmoji: '🌲',
      category: SoundscapeCategory.nature,
      defaultVolume: 0.30,
    ),
    SensorySoundscape(
      id: 'ocean_shallows',
      title: 'Calm Ocean Shallows',
      description: 'Periodic, slow-rolling small waves for rhythmic breathing.',
      iconEmoji: '🌊',
      category: SoundscapeCategory.nature,
      defaultVolume: 0.25,
    ),
  ];
}
