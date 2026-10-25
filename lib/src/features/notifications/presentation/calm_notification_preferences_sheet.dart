import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/presentation/system_insets.dart';
import 'package:refuge4serverpod/src/features/notifications/data/calm_local_notification_service.dart';
import 'package:refuge4serverpod/src/features/notifications/data/notification_permissions_service.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/calm_notification_preferences.dart';

/// Modal bottom sheet allowing members to configure unhurried digest schedules.
class CalmNotificationPreferencesSheet extends ConsumerWidget {
  const CalmNotificationPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          const SystemBottomInset(child: CalmNotificationPreferencesSheet()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final prefs = ref.watch(calmNotificationPreferencesProvider);
    final notifier = ref.read(calmNotificationPreferencesProvider.notifier);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Calm Notification Ethics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Belong respects your attention and sensory peace. We never send loud chimes, urgency countdowns, or anxiety-inducing red dots.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.8,
                  ),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // Notification Master Toggle
              SwitchListTile.adaptive(
                key: const ValueKey('toggle-notifications-switch'),
                contentPadding: EdgeInsets.zero,
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

              if (prefs.isSystemPermissionDenied) ...[
                const SizedBox(height: 8),
                Text(
                  'Android blocked alerts. Allow notifications for Belong in system settings, then turn Message alerts on again.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],

              if (prefs.isIosWebWithoutPwa) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📱', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Apple iOS Requirement: Mobile Safari requires adding Belong to your Home Screen (Share ⬆️ -> "Add to Home Screen") before web push notifications can be enabled.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 28),
              Text(
                'Delivery Schedule',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              for (final schedule in CalmDigestSchedule.values)
                RadioListTile<CalmDigestSchedule>(
                  key: ValueKey('schedule-radio-${schedule.name}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    '${schedule.emoji} ${schedule.title}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    schedule.description,
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: schedule,
                  groupValue: prefs.schedule,
                  onChanged: (selected) {
                    if (selected != null) {
                      notifier.setSchedule(selected);
                    }
                  },
                ),

              if (kDebugMode) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    identifier: 'preview-calm-shade-notification-button',
                    label: 'Preview shade notification debug',
                    child: OutlinedButton(
                      key: const ValueKey('preview-calm-shade-notification-button'),
                      onPressed: () async {
                      await showCalmPreviewDirectMessage(
                        ref.read(calmLocalNotificationServiceProvider),
                      );
                    },
                      child: const Text('Preview shade notification (debug)'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('save-notification-preferences-button'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Save & Return'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
