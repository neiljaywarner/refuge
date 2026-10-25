import 'dart:io';

import 'package:args/args.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/observability/serverpod_telemetry_backup.dart';

/// CLI tool to review and inspect dual-observability telemetry across
/// Firebase Crashlytics, Firebase Analytics, and Serverpod Backup Ring Buffers.
///
/// Usage:
///   dart run tool/review_telemetry.dart [--flavor dev|prod] [--simulate-error] [--simulate-event]
void main(List<String> rawArgs) async {
  final parser = ArgParser()
    ..addOption(
      'flavor',
      abbr: 'f',
      defaultsTo: 'dev',
      help: 'Target app flavor (dev or prod)',
    )
    ..addFlag(
      'simulate-error',
      abbr: 'e',
      defaultsTo: false,
      help: 'Simulate a handled error & fatal crash',
    )
    ..addFlag(
      'simulate-event',
      abbr: 's',
      defaultsTo: false,
      help: 'Simulate key community user journey analytics',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display usage instructions',
    );

  final results = parser.parse(rawArgs);

  if (results['help'] as bool) {
    stdout.writeln(
      '📡 Belong on the Spectrum — Telemetry & Observability Review CLI',
    );
    stdout.writeln(parser.usage);
    exit(0);
  }

  final flavorName = results['flavor'] as String;
  final flavor = flavorName == 'prod' ? AppFlavor.prod : AppFlavor.dev;
  final backup = ServerpodTelemetryBackup(flavor: flavor);

  stdout.writeln(
    '================================================================',
  );
  stdout.writeln('📡 Belong on the Spectrum: Observability & Telemetry Audit');
  stdout.writeln('   Active Flavor: ${flavor.slug.toUpperCase()}');
  stdout.writeln('   Firebase Project: belongonthespectrum (US Central)');
  stdout.writeln(
    '   Serverpod Cluster: https://refuge4serverpod.api.serverpod.space/',
  );
  stdout.writeln(
    '================================================================\n',
  );

  final shouldSimulateError = results['simulate-error'] as bool;
  final shouldSimulateEvent = results['simulate-event'] as bool;

  if (shouldSimulateEvent || (!shouldSimulateError && !shouldSimulateEvent)) {
    stdout.writeln(
      '1. Recording Simulated User Journeys (Conversion Funnels):',
    );
    await backup.recordAnalyticsEvent(
      'space_viewed',
      parameters: {'space_slug': 'memes'},
    );
    await backup.recordAnalyticsEvent(
      'sensory_theme_changed',
      parameters: {'mode': 'sage'},
    );
    await backup.recordAnalyticsEvent(
      'vote_cast',
      parameters: {'feature_id': 'soundscapes'},
    );
    stdout.writeln(
      '   ✅ Successfully logged 3 sample analytics events into Serverpod buffer.\n',
    );
  }

  if (shouldSimulateError) {
    stdout.writeln('2. Recording Simulated Exception & Fatal Crash:');
    await backup.recordErrorReport(
      Exception('Simulated Handled Exception for CLI Audit'),
      StackTrace.current,
      reason: 'Manual CLI Verification',
      fatal: false,
    );
    await backup.recordErrorReport(
      StateError('Simulated Fatal State Crash'),
      StackTrace.current,
      reason: 'Crashlytics Fatal Test',
      fatal: true,
    );
    stdout.writeln(
      '   ✅ Successfully logged handled exception & fatal crash into Serverpod buffer.\n',
    );
  }

  stdout.writeln('3. Current Serverpod Backup Ring Buffer:');
  for (final record in backup.recentRecords) {
    final icon = record.kind == TelemetryKind.error
        ? (record.isFatal ? '🚨' : '⚠️')
        : '📊';
    stdout.writeln(
      '   $icon [${record.timestamp.toIso8601String()}] ${record.name} (${record.kind.name})',
    );
    stdout.writeln('      Parameters: ${record.parameters}');
    if (record.stackTraceSnippet != null) {
      stdout.writeln('      Stack: ${record.stackTraceSnippet}');
    }
  }

  stdout.writeln(
    '\n================================================================',
  );
  stdout.writeln('🔍 How to Review Production Telemetry Channels:');
  stdout.writeln('   • Firebase Analytics:');
  stdout.writeln(
    '     https://console.firebase.google.com/project/belongonthespectrum/analytics/app/events',
  );
  stdout.writeln('   • Firebase Crashlytics:');
  stdout.writeln(
    '     https://console.firebase.google.com/project/belongonthespectrum/crashlytics',
  );
  stdout.writeln('   • Serverpod Live Logs:');
  stdout.writeln('     Run: serverpod logs --project refuge4serverpod');
  stdout.writeln('   • On-Device 7-Tap Easter Egg:');
  stdout.writeln(
    '     Rapidly tap the Belong logo 7 times in the header to trigger test crashes & NFEs!',
  );
  stdout.writeln(
    '================================================================',
  );
}
