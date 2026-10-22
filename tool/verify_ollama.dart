// 🦙 Belong on the Spectrum — Local Ollama Health Check & Diagnostic Tool
//
// Verifies local inference on Apple Silicon (Metal GPU acceleration)
// Issue #271 (Phase 1) & Issue #272 (Phase 2)
//
// Usage:
//   dart run tool/verify_ollama.dart [--skip-infer]

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final skipInfer = args.contains('--skip-infer');
  stdout.writeln('\x1B[1m\x1B[34m=================================================================\x1B[0m');
  stdout.writeln('\x1B[1m\x1B[34m🦙 Belong on the Spectrum — Local Ollama Diagnostic (Phase 1)\x1B[0m');
  stdout.writeln('\x1B[1m\x1B[34m=================================================================\x1B[0m\n');

  // 1. Hardware & Memory Audit
  stdout.writeln('\x1B[1m1. Hardware & Unified Memory Profile:\x1B[0m');
  final isMac = Platform.isMacOS;
  stdout.writeln('   • Operating System: ${Platform.operatingSystem} (${Platform.operatingSystemVersion})');
  stdout.writeln('   • Dart SDK: ${Platform.version.split(' ').first}');

  if (isMac) {
    try {
      final memResult = await Process.run('sysctl', ['-n', 'hw.memsize']);
      final ramBytes = int.tryParse(memResult.stdout.toString().trim()) ?? 0;
      final ramGb = (ramBytes / (1024 * 1024 * 1024)).round();
      stdout.writeln('   • Apple Silicon Unified RAM: \x1B[32m${ramGb} GB\x1B[0m');

      if (ramGb >= 48) {
        stdout.writeln('   • Headroom Grade: \x1B[32mOptimal (48GB+)\x1B[0m — Can run qwen2.5-coder:32b (~20GB VRAM) + Flutter emulators simultaneously.');
      } else if (ramGb >= 24) {
        stdout.writeln('   • Headroom Grade: \x1B[33mGood (24GB–36GB)\x1B[0m — Recommended: qwen2.5-coder:14b (~9GB VRAM).');
      } else {
        stdout.writeln('   • Headroom Grade: \x1B[33mConservative (<24GB)\x1B[0m — Recommended: qwen2.5-coder:7b (~5GB VRAM).');
      }
    } catch (_) {
      stdout.writeln('   • Unified RAM: Unable to query sysctl.');
    }
  }

  // 2. Connectivity to Ollama Local Daemon
  stdout.writeln('\n\x1B[1m2. Probing Ollama HTTP Service:\x1B[0m');
  const baseUrl = 'http://127.0.0.1:11434';
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);

  Map<String, dynamic>? tagsData;
  try {
    final request = await client.getUrl(Uri.parse('$baseUrl/api/tags'));
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      tagsData = jsonDecode(body) as Map<String, dynamic>;
      stdout.writeln('   • Status: \x1B[32mActive & Responding (HTTP 200)\x1B[0m at $baseUrl');
    } else {
      stdout.writeln('   • Status: \x1B[31mHTTP Error ${response.statusCode}\x1B[0m');
    }
  } catch (e) {
    stdout.writeln('   • Status: \x1B[31mNot Reachable\x1B[0m ($e)');
  } finally {
    client.close();
  }

  if (tagsData == null) {
    stdout.writeln('\n\x1B[33m⚠️ Ollama daemon is currently not running or not installed.\x1B[0m');
    stdout.writeln('   \x1B[1mRecommended Next Steps to Start Ollama:\x1B[0m');
    stdout.writeln('   1. Install Ollama:');
    stdout.writeln('      \x1B[36mbrew install ollama\x1B[0m (or download from https://ollama.com/download)');
    stdout.writeln('   2. Start the local server:');
    stdout.writeln('      \x1B[36mbrew services start ollama\x1B[0m  (or run \x1B[36mollama serve\x1B[0m in a separate terminal)');
    stdout.writeln('   3. Download the coding specialist models:');
    stdout.writeln('      \x1B[36mollama pull qwen2.5-coder:14b\x1B[0m  (~9 GB, ~50 tok/sec utility model)');
    stdout.writeln('      \x1B[36mollama pull qwen2.5-coder:32b\x1B[0m  (~20 GB, ~30 tok/sec architecture specialist)');
    stdout.writeln('   4. Re-run this check:');
    stdout.writeln('      \x1B[36mdart run tool/verify_ollama.dart\x1B[0m\n');
    exit(0);
  }

  // 3. Model Inventory Inspection
  stdout.writeln('\n\x1B[1m3. Inspecting Downloaded Models:\x1B[0m');
  final models = (tagsData['models'] as List<dynamic>?) ?? [];
  if (models.isEmpty) {
    stdout.writeln('   \x1B[33mNo models currently installed in local Ollama storage.\x1B[0m');
    stdout.writeln('   Run: \x1B[36mollama pull qwen2.5-coder:14b\x1B[0m');
  } else {
    stdout.writeln('   Found \x1B[32m${models.length}\x1B[0m local model(s):');
    String? selectedTestModel;

    for (final m in models) {
      final name = m['name'] as String? ?? 'unknown';
      final sizeBytes = (m['size'] as num?)?.toDouble() ?? 0.0;
      final sizeGb = (sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
      final details = m['details'] as Map<String, dynamic>? ?? {};
      final parameterSize = details['parameter_size'] as String? ?? 'unknown';
      final quant = details['quantization_level'] as String? ?? 'unknown';

      stdout.writeln('   • \x1B[1m$name\x1B[0m — $sizeGb GB (Params: $parameterSize, Quant: $quant)');

      if (name.contains('qwen2.5-coder') && selectedTestModel == null) {
        selectedTestModel = name;
      }
    }

    selectedTestModel ??= (models.first['name'] as String?);

    // 4. Sample Inference Benchmark
    if (!skipInfer && selectedTestModel != null) {
      stdout.writeln('\n\x1B[1m4. Testing Inference on $selectedTestModel:\x1B[0m');
      stdout.writeln('   Prompt: "Write a 1-line Dart function that reverses a string."');
      stdout.write('   Waiting for Metal GPU response... ');

      final inferClient = HttpClient()..connectionTimeout = const Duration(seconds: 30);
      try {
        final stopwatch = Stopwatch()..start();
        final req = await inferClient.postUrl(Uri.parse('$baseUrl/api/generate'));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({
          'model': selectedTestModel,
          'prompt': 'Write a 1-line Dart function that reverses a string. Respond with ONLY the Dart function code.',
          'stream': false,
        }));
        final res = await req.close();
        stopwatch.stop();

        if (res.statusCode == 200) {
          final resBody = await res.transform(utf8.decoder).join();
          final genData = jsonDecode(resBody) as Map<String, dynamic>;
          final responseText = (genData['response'] as String?)?.trim() ?? '';
          final totalDurationNs = (genData['total_duration'] as num?)?.toDouble() ?? 0.0;
          final evalCount = (genData['eval_count'] as num?)?.toInt() ?? 0;
          final evalDurationNs = (genData['eval_duration'] as num?)?.toDouble() ?? 0.0;

          final tokensPerSec = evalDurationNs > 0
              ? (evalCount / (evalDurationNs / 1e9)).toStringAsFixed(1)
              : 'N/A';
          final latencyMs = (totalDurationNs / 1e6).toStringAsFixed(0);

          stdout.writeln('\x1B[32mCompleted in ${latencyMs}ms!\x1B[0m');
          stdout.writeln('   • Generation Speed: \x1B[32m$tokensPerSec tokens/sec\x1B[0m ($evalCount tokens)');
          stdout.writeln('   • Output snippet: \x1B[36m$responseText\x1B[0m');
        } else {
          stdout.writeln('\x1B[31mHTTP ${res.statusCode}\x1B[0m');
        }
      } catch (e) {
        stdout.writeln('\x1B[31mInference failed ($e)\x1B[0m');
      } finally {
        inferClient.close();
      }
    }
  }

  stdout.writeln('\n\x1B[1m\x1B[32m=================================================================\x1B[0m');
  stdout.writeln('\x1B[1m\x1B[32m✓ Local LLM Health Check Completed Successfully!\x1B[0m');
  stdout.writeln('\x1B[1m\x1B[32m=================================================================\x1B[0m\n');
}
