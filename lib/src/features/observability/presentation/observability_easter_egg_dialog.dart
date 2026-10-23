import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/firebase/community_analytics_service.dart';
import '../../../core/firebase/firebase_installations_service.dart';
import '../../../core/firebase/in_app_messaging/in_app_messaging_service.dart';
import '../../../core/observability/diagnostic_log_service.dart';
import '../../../core/observability/error_reporter_service.dart';

/// Developer Easter Egg Dialog triggered by tapping the Belong logo/title 7 times.
/// Allows instant end-to-end verification of:
/// 1. Firebase Installation ID (FID) inspection & copying for device troubleshooting
/// 2. Firebase In-App Messaging (FIAM) event trigger with web graceful fallback
/// 3. Diagnostic Session Replay & "Send Logs" to Cloud Storage (Production Safe)
/// 4. Firebase Crashlytics fatal crash reporting
/// 5. Handled non-fatal error (NFE) reporting & Talker diagnostics
/// 6. Google Analytics event emission and DebugView verification
class ObservabilityEasterEggDialog extends ConsumerStatefulWidget {
  const ObservabilityEasterEggDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog(
        context: context,
        builder: (_) => const ObservabilityEasterEggDialog(),
      );

  @override
  ConsumerState<ObservabilityEasterEggDialog> createState() =>
      _ObservabilityEasterEggDialogState();
}

class _ObservabilityEasterEggDialogState
    extends ConsumerState<ObservabilityEasterEggDialog> {
  bool _isUploadingLogs = false;
  String? _uploadedLogUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorReporter = ref.watch(errorReporterServiceProvider);
    final analytics = ref.watch(communityAnalyticsServiceProvider);
    final installationsAsync = ref.watch(firebaseInstallationsIdProvider);
    final fiam = ref.watch(inAppMessagingServiceProvider);
    final diagnosticLogService = ref.watch(diagnosticLogServiceProvider);

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
              'Tap below to verify Firebase services, copy device Installation ID, trigger In-App Messaging, or export session diagnostic logs.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 1. Firebase Installation ID (FID) Card
            // -----------------------------------------------------------------
            Text(
              'Firebase Installation ID (Troubleshooting):',
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.5),
                ),
              ),
              child: installationsAsync.when(
                data: (fid) => Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        fid,
                        key: const Key('easter_egg_installations_id_text'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('easter_egg_copy_fid_button'),
                      icon: const Icon(Icons.copy, size: 16),
                      tooltip: 'Copy Installation ID',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '📋 Firebase Installation ID copied to clipboard',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Fetching Installation ID...',
                          style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                error: (err, _) => SelectableText(
                  'Error: $err',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Unique device identifier for In-App Messaging & Remote Config troubleshooting without personal accounts.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 2. Firebase In-App Messaging (FIAM) Trigger
            // -----------------------------------------------------------------
            OutlinedButton.icon(
              key: const Key('easter_egg_trigger_fiam_button'),
              onPressed: () async {
                await fiam.triggerEvent('easter_egg_prompt');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        fiam.isSupported
                            ? '💬 FIAM event "easter_egg_prompt" triggered'
                            : '🌐 FIAM web/stub no-op (platform not supported by FlutterFire)',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: Icon(
                fiam.isSupported
                    ? Icons.chat_bubble_outline
                    : Icons.chat_bubble_outline_rounded,
                size: 18,
              ),
              label: Text(
                fiam.isSupported
                    ? 'Trigger In-App Message'
                    : 'Trigger In-App Message (Web Stub)',
              ),
            ),
            const SizedBox(height: 8),

            // -----------------------------------------------------------------
            // 3. Diagnostic Session Replay & "Send Logs"
            // -----------------------------------------------------------------
            FilledButton.tonalIcon(
              key: const Key('easter_egg_send_logs_button'),
              onPressed: _isUploadingLogs
                  ? null
                  : () async {
                      setState(() => _isUploadingLogs = true);
                      try {
                        final url = await diagnosticLogService
                            .sendLogsToCloudStorage();
                        if (mounted) {
                          setState(() {
                            _isUploadingLogs = false;
                            _uploadedLogUrl = url;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📦 Logs sent to Cloud Storage!'),
                              action: SnackBarAction(
                                label: 'Copy Link',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: url),
                                  );
                                },
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isUploadingLogs = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('⚠️ Failed to send logs: $e'),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
              icon: _isUploadingLogs
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(
                _isUploadingLogs
                    ? 'Uploading Diagnostic Logs...'
                    : 'Send Logs to Cloud Storage',
              ),
            ),
            if (_uploadedLogUrl != null) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _uploadedLogUrl!,
                        key: const Key('easter_egg_uploaded_log_url'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('easter_egg_copy_log_link_button'),
                      icon: const Icon(Icons.copy, size: 14),
                      tooltip: 'Copy Log URL',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _uploadedLogUrl!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📋 Log URL copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            // View Session Replay Summary
            OutlinedButton.icon(
              key: const Key('easter_egg_view_replay_button'),
              onPressed: () async {
                final replay =
                    await diagnosticLogService.generateReplayBundle();
                if (context.mounted) {
                  _showSessionReplaySheet(context, replay);
                }
              },
              icon: const Icon(Icons.replay_outlined, size: 18),
              label: const Text('View Session Replay & Breadcrumbs'),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // -----------------------------------------------------------------
            // 4. Handled Non-Fatal Error (NFE)
            // -----------------------------------------------------------------
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
                    content: Text(
                      '✅ Handled NFE logged to Crashlytics, Analytics & Talker',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text('Trigger Handled NFE'),
            ),
            const SizedBox(height: 8),

            // -----------------------------------------------------------------
            // 5. Custom Analytics Event
            // -----------------------------------------------------------------
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
                    content: Text(
                      '📊 Analytics event "easter_egg_test_event" dispatched',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('Emit Test Analytics Event'),
            ),
            const SizedBox(height: 8),

            // -----------------------------------------------------------------
            // 6. Force Fatal Crash (Crashlytics)
            // -----------------------------------------------------------------
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
                  throw StateError(
                    'Simulated Fatal Crash from 7-Tap Easter Egg',
                  );
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
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      'adb shell setprop debug.firebase.analytics.app com.belongonthespectrum.refuge',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                  IconButton(
                    key: const Key('easter_egg_copy_adb_button'),
                    icon: const Icon(Icons.copy, size: 14),
                    tooltip: 'Copy ADB command',
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text:
                              'adb shell setprop debug.firebase.analytics.app com.belongonthespectrum.refuge',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('📋 ADB command copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recent In-Memory Errors (${errorReporter.recordedErrorsForTesting.length}):',
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              errorReporter.recordedErrorsForTesting.isEmpty
                  ? 'No errors recorded in this session.'
                  : errorReporter.recordedErrorsForTesting
                      .map((e) =>
                          '• [${e['fatal'] == true ? 'FATAL' : 'HANDLED'}] ${e['reason']}')
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

  void _showSessionReplaySheet(
    BuildContext context,
    DiagnosticSessionReplay replay,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.replay_circle_filled_outlined,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Diagnostic Session Replay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('easter_egg_copy_full_replay_button'),
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy Session Replay',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: replay.toFormattedText()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '📋 Session replay copied to clipboard',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    replay.toFormattedText(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}