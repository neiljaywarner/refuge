import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

class ExitCodes {
  static const int success = 0;
  static const int usage = 64;
  static const int software = 70;
}

class DualPixelDemoRunner {
  final ArgParser argParser;
  final DeviceCommandExecutor executor;
  final IOSink outSink;
  final IOSink errSink;

  DualPixelDemoRunner({DeviceCommandExecutor? executor, IOSink? outSink, IOSink? errSink})
    : executor = executor ?? const RealDeviceCommandExecutor(),
      outSink = outSink ?? stdout,
      errSink = errSink ?? stderr,
      argParser = ArgParser() {
    argParser
      ..addOption(
        'left',
        abbr: 'l',
        help: 'Device ID for the Left Pixel (overrides LEFT_DEV and auto-detection).',
      )
      ..addOption(
        'right',
        abbr: 'r',
        help: 'Device ID for the Right Pixel (overrides RIGHT_DEV and auto-detection).',
      )
      ..addFlag(
        'staggered',
        abbr: 's',
        defaultsTo: true,
        help: 'Runs staggered multi-turn demo including reactions and sensory theme switch.',
      )
      ..addFlag(
        'record',
        defaultsTo: false,
        negatable: true,
        help: 'Records screen video on both devices and pulls MP4 files upon completion.',
      )
      ..addOption('duration', defaultsTo: '45', help: 'Duration in seconds for screen recording.')
      ..addFlag(
        'screenshots',
        defaultsTo: true,
        help: 'Captures step screenshots into scratch/ during execution.',
      )
      ..addFlag(
        'dry-run',
        abbr: 'n',
        defaultsTo: false,
        negatable: false,
        help: 'Detects devices and prints the step schedule without executing touches.',
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
    final physical = <String>[];
    final emulators = <String>[];
    for (final line in LineSplitter.split(adbOutput)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('List of devices')) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1] == 'device') {
        final id = parts[0];
        if (id.startsWith('emulator-')) {
          emulators.add(id);
        } else {
          physical.add(id);
        }
      }
    }
    return [...physical, ...emulators];
  }

  /// Escapes text for `adb shell input text`
  static String formatInputText(String text) => text
      .replaceAll(' ', '%s')
      .replaceAll("'", r"\'")
      .replaceAll('"', r'\"')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]');

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
      outSink.writeln('=== Belong on the Spectrum — Dual Device Live Demo Runner ===');
      outSink.writeln(argParser.usage);
      return ExitCodes.success;
    }

    final dryRun = results['dry-run'] as bool;
    final staggered = results['staggered'] as bool;
    final recordVideo = results['record'] as bool;
    final captureScreenshots = results['screenshots'] as bool;
    final durationSeconds = int.tryParse(results['duration'] as String) ?? 45;

    outSink.writeln('=== Belong on the Spectrum — Dual Device Live Demo Runner ===');

    // 1. Discover Devices
    String? leftDev = results['left'] as String?;
    String? rightDev = results['right'] as String?;

    if (leftDev == null || leftDev.isEmpty) {
      leftDev = Platform.environment['LEFT_DEV'];
    }
    if (rightDev == null || rightDev.isEmpty) {
      rightDev = Platform.environment['RIGHT_DEV'];
    }

    if (leftDev == null || rightDev == null || leftDev.isEmpty || rightDev.isEmpty) {
      final adbOutput = await executor.run(['adb', 'devices']);
      final devices = parseConnectedDevices(adbOutput.stdout);

      if (devices.length < 2) {
        errSink.writeln('⚠️ At least two connected Android devices/emulators are required.');
        errSink.writeln('Detected devices (${devices.length}): ${devices.join(', ')}');
        errSink.writeln('💡 Specify explicitly via: --left <ID> --right <ID>');
        return ExitCodes.software;
      }

      leftDev ??= devices[0];
      rightDev ??= devices[1];
    }

    outSink.writeln('📍 Left Device:  $leftDev');
    outSink.writeln('📍 Right Device: $rightDev');

    if (dryRun) {
      outSink.writeln('\n🔍 [DRY RUN] Execution Schedule:');
      outSink.writeln('   - Devices: Left ($leftDev), Right ($rightDev)');
      outSink.writeln(
        '   - Mode: ${staggered ? "Staggered interactive demonstration" : "Standard demo"}',
      );
      outSink.writeln('   - Screen recording: $recordVideo (${durationSeconds}s limit)');
      outSink.writeln('   - Step screenshots: $captureScreenshots');
      outSink.writeln('   - Step 1: Right device composes reflection via Serverpod Cloud');
      outSink.writeln('   - Step 2: Left device observes incoming post & taps Praying reaction');
      outSink.writeln('   - Step 3: Left device replies to Right reflection');
      outSink.writeln('   - Step 4: Right device switches to Charcoal/Dark sensory theme');
      outSink.writeln('   - Step 5: Left device opens About Sanctuary dialog and closes');
      outSink.writeln('✅ Dry run completed.');
      return ExitCodes.success;
    }

    // 2. Initial Setup
    outSink.writeln('\n🧹 Preparing devices and resetting state...');
    for (final dev in [leftDev, rightDev]) {
      await executor.run(['adb', '-s', dev, 'shell', 'pkill', '-f', 'screenrecord']);
      await executor.run(['adb', '-s', dev, 'shell', 'rm', '-f', '/sdcard/belong_demo.mp4']);
      await executor.run([
        'adb',
        '-s',
        dev,
        'shell',
        'am',
        'force-stop',
        'com.belongonthespectrum.sanctuary',
      ]);
    }

    await Future<void>.delayed(const Duration(seconds: 1));

    // Launch app on both devices
    outSink.writeln('🚀 Launching Sanctuary on Left & Right devices...');
    for (final dev in [leftDev, rightDev]) {
      await executor.run([
        'adb',
        '-s',
        dev,
        'shell',
        'monkey',
        '-p',
        'com.belongonthespectrum.sanctuary',
        '-c',
        'android.intent.category.LAUNCHER',
        '1',
      ]);
    }

    await Future<void>.delayed(const Duration(seconds: 3));

    if (captureScreenshots) {
      Directory('scratch').createSync(recursive: true);
      await executor.captureScreenshot(leftDev, 'scratch/step0_left_initial.png');
      await executor.captureScreenshot(rightDev, 'scratch/step0_right_initial.png');
      outSink.writeln('📸 Initial screens captured in scratch/');
    }

    // 3. Start Screen Recording if requested
    ProcessHandle? leftRec;
    ProcessHandle? rightRec;
    if (recordVideo) {
      outSink.writeln(
        '📹 Starting video screenrecord on both devices ($durationSeconds seconds)...',
      );
      leftRec = await executor.startBackground([
        'adb',
        '-s',
        leftDev,
        'shell',
        'screenrecord',
        '--time-limit',
        durationSeconds.toString(),
        '--bit-rate',
        '8000000',
        '/sdcard/belong_left_demo.mp4',
      ]);
      rightRec = await executor.startBackground([
        'adb',
        '-s',
        rightDev,
        'shell',
        'screenrecord',
        '--time-limit',
        durationSeconds.toString(),
        '--bit-rate',
        '8000000',
        '/sdcard/belong_right_demo.mp4',
      ]);
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    // 4. Step 1: Right device posts reflection
    outSink.writeln('\n=== Step 1: Right device composes reflection ===');
    await executor.run(['adb', '-s', rightDev, 'shell', 'input', 'tap', '524', '1266']);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    final msg1 = formatInputText(
      'From pixel on the right: Unhurried reflection via Serverpod Cloud!',
    );
    await executor.run(['adb', '-s', rightDev, 'shell', 'input', 'text', msg1]);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    await executor.run([
      'adb',
      '-s',
      rightDev,
      'shell',
      'input',
      'keyevent',
      '4',
    ]); // Close keyboard
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    await executor.run(['adb', '-s', rightDev, 'shell', 'input', 'tap', '778', '1470']); // Publish
    await Future<void>.delayed(const Duration(milliseconds: 3000));

    if (captureScreenshots) {
      await executor.captureScreenshot(rightDev, 'scratch/step1_right_published.png');
      await executor.captureScreenshot(leftDev, 'scratch/step1_left_received.png');
    }

    // 5. Step 2: Left device observes and reacts
    outSink.writeln('=== Step 2: Left device reacts with Prayer chip ===');
    await executor.run(['adb', '-s', leftDev, 'shell', 'input', 'tap', '184', '2119']);
    await Future<void>.delayed(const Duration(milliseconds: 2000));

    if (captureScreenshots) {
      await executor.captureScreenshot(leftDev, 'scratch/step2_left_reacted.png');
    }

    // 6. Step 3: Left device replies
    outSink.writeln('=== Step 3: Left device publishes reply reflection ===');
    await executor.run(['adb', '-s', leftDev, 'shell', 'input', 'tap', '524', '1266']);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    final msg2 = formatInputText(
      'From left pixel: Received your reflection! Fearfully and wonderfully made.',
    );
    await executor.run(['adb', '-s', leftDev, 'shell', 'input', 'text', msg2]);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    await executor.run(['adb', '-s', leftDev, 'shell', 'input', 'keyevent', '4']);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    await executor.run(['adb', '-s', leftDev, 'shell', 'input', 'tap', '778', '1470']);
    await Future<void>.delayed(const Duration(milliseconds: 3000));

    if (captureScreenshots) {
      await executor.captureScreenshot(leftDev, 'scratch/step3_left_replied.png');
      await executor.captureScreenshot(rightDev, 'scratch/step3_right_received_reply.png');
    }

    // 7. Step 4: Sensory theme switch on Right device
    outSink.writeln('=== Step 4: Sensory theme switch on Right device ===');
    await executor.run([
      'adb',
      '-s',
      rightDev,
      'shell',
      'input',
      'tap',
      '584',
      '226',
    ]); // theme icon
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await executor.run([
      'adb',
      '-s',
      rightDev,
      'shell',
      'input',
      'tap',
      '450',
      '530',
    ]); // dark theme
    await Future<void>.delayed(const Duration(milliseconds: 2000));

    if (captureScreenshots) {
      await executor.captureScreenshot(rightDev, 'scratch/step4_right_dark_theme.png');
    }

    // 8. Step 5: About dialog on Left device
    outSink.writeln('=== Step 5: About Sanctuary dialog on Left device ===');
    await executor.run([
      'adb',
      '-s',
      leftDev,
      'shell',
      'input',
      'tap',
      '699',
      '225',
    ]); // About button
    await Future<void>.delayed(const Duration(milliseconds: 3000));
    if (captureScreenshots) {
      await executor.captureScreenshot(leftDev, 'scratch/step5_left_about_dialog.png');
    }
    await executor.run([
      'adb',
      '-s',
      leftDev,
      'shell',
      'input',
      'tap',
      '828',
      '1999',
    ]); // Close button
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    // 9. Finalize Video Recordings
    if (recordVideo) {
      outSink.writeln('Waiting for recordings to conclude...');
      if (leftRec != null) await leftRec.exitCode;
      if (rightRec != null) await rightRec.exitCode;

      outSink.writeln('Pulling MP4 recordings from devices...');
      await executor.run([
        'adb',
        '-s',
        leftDev,
        'pull',
        '/sdcard/belong_left_demo.mp4',
        './belong_left_demo.mp4',
      ]);
      await executor.run([
        'adb',
        '-s',
        rightDev,
        'pull',
        '/sdcard/belong_right_demo.mp4',
        './belong_right_demo.mp4',
      ]);
      outSink.writeln('✓ Videos pulled: ./belong_left_demo.mp4 and ./belong_right_demo.mp4');
    }

    outSink.writeln('\n===============================================================');
    outSink.writeln('✅ Dual Pixel Live Demonstration Completed Successfully!');
    outSink.writeln('===============================================================');

    return ExitCodes.success;
  }
}

abstract class DeviceCommandExecutor {
  Future<DeviceExecutionResult> run(List<String> command);
  Future<ProcessHandle> startBackground(List<String> command);
  Future<void> captureScreenshot(String deviceId, String destPath);
}

class DeviceExecutionResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const DeviceExecutionResult({required this.exitCode, required this.stdout, required this.stderr});
}

abstract class ProcessHandle {
  Future<int> get exitCode;
}

class RealProcessHandle implements ProcessHandle {
  final Process process;
  RealProcessHandle(this.process);

  @override
  Future<int> get exitCode => process.exitCode;
}

class RealDeviceCommandExecutor implements DeviceCommandExecutor {
  const RealDeviceCommandExecutor();

  @override
  Future<DeviceExecutionResult> run(List<String> command) async {
    final result = await Process.run(command.first, command.skip(1).toList());
    return DeviceExecutionResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }

  @override
  Future<ProcessHandle> startBackground(List<String> command) async {
    final process = await Process.start(command.first, command.skip(1).toList());
    return RealProcessHandle(process);
  }

  @override
  Future<void> captureScreenshot(String deviceId, String destPath) async {
    final file = File(destPath);
    await file.parent.create(recursive: true);
    final process = await Process.start('adb', ['-s', deviceId, 'exec-out', 'screencap', '-p']);
    final sink = file.openWrite();
    await process.stdout.pipe(sink);
    await process.exitCode;
  }
}

Future<void> main(List<String> args) async {
  final runner = DualPixelDemoRunner();
  exitCode = await runner.run(args);
}
