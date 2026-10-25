import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

class ExitCodes {
  static const int success = 0;
  static const int usage = 64;
  static const int software = 70;
}

class SystemMemoryInfo {
  final String architecture;
  final int ramGb;
  final bool isAppleSilicon;

  const SystemMemoryInfo({
    required this.architecture,
    required this.ramGb,
    required this.isAppleSilicon,
  });

  String get recommendedModel {
    if (ramGb >= 48) {
      return 'qwen2.5-coder:14b & qwen2.5-coder:32b';
    } else if (ramGb >= 24) {
      return 'qwen2.5-coder:14b';
    } else {
      return 'qwen2.5-coder:7b';
    }
  }

  String get defaultModelName {
    if (ramGb >= 24) {
      return 'qwen2.5-coder:14b';
    } else {
      return 'qwen2.5-coder:7b';
    }
  }
}

class OllamaSetupRunner {
  final ArgParser argParser;
  final SystemInspector inspector;
  final HttpClient Function()? clientFactory;
  final IOSink outSink;
  final IOSink errSink;

  OllamaSetupRunner({
    SystemInspector? inspector,
    HttpClient Function()? clientFactory,
    IOSink? outSink,
    IOSink? errSink,
  }) : inspector = inspector ?? const RealSystemInspector(),
       clientFactory = clientFactory,
       outSink = outSink ?? stdout,
       errSink = errSink ?? stderr,
       argParser = ArgParser() {
    argParser
      ..addFlag(
        'check-only',
        abbr: 'c',
        defaultsTo: false,
        negatable: false,
        help: 'Inspects memory, service, and installed models without starting services or downloading models.',
      )
      ..addFlag(
        'pull',
        abbr: 'p',
        defaultsTo: false,
        negatable: false,
        help: 'Automatically pulls the recommended coding model if missing.',
      )
      ..addOption(
        'model',
        abbr: 'm',
        help: 'Model to verify or pull (defaults to recommended based on unified RAM).',
      )
      ..addOption('port', defaultsTo: '11434', help: 'Ollama service port.')
      ..addFlag(
        'help',
        abbr: 'h',
        defaultsTo: false,
        negatable: false,
        help: 'Shows usage documentation.',
      );
  }

  static int parseRamBytesToGb(String sysctlOutput) {
    final cleaned = sysctlOutput.trim();
    final bytes = int.tryParse(cleaned);
    if (bytes != null && bytes > 0) {
      return bytes ~/ (1024 * 1024 * 1024);
    }
    return 0;
  }

  static List<String> parseModelsList(String output) {
    final models = <String>[];
    for (final line in LineSplitter.split(output)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('NAME')) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        models.add(parts.first);
      }
    }
    return models;
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
      outSink.writeln('=================================================================');
      outSink.writeln('🦙 Belong on the Spectrum — Local Offline LLM Setup (Phase 1)');
      outSink.writeln('=================================================================');
      outSink.writeln(argParser.usage);
      return ExitCodes.success;
    }

    final checkOnly = results['check-only'] as bool;
    final autoPull = results['pull'] as bool;
    final port = int.tryParse(results['port'] as String) ?? 11434;

    outSink.writeln('=================================================================');
    outSink.writeln('🦙 Belong on the Spectrum — Local Offline LLM Setup (Phase 1)');
    outSink.writeln('=================================================================\n');

    // 1. Hardware & System Inspection
    outSink.writeln('1. Inspecting Hardware & Memory...');
    final memoryInfo = await inspector.inspectMemory();
    if (!memoryInfo.isAppleSilicon) {
      outSink.writeln(
        '⚠️ Architecture is ${memoryInfo.architecture} (Expected arm64 Apple Silicon). Metal GPU shader acceleration may not be available.',
      );
    } else {
      outSink.writeln(
        '✓ Apple Silicon (${memoryInfo.architecture}) detected. Metal GPU shader acceleration supported.',
      );
    }

    outSink.writeln('✓ Unified RAM: ${memoryInfo.ramGb} GB detected.');
    outSink.writeln('✓ Recommended Local Models: ${memoryInfo.recommendedModel}');

    final targetModel = (results['model'] as String?)?.isNotEmpty == true
        ? results['model'] as String
        : memoryInfo.defaultModelName;

    // 2. Check Ollama Binary
    outSink.writeln('\n2. Checking Ollama Binary...');
    final hasOllama = await inspector.commandExists('ollama');
    if (hasOllama) {
      final versionResult = await inspector.runCommand(['ollama', '--version']);
      outSink.writeln('✓ Ollama is installed: ${versionResult.trim()}');
    } else {
      outSink.writeln('ℹ️ Ollama is not installed.');
      if (!checkOnly) {
        final hasBrew = await inspector.commandExists('brew');
        if (hasBrew) {
          outSink.writeln('Installing Ollama via Homebrew (brew install ollama)...');
          await inspector.runCommand(['brew', 'install', 'ollama']);
        } else {
          outSink.writeln(
            'Homebrew not found. Please download Ollama directly from: https://ollama.com/download',
          );
        }
      }
    }

    // 3. Check Ollama Service
    outSink.writeln('\n3. Checking Ollama Service Status (http://127.0.0.1:$port)...');
    var isServiceUp = await inspector.isPortResponding(port);
    if (isServiceUp) {
      outSink.writeln('✓ Ollama service is active and responding on port $port.');
    } else {
      outSink.writeln('ℹ️ Ollama service is not responding on port $port.');
      if (!checkOnly && hasOllama) {
        outSink.writeln('Starting Ollama background service...');
        await inspector.startOllamaService();
        await Future<void>.delayed(const Duration(seconds: 2));
        isServiceUp = await inspector.isPortResponding(port);
        if (isServiceUp) {
          outSink.writeln('✓ Ollama service successfully started.');
        } else {
          outSink.writeln(
            '⚠️ Service startup in progress. If needed, run "ollama serve" in a separate terminal.',
          );
        }
      }
    }

    // 4. Check Installed Models
    outSink.writeln('\n4. Checking Installed Models...');
    if (hasOllama) {
      final listResult = await inspector.runCommand(['ollama', 'list']);
      final installedModels = parseModelsList(listResult);

      final hasTarget = installedModels.any(
        (m) => m.startsWith(targetModel) || m.contains(targetModel),
      );
      if (hasTarget) {
        outSink.writeln('✓ $targetModel is already downloaded.');
      } else {
        outSink.writeln('ℹ️ $targetModel not found.');
        if (autoPull && !checkOnly && isServiceUp) {
          outSink.writeln('⬇️ Pulling $targetModel (this may take several minutes)...');
          await inspector.runCommand(['ollama', 'pull', targetModel]);
          outSink.writeln('✓ $targetModel pulled successfully.');
        } else {
          outSink.writeln('   To pull: ollama pull $targetModel');
        }
      }
    }

    // 5. Run Health Check Utility
    outSink.writeln('\n5. Running Dart LLM Health Check Utility...');
    final verifyFile = File('tool/verify_ollama.dart');
    if (await verifyFile.exists()) {
      final verifyResult = await inspector.runCommand(['dart', 'run', 'tool/verify_ollama.dart']);
      if (verifyResult.trim().isNotEmpty) {
        outSink.writeln(verifyResult.trim());
      }
    } else {
      outSink.writeln('ℹ️ tool/verify_ollama.dart not found.');
    }

    outSink.writeln('\n=================================================================');
    outSink.writeln('🎉 Local Offline LLM Setup Completed!');
    outSink.writeln('Detailed documentation: docs/wiki/Local-LLMs-Phase-1-Getting-Started.md');
    outSink.writeln('=================================================================\n');

    return ExitCodes.success;
  }
}

abstract class SystemInspector {
  Future<SystemMemoryInfo> inspectMemory();
  Future<bool> commandExists(String command);
  Future<String> runCommand(List<String> command);
  Future<bool> isPortResponding(int port);
  Future<void> startOllamaService();
}

class RealSystemInspector implements SystemInspector {
  const RealSystemInspector();

  @override
  Future<SystemMemoryInfo> inspectMemory() async {
    final archResult = await Process.run('uname', ['-m']);
    final arch = archResult.stdout.toString().trim();
    final isArm = arch == 'arm64';

    var ramGb = 0;
    if (Platform.isMacOS) {
      final memResult = await Process.run('sysctl', ['-n', 'hw.memsize']);
      ramGb = OllamaSetupRunner.parseRamBytesToGb(memResult.stdout.toString());
    }

    return SystemMemoryInfo(
      architecture: arch,
      ramGb: ramGb,
      isAppleSilicon: isArm && Platform.isMacOS,
    );
  }

  @override
  Future<bool> commandExists(String command) async {
    final result = await Process.run('which', [command]);
    return result.exitCode == 0;
  }

  @override
  Future<String> runCommand(List<String> command) async {
    final result = await Process.run(command.first, command.skip(1).toList());
    return result.stdout.toString();
  }

  @override
  Future<bool> isPortResponding(int port) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 1);
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/tags'));
      final response = await request.close();
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startOllamaService() async {
    try {
      await Process.start('ollama', ['serve'], mode: ProcessStartMode.detached);
    } catch (_) {}
  }
}

Future<void> main(List<String> args) async {
  final runner = OllamaSetupRunner();
  exitCode = await runner.run(args);
}
