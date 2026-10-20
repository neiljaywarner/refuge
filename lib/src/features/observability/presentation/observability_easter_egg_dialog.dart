import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/firebase/community_analytics_service.dart';
import '../../../core/observability/error_reporter_service.dart';

/// Developer Easter Egg Dialog triggered by tapping the Belong logo/title 7 times.
/// Allows instant end-to-end verification of:
/// 1. Firebase Crashlytics fatal crash reporting
/// 2. Handled non-fatal error (NFE) reporting & Talker diagnostics
/// 3. Google Analytics event emission and DebugView verification
class ObservabilityEasterEggDialog extends ConsumerWidget {
  const ObservabilityEasterEggDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const ObservabilityEasterEggDialog(),
  );

  static const String adbDebugCommand =
      'adb shell setprop debug.firebase.analytics.app com.belongonthespectrum.sanctuary';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(communityAnalyticsServiceProvider);
    final errorReporter = ref.watch(errorReporterServiceProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      key: const Key('observability_easter_egg_dialog'),
      title: const Row(
        children: [
          Text('🐣', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Observability & Diagnostics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Secret developer menu to verify Firebase Analytics, Crashlytics, and Talker logging.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // 1. Force Handled Non-Fatal Error (NFE)
            FilledButton.tonalIcon(
              key: const Key('easter_egg_trigger_nfe_button'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.withValues(alpha: 0.15),
                foregroundColor: Colors.amber.shade900,
              ),
              onPressed: () async {
                await errorReporter.recordError(
                  Exception('Test Handled NFE from 7-Tap Easter Egg'),
                  StackTrace.current,
                  reason: 'Manual 7-Tap Easter Egg Verification',
                  fatal: false,
                  context: {'source': 'easter_egg_dialog', 'test_mode': 'non_fatal'},
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Handled NFE recorded to Crashlytics, Analytics & Talker!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text('Record Handled NFE'),
            ),
            const SizedBox(height: 8),

            // 2. Force Test Analytics Event
            FilledButton.tonalIcon(
              key: const Key('easter_egg_trigger_analytics_button'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.withValues(alpha: 0.15),
                foregroundColor: Colors.blue.shade800,
              ),
              onPressed: () async {
                await analytics.logEvent(
                  'easter_egg_test_event',
                  parameters: {
                    'source': 'easter_egg_dialog',
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📊 Test event logged to Firebase Analytics & DebugView!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('Emit Test Analytics Event'),
            ),
            const SizedBox(height: 8),

            // 3. Force Fatal Crash (Crashlytics)
            FilledButton.icon(
              key: const Key('easter_egg_trigger_fatal_crash_button'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () {
                if (Firebase.apps.isNotEmpty) {
                  FirebaseCrashlytics.instance.crash();
                } else {
                  throw StateError('Simulated Fatal Crash from 7-Tap Easter Egg');
                }
              },
              icon: const Icon(Icons.dangerous_outlined, size: 18),
              label: const Text('Simulate Fatal Crash'),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ADB DebugView Help
            Text(
              'ADB Analytics DebugView Mode:',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                adbDebugCommand,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              key: const Key('easter_egg_copy_adb_button'),
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: adbDebugCommand));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📋 ADB command copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Copy ADB Command', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(height: 8),
            Text(
              'Recent Diagnostic Entries: ${errorReporter.recordedErrorsForTesting.length}',
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('easter_egg_close_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
