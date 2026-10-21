import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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

  static Future<void> show(BuildContext context) => showDialog(
        context: context,
        builder: (_) => const ObservabilityEasterEggDialog(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final errorReporter = ref.watch(errorReporterServiceProvider);
    final analytics = ref.watch(communityAnalyticsServiceProvider);

    return AlertDialog(
      key: const Key('observability_easter_egg_dialog'),
      title: Row(
        children: [
          const Icon(Icons.bug_report_outlined, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Observability Verification',
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
            const Text(
              'Tap below to verify Firebase Crashlytics and Google Analytics events live on device or emulator.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // 1. Trigger Handled Non-Fatal Error (NFE)
            OutlinedButton.icon(
              key: const Key('easter_egg_trigger_nfe_button'),
              onPressed: () {
                errorReporter.recordError(
                  Exception('Test Handled NFE from 7-Tap Easter Egg'),
                  StackTrace.current,
                  reason: 'Manual 7-Tap Easter Egg Verification',
                  fatal: false,
                  context: {
                    'screen': 'easter_egg_dialog',
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Handled NFE logged to Crashlytics, Analytics & Talker'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text('Trigger Handled NFE'),
            ),
            const SizedBox(height: 8),

            // 2. Trigger Custom Analytics Event
            OutlinedButton.icon(
              key: const Key('easter_egg_trigger_analytics_button'),
              onPressed: () {
                analytics.logEvent(
                  'easter_egg_test_event',
                  parameters: {
                    'trigger_source': '7_tap_header',
                    'time': DateTime.now().toIso8601String(),
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📊 Analytics event "easter_egg_test_event" dispatched'),
                    duration: Duration(seconds: 2),
                  ),
                );
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
                if (Firebase.apps.isNotEmpty && !kIsWeb) {
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
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const SelectableText(
                'adb shell setprop debug.firebase.analytics.app com.belongonthespectrum.sanctuary',
                style: TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recent In-Memory Errors (${errorReporter.recordedErrorsForTesting.length}):',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              errorReporter.recordedErrorsForTesting.isEmpty
                  ? 'No errors recorded in this session.'
                  : errorReporter.recordedErrorsForTesting
                      .map((e) => '• [${e['fatal'] == true ? 'FATAL' : 'HANDLED'}] ${e['reason']}')
                      .join('\n'),
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('easter_egg_close_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
