import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/marionette_demo.dart';
import '../../tool/run_dual_pixel_demo.dart';
import '../../tool/run_maestro_verification.dart';
import '../../tool/run_physical_glass_regression.dart';
import '../../tool/setup_ollama.dart';

class MockProcessManager implements ProcessManager {
  final Map<String, ProcessResultData> responses;
  final List<List<String>> executedCommands = [];

  MockProcessManager(this.responses);

  @override
  Future<ProcessResultData> run(
    List<String> command, {
    Map<String, String>? environment,
    String? stdoutPath,
  }) async {
    executedCommands.add(command);
    final key = command.join(' ');
    for (final entry in responses.entries) {
      if (key.startsWith(entry.key) || entry.key == key) {
        return entry.value;
      }
    }
    return const ProcessResultData(exitCode: 0, stdout: '', stderr: '');
  }
}

class MockProcessExecutor implements ProcessExecutor {
  final Map<String, ProcessExecutionResult> responses;
  final List<List<String>> executed = [];

  MockProcessExecutor(this.responses);

  @override
  Future<ProcessExecutionResult> run(List<String> command) async {
    executed.add(command);
    final key = command.join(' ');
    for (final entry in responses.entries) {
      if (key.startsWith(entry.key) || entry.key == key) {
        return entry.value;
      }
    }
    return const ProcessExecutionResult(exitCode: 0, stdout: '', stderr: '');
  }
}

class MockSystemInspector implements SystemInspector {
  final SystemMemoryInfo memoryInfo;
  final bool hasOllama;
  final bool hasBrew;
  final bool isPortUp;
  final String modelsList;

  MockSystemInspector({
    required this.memoryInfo,
    this.hasOllama = true,
    this.hasBrew = true,
    this.isPortUp = true,
    this.modelsList = 'NAME\nqwen2.5-coder:14b\n',
  });

  @override
  Future<SystemMemoryInfo> inspectMemory() async => memoryInfo;

  @override
  Future<bool> commandExists(String command) async {
    if (command == 'ollama') return hasOllama;
    if (command == 'brew') return hasBrew;
    return true;
  }

  @override
  Future<String> runCommand(List<String> command) async {
    if (command.contains('list')) return modelsList;
    if (command.contains('--version')) return 'ollama version is 0.5.1';
    return '';
  }

  @override
  Future<bool> isPortResponding(int port) async => isPortUp;

  @override
  Future<void> startOllamaService() async {}
}

class MockDeviceCommandExecutor implements DeviceCommandExecutor {
  final List<List<String>> commands = [];

  @override
  Future<DeviceExecutionResult> run(List<String> command) async {
    commands.add(command);
    if (command.contains('devices')) {
      return const DeviceExecutionResult(
        exitCode: 0,
        stdout: 'List of devices attached\n56091JEBF14039\tdevice\n58221JEBF20835\tdevice\n',
        stderr: '',
      );
    }
    return const DeviceExecutionResult(exitCode: 0, stdout: '', stderr: '');
  }

  @override
  Future<ProcessHandle> startBackground(List<String> command) async {
    commands.add(command);
    return MockProcessHandle();
  }

  @override
  Future<void> captureScreenshot(String deviceId, String destPath) async {}
}

class MockProcessHandle implements ProcessHandle {
  @override
  Future<int> get exitCode async => 0;
}

void main() {
  group('PhysicalGlassRegressionRunner', () {
    test('displays help and exits with code 0', () async {
      final runner = PhysicalGlassRegressionRunner();
      final code = await runner.run(['--help']);
      expect(code, equals(0));
    });

    test('returns usage code 64 on invalid arguments', () async {
      final runner = PhysicalGlassRegressionRunner();
      final code = await runner.run(['--invalid-flag-123']);
      expect(code, equals(64));
    });

    test('parseConnectedDevices correctly parses adb output', () {
      const adbOutput = '''
List of devices attached
56091JEBF14039\tdevice
emulator-5554\tdevice
offline_device\toffline
unauthorized_device\tunauthorized
''';
      final devices = PhysicalGlassRegressionRunner.parseConnectedDevices(adbOutput);
      expect(devices, equals(['56091JEBF14039', 'emulator-5554']));
    });

    test('parseBatteryLevel extracts percentage accurately', () {
      const dumpsys = '''
Current Battery Service state:
  AC powered: false
  USB powered: true
  level: 87
  scale: 100
''';
      expect(PhysicalGlassRegressionRunner.parseBatteryLevel(dumpsys), equals('87%'));
      expect(PhysicalGlassRegressionRunner.parseBatteryLevel('no battery info'), equals('N/A'));
    });

    test('parseWakefulness extracts wakefulness state', () {
      const dumpsys = 'Display Power: state=ON\nmWakefulness=Awake';
      expect(PhysicalGlassRegressionRunner.parseWakefulness(dumpsys), equals('Awake'));
      expect(PhysicalGlassRegressionRunner.parseWakefulness('no info'), equals('Unknown'));
    });

    test('captures report correctly under dry run', () async {
      final manager = MockProcessManager({
        'adb devices': const ProcessResultData(
          exitCode: 0,
          stdout: 'List of devices attached\n56091JEBF14039\tdevice\n',
          stderr: '',
        ),
      });
      final runner = PhysicalGlassRegressionRunner(processManager: manager);
      final code = await runner.run(['--dry-run']);
      expect(code, equals(0));
    });
  });

  group('MaestroVerificationRunner', () {
    test('displays help and exits with code 0', () async {
      final runner = MaestroVerificationRunner();
      final code = await runner.run(['--help']);
      expect(code, equals(0));
    });

    test('dry run parses existing flows and succeeds', () async {
      final runner = MaestroVerificationRunner();
      final code = await runner.run(['--dry-run']);
      expect(code, equals(0));
    });

    test('lists available flows', () async {
      final runner = MaestroVerificationRunner();
      final code = await runner.run(['--list']);
      expect(code, equals(0));
    });
  });

  group('OllamaSetupRunner', () {
    test('displays help and exits with code 0', () async {
      final runner = OllamaSetupRunner();
      final code = await runner.run(['--help']);
      expect(code, equals(0));
    });

    test('parseRamBytesToGb converts raw bytes correctly', () {
      // 48 GB = 51539607552 bytes
      expect(OllamaSetupRunner.parseRamBytesToGb('51539607552'), equals(48));
      // 24 GB = 25769803776 bytes
      expect(OllamaSetupRunner.parseRamBytesToGb('25769803776'), equals(24));
      // 8 GB = 8589934592 bytes
      expect(OllamaSetupRunner.parseRamBytesToGb('8589934592'), equals(8));
      expect(OllamaSetupRunner.parseRamBytesToGb('invalid'), equals(0));
    });

    test('SystemMemoryInfo recommends models by memory tier', () {
      const mem48 = SystemMemoryInfo(architecture: 'arm64', ramGb: 48, isAppleSilicon: true);
      expect(mem48.recommendedModel, contains('32b'));
      expect(mem48.defaultModelName, equals('qwen2.5-coder:14b'));

      const mem24 = SystemMemoryInfo(architecture: 'arm64', ramGb: 24, isAppleSilicon: true);
      expect(mem24.recommendedModel, equals('qwen2.5-coder:14b'));
      expect(mem24.defaultModelName, equals('qwen2.5-coder:14b'));

      const mem8 = SystemMemoryInfo(architecture: 'arm64', ramGb: 8, isAppleSilicon: true);
      expect(mem8.recommendedModel, equals('qwen2.5-coder:7b'));
      expect(mem8.defaultModelName, equals('qwen2.5-coder:7b'));
    });

    test('parseModelsList extracts model names', () {
      const output = '''
NAME                    ID              SIZE    MODIFIED
qwen2.5-coder:14b       abc12345        9.0 GB  2 days ago
llama3.2:3b             def67890        2.0 GB  1 week ago
''';
      final models = OllamaSetupRunner.parseModelsList(output);
      expect(models, equals(['qwen2.5-coder:14b', 'llama3.2:3b']));
    });

    test('check-only reports status without pulling', () async {
      final inspector = MockSystemInspector(
        memoryInfo: const SystemMemoryInfo(architecture: 'arm64', ramGb: 48, isAppleSilicon: true),
      );
      final runner = OllamaSetupRunner(inspector: inspector);
      final code = await runner.run(['--check-only']);
      expect(code, equals(0));
    });
  });

  group('DualPixelDemoRunner', () {
    test('displays help and exits with 0', () async {
      final runner = DualPixelDemoRunner();
      final code = await runner.run(['--help']);
      expect(code, equals(0));
    });

    test('formatInputText escapes special characters for adb text input', () {
      final text = 'Hello world! (Refuge) [Calm]';
      final formatted = DualPixelDemoRunner.formatInputText(text);
      expect(formatted, equals(r'Hello%sworld!%s\(Refuge\)%s\[Calm\]'));
    });

    test('parseConnectedDevices sorts physical devices first', () {
      const adbOutput = '''
List of devices attached
emulator-5554\tdevice
56091JEBF14039\tdevice
emulator-5556\tdevice
58221JEBF20835\tdevice
''';
      final devices = DualPixelDemoRunner.parseConnectedDevices(adbOutput);
      expect(devices, equals(['56091JEBF14039', '58221JEBF20835', 'emulator-5554', 'emulator-5556']));
    });

    test('dry run verifies devices and exits with 0', () async {
      final executor = MockDeviceCommandExecutor();
      final runner = DualPixelDemoRunner(executor: executor);
      final code = await runner.run(['--dry-run', '--left', 'dev1', '--right', 'dev2']);
      expect(code, equals(0));
    });
  });

  group('MarionetteDemoArgs and CLI parsing', () {
    test('parses default arguments cleanly', () {
      final args = parseMarionetteArgs([]);
      expect(args.showHelp, isFalse);
      expect(args.deviceId, isNull);
      expect(args.vmServiceUri, isNull);
      expect(args.speed, equals('normal'));
      expect(args.isInteractive, isFalse);
      expect(args.grantPermissions, isTrue);
      expect(args.captureScreenshots, isFalse);
      expect(args.isDualDevice, isFalse);
    });

    test('parses help flag correctly', () {
      final argsShort = parseMarionetteArgs(['-h']);
      expect(argsShort.showHelp, isTrue);

      final argsLong = parseMarionetteArgs(['--help']);
      expect(argsLong.showHelp, isTrue);
    });

    test('parses device flag, interactive flag, speed, and capture', () {
      final args = parseMarionetteArgs([
        '--device',
        '56091JEBF14039',
        '-i',
        '--speed',
        'slow',
        '--capture',
        '--no-grant-permissions',
        '--dual',
      ]);
      expect(args.deviceId, equals('56091JEBF14039'));
      expect(args.isInteractive, isTrue);
      expect(args.speed, equals('slow'));
      expect(args.captureScreenshots, isTrue);
      expect(args.grantPermissions, isFalse);
      expect(args.isDualDevice, isTrue);
    });

    test('parses equals-style flags', () {
      final args = parseMarionetteArgs([
        '--device=emulator-5554',
        '--speed=fast',
        '--uri=ws://127.0.0.1:56283/token=/ws',
      ]);
      expect(args.deviceId, equals('emulator-5554'));
      expect(args.speed, equals('fast'));
      expect(args.vmServiceUri, equals('ws://127.0.0.1:56283/token=/ws'));
    });
  });
}
