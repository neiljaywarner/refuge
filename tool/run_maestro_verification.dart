import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

class ExitCodes {
  static const int success = 0;
  static const int usage = 64;
  static const int software = 70;
}

/// Flows tagged with this stay in the repo but are left out of the default
/// suite and out of `maestro test` on a directory (see `.maestro/config.yaml`).
const maestroDefaultSuiteExcludedTag = 'known-gap';

/// True when the Maestro flow header asks the default/CI suite to skip it.
bool excludesFromDefaultSuite(String yamlContents) {
  final divider = yamlContents.indexOf('\n---');
  final header = divider < 0
      ? yamlContents
      : yamlContents.substring(0, divider);
  return RegExp(
    '^\\s*-\\s+$maestroDefaultSuiteExcludedTag\\s*\$',
    multiLine: true,
  ).hasMatch(header);
}

class MaestroVerificationRunner {
  final ArgParser argParser;
  final ProcessExecutor executor;
  final IOSink outSink;
  final IOSink errSink;

  MaestroVerificationRunner({
    ProcessExecutor? executor,
    IOSink? outSink,
    IOSink? errSink,
  }) : executor = executor ?? const RealProcessExecutor(),
       outSink = outSink ?? stdout,
       errSink = errSink ?? stderr,
       argParser = ArgParser() {
    argParser
      ..addOption(
        'device',
        abbr: 'd',
        help: 'Target Android device or emulator ID for Maestro.',
      )
      ..addOption(
        'flow',
        abbr: 'f',
        help: 'Specific Maestro flow YAML to execute. If omitted, runs all standard flows.',
      )
      ..addFlag(
        'list',
        abbr: 'l',
        defaultsTo: false,
        negatable: false,
        help: 'Lists all available Maestro YAML flows in .maestro/.',
      )
      ..addFlag(
        'dry-run',
        defaultsTo: false,
        negatable: false,
        help: 'Discovers target device and flows without running them.',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        defaultsTo: false,
        negatable: false,
        help: 'Displays usage help.',
      );
  }

  static List<String> parseConnectedDevices(String adbOutput) {
    final devices = <String>[];
    for (final line in LineSplitter.split(adbOutput)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('List of devices')) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1] == 'device') {
        devices.add(parts[0]);
      }
    }
    return devices;
  }

  Future<int> run(List<String> args) async {
    ArgResults results;
    try {
      results = argParser.parse(args);
    } on FormatException catch (e) {
      errSink.writeln('Error: ${e.message}');
      errSink.writeln(argParser.usage);
      return ExitCodes.usage;
    }

    if (results['help'] == true) {
      outSink.writeln(
        '=== Belong on the Spectrum — Maestro End-to-End Test Suite ===',
      );
      outSink.writeln(argParser.usage);
      return ExitCodes.success;
    }

    // Discover available flows
    final maestroDir = Directory('.maestro');
    final availableFlows = <String>[];
    if (await maestroDir.exists()) {
      await for (final entity in maestroDir.list()) {
        if (entity is! File || !entity.path.endsWith('.yaml')) continue;
        // Workspace policy, not a flow. Maestro reads this name itself.
        if (entity.uri.pathSegments.last == 'config.yaml') continue;
        availableFlows.add(entity.path);
      }
      availableFlows.sort();
    }

    if (results['list'] == true) {
      outSink.writeln('📋 Available Maestro flows in .maestro/:');
      if (availableFlows.isEmpty) {
        outSink.writeln('   (No .yaml flows found in .maestro/)');
      } else {
        for (final flow in availableFlows) {
          outSink.writeln('   - $flow');
        }
      }
      return ExitCodes.success;
    }

    outSink.writeln(
      '=== Belong on the Spectrum — Maestro End-to-End Test Suite ===',
    );

    // Check Maestro binary
    final maestroCheck = await executor.run(['which', 'maestro']);
    if (maestroCheck.exitCode != 0) {
      outSink.writeln('⚠️ Maestro CLI is not currently in PATH.');
      outSink.writeln(
        '👉 Install with: curl -fsSL https://get.maestro.mobile.dev | bash',
      );
      outSink.writeln('👉 Then run: export PATH="\$PATH:\$HOME/.maestro/bin"');
      return ExitCodes.success;
    }

    // Detect device
    String? device = results['device'] as String?;
    if (device == null || device.isEmpty) {
      device = Platform.environment['ADB_DEVICE'];
    }
    if (device == null || device.isEmpty) {
      ProcessExecutionResult adbOutput;
      try {
        adbOutput = await executor.run(['adb', 'devices']);
      } on ProcessException {
        outSink.writeln(
          '⚠️ No connected Android device or emulator detected for Maestro.',
        );
        return ExitCodes.success;
      }
      final devices = parseConnectedDevices(adbOutput.stdout);
      if (devices.isEmpty) {
        outSink.writeln(
          '⚠️ No connected Android device or emulator detected for Maestro.',
        );
        return ExitCodes.success;
      }
      device = devices.first;
    }

    outSink.writeln('📍 Detected Target Device: $device');

    // Determine flows to run
    final flowsToRun = <String>[];
    final requestedFlow = results['flow'] as String?;
    if (requestedFlow != null && requestedFlow.isNotEmpty) {
      flowsToRun.add(requestedFlow);
    } else {
      const defaultFlows = [
        '.maestro/belong_full_journey.yaml',
        '.maestro/belong_auth_journey.yaml',
      ];
      for (final flow in defaultFlows) {
        if (!availableFlows.contains(flow) && !await File(flow).exists()) {
          continue;
        }
        if (await _flowExcludedFromDefaultSuite(flow)) continue;
        flowsToRun.add(flow);
      }
      if (flowsToRun.isEmpty && availableFlows.isNotEmpty) {
        for (final flow in availableFlows) {
          if (await _flowExcludedFromDefaultSuite(flow)) continue;
          flowsToRun.add(flow);
        }
      }
    }

    if (results['dry-run'] == true) {
      outSink.writeln(
        '🔍 [DRY RUN] Would execute the following flows on $device:',
      );
      for (final flow in flowsToRun) {
        outSink.writeln('   ▶️ $flow');
      }
      outSink.writeln('✅ Dry run completed.');
      return ExitCodes.success;
    }

    if (flowsToRun.isEmpty) {
      outSink.writeln('ℹ️ No Maestro flows found to execute.');
      return ExitCodes.success;
    }

    outSink.writeln('🚀 Running Maestro Journey on Device: $device');
    var anyFailures = false;

    for (final flow in flowsToRun) {
      final command = ['maestro', '--device', device, 'test', '--env', 'AUTOMATION_TOOL=maestro'];
      if (requestedFlow == null || requestedFlow.isEmpty) {
        command.addAll(['--exclude-tags', maestroDefaultSuiteExcludedTag]);
      } else if (await _flowExcludedFromDefaultSuite(flow)) {
        // config.yaml excludes known-gap. A different tag overrides that so
        // an explicit --flow still runs the file.
        command.addAll(['--exclude-tags', 'explicit']);
      }
      command.add(flow);
      outSink.writeln('\n▶️ Executing: ${command.join(' ')}');
      final result = await executor.run(command);
      if (result.stdout.trim().isNotEmpty) {
        outSink.writeln(result.stdout.trim());
      }
      if (result.exitCode != 0) {
        anyFailures = true;
        errSink.writeln(
          '⚠️ Flow $flow failed with exit code ${result.exitCode}',
        );
        if (result.stderr.trim().isNotEmpty) {
          errSink.writeln(result.stderr.trim());
        }
      } else {
        outSink.writeln('✅ Flow $flow completed successfully.');
      }
    }

    outSink.writeln(
      '\n===============================================================',
    );
    if (anyFailures) {
      outSink.writeln('⚠️ One or more Maestro flows encountered issues.');
    } else {
      outSink.writeln('✅ All Maestro flows executed cleanly!');
    }
    outSink.writeln(
      '===============================================================',
    );

    return anyFailures ? ExitCodes.software : ExitCodes.success;
  }
}

Future<bool> _flowExcludedFromDefaultSuite(String path) async {
  final file = File(path);
  if (!await file.exists()) return false;
  return excludesFromDefaultSuite(await file.readAsString());
}

abstract class ProcessExecutor {
  Future<ProcessExecutionResult> run(List<String> command);
}

class ProcessExecutionResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const ProcessExecutionResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

class RealProcessExecutor implements ProcessExecutor {
  const RealProcessExecutor();

  @override
  Future<ProcessExecutionResult> run(List<String> command) async {
    final result = await Process.run(command.first, command.skip(1).toList());
    return ProcessExecutionResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }
}

Future<void> main(List<String> args) async {
  final runner = MaestroVerificationRunner();
  exitCode = await runner.run(args);
}
