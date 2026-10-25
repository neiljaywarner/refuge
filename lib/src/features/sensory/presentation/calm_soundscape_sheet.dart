import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/system_insets.dart';
import '../application/sensory_soundscape_service.dart';
import '../domain/sensory_soundscape.dart';

/// Modal bottom sheet providing calm ambient soundscapes and brown noise generator.
class CalmSoundscapeSheet extends HookConsumerWidget {
  const CalmSoundscapeSheet({super.key});

  /// Helper to display this modal bottom sheet with safe padding.
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SystemBottomInset(child: CalmSoundscapeSheet()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundscapeState = ref.watch(sensorySoundscapeNotifierProvider);
    final notifier = ref.read(sensorySoundscapeNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewPadding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(76),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E6B56).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎧', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calm Sensory Soundscapes',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Gentle auditory masking for focus and regulation.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('close_soundscape_sheet_button'),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close soundscapes',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Soundscape Cards
            ...SensorySoundscape.curatedSoundscapes.map((soundscape) {
              final isSelected = soundscapeState.activeSoundscape?.id == soundscape.id;
              final isPlayingThis = isSelected && soundscapeState.isPlaying;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  key: Key('soundscape_card_${soundscape.id}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => notifier.selectSoundscape(soundscape),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E6B56).withAlpha(25)
                          : theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2E6B56) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(soundscape.iconEmoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                soundscape.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF2E6B56) : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                soundscape.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPlayingThis)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.graphic_eq_rounded,
                              color: Color(0xFF2E6B56),
                              size: 20,
                            ),
                          )
                        else if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF2E6B56),
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Controls Divider
            const Divider(),
            const SizedBox(height: 12),

            // Volume Control
            Row(
              children: [
                const Icon(Icons.volume_down_rounded, size: 20),
                Expanded(
                  child: Slider(
                    key: const Key('soundscape_volume_slider'),
                    value: soundscapeState.volume,
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xFF2E6B56),
                    onChanged: (val) => notifier.setVolume(val),
                  ),
                ),
                Text(
                  '${(soundscapeState.volume * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sleep Timer Row
            Text(
              'Sleep / Calm Timer',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('timer_chip_off'),
                  label: const Text('Continuous'),
                  selected: soundscapeState.sleepTimerMinutes == null,
                  onSelected: (selected) {
                    if (selected) notifier.setSleepTimer(null);
                  },
                ),
                ChoiceChip(
                  key: const Key('timer_chip_15'),
                  label: const Text('15 min'),
                  selected: soundscapeState.sleepTimerMinutes == 15,
                  onSelected: (selected) {
                    if (selected) notifier.setSleepTimer(15);
                  },
                ),
                ChoiceChip(
                  key: const Key('timer_chip_30'),
                  label: const Text('30 min'),
                  selected: soundscapeState.sleepTimerMinutes == 30,
                  onSelected: (selected) {
                    if (selected) notifier.setSleepTimer(30);
                  },
                ),
                ChoiceChip(
                  key: const Key('timer_chip_60'),
                  label: const Text('60 min'),
                  selected: soundscapeState.sleepTimerMinutes == 60,
                  onSelected: (selected) {
                    if (selected) notifier.setSleepTimer(60);
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Play / Pause Master Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                key: const Key('toggle_soundscape_playback_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6B56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => notifier.togglePlay(),
                icon: Icon(
                  soundscapeState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  soundscapeState.isPlaying
                      ? 'Pause Soundscape'
                      : 'Play ${soundscapeState.activeSoundscape?.title ?? "Soundscape"}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
