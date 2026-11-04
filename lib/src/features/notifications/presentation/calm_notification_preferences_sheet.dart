import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/theme/belong_colors.dart';
import 'package:refuge4serverpod/src/features/notifications/data/notification_permissions_service.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/calm_notification_preferences.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notification_settings_help.dart';

/// Modal bottom sheet providing calm, non-nagging notification controls.
class CalmNotificationPreferencesSheet extends ConsumerWidget {
  const CalmNotificationPreferencesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(calmNotificationPreferencesProvider);
    final notifier = ref.read(calmNotificationPreferencesProvider.notifier);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with subtle indicator pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Calm Notification Ethics',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'No red guilt dots. No streak alarms. Zero surprise audio startles. '
                'Choose how and when updates reach you.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Master Push Toggle
              SwitchListTile.adaptive(
                key: const ValueKey('toggle-notifications-switch'),
                contentPadding: .zero,
                title: const Text(
                  'Message alerts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  prefs.enabled
                      ? 'On. A new direct message shows as a notification, with sound, even when Belong is closed.'
                      : 'Off. You will not be notified when someone messages you.',
                  style: const TextStyle(fontSize: 12),
                ),
                value: prefs.enabled,
                onChanged: (val) => notifier.setEnabled(val),
              ),
              Text(
                'Sign in on this phone so the notification can find you. A sample member never gets one. Immediate Gentle Cards stays quiet.',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                notificationSettingsHelp(defaultTargetPlatform),
                key: const ValueKey('notification-settings-help'),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.4),
              ),

              if (prefs.isSystemPermissionDenied) ...[
                const SizedBox(height: 8),
                Text(
                  'Android blocked alerts. Allow notifications for Belong in system settings, then turn Message alerts on again.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: theme.colorScheme.error),
                ),
              ],

              if (prefs.isWebPushUnavailable) ...[
                const SizedBox(height: 8),
                Text(
                  'Web push alerts are unavailable in this browser environment. You can install Belong as a PWA or use the mobile app.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: theme.colorScheme.error),
                ),
              ],

              if (prefs.isIosWebWithoutPwa) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const .all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: .circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: .start,
                    children: [
                      const Text('📱', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Apple iOS Requirement: Mobile Safari requires adding Belong to your Home Screen (Share ⬆️ -> "Add to Home Screen") before web push notifications can be enabled.',
                          style: TextStyle(fontSize: 11, height: 1.4, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 24),

              // Batched Delivery Schedules
              Text(
                'Batched Delivery Windows',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...CalmDigestSchedule.values.map((schedule) {
                final isSelected = prefs.schedule == schedule;
                return RadioListTile<CalmDigestSchedule>(
                  key: ValueKey('schedule-radio-${schedule.name}'),
                  contentPadding: .zero,
                  value: schedule,
                  groupValue: prefs.schedule,
                  onChanged: (val) {
                    if (val != null) notifier.setSchedule(val);
                  },
                  title: Row(
                    children: [
                      Text(schedule.emoji),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schedule.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    schedule.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Close / Save Action Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  key: const ValueKey('save-notification-preferences-button'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: BelongColors.sageGreen.withValues(alpha: 0.18),
                    foregroundColor: BelongColors.sageGreenDarker,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save & Return', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
