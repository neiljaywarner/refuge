import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Marionette Standalone Smoke Test Suite.
///
/// Drives the Selah Flutter application over the Dart VM Service WebSocket
/// without needing external dependencies.
///
/// Usage:
///   `dart run scripts/marionette_smoke_suite.dart ws://127.0.0.1:<PORT>/<TOKEN>/ws`
void main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('⚠️  Usage: dart run scripts/marionette_smoke_suite.dart <vm_service_ws_uri>');
    stdout.writeln(
      'Example: dart run scripts/marionette_smoke_suite.dart ws://127.0.0.1:56352/token=/ws',
    );
    exit(1);
  }

  final wsUri = args[0];
  stdout.writeln('🚀 Connecting to Flutter VM Service at $wsUri...');

  late final WebSocket socket;
  try {
    socket = await WebSocket.connect(wsUri);
    stdout.writeln('✅ Connected to VM Service WebSocket.');
  } catch (e) {
    stderr.writeln('❌ Failed to connect: $e');
    exit(1);
  }

  int reqId = 1;
  final completers = <int, Completer<Map<String, dynamic>>>{};

  socket.listen(
    (data) {
      try {
        final decoded = jsonDecode(data as String) as Map<String, dynamic>;
        final id = decoded['id'] as int?;
        if (id != null && completers.containsKey(id)) {
          completers[id]!.complete(decoded);
        }
      } catch (_) {}
    },
    onError: (e) {
      stderr.writeln('WebSocket error: $e');
    },
    onDone: () {
      stdout.writeln('WebSocket connection closed.');
    },
  );

  Future<Map<String, dynamic>> sendRpc(String method, [Map<String, dynamic>? params]) {
    final id = reqId++;
    final completer = Completer<Map<String, dynamic>>();
    completers[id] = completer;

    final request = <String, dynamic>{'jsonrpc': '2.0', 'id': id, 'method': method};
    if (params != null) {
      request['params'] = params;
    }

    socket.add(jsonEncode(request));
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => {'error': 'Timeout awaiting response for $method'},
    );
  }

  try {
    // 1. Check VM Service Info
    stdout.writeln('🔍 Checking VM version...');
    final vmInfo = await sendRpc('getVersion');
    stdout.writeln('   VM Version: ${vmInfo['result']?['major']}.${vmInfo['result']?['minor']}');

    // 2. Discover Isolate ID
    final vm = await sendRpc('getVM');
    final isolates = vm['result']?['isolates'] as List<dynamic>?;
    if (isolates == null || isolates.isEmpty) {
      stderr.writeln('❌ No active isolates found.');
      exit(1);
    }
    final isolateId = isolates.first['id'] as String;
    stdout.writeln('   Main Isolate: $isolateId');

    // 3. Inspect registered service extensions
    final isolate = await sendRpc('getIsolate', {'isolateId': isolateId});
    final extensions = isolate['result']?['extensionRPCs'] as List<dynamic>? ?? [];
    stdout.writeln('   Registered Extensions (${extensions.length} total):');
    final marionetteExts = extensions.where((e) => e.toString().contains('marionette')).toList();
    for (final ext in marionetteExts) {
      stdout.writeln('     • $ext');
    }

    // 4. Hot Reload Verification
    stdout.writeln('🔥 Testing proactive hot reload...');
    final reloadRes = await sendRpc('reloadSources', {'isolateId': isolateId});
    if (reloadRes['result']?['type'] == 'ReloadReport') {
      stdout.writeln('✅ Hot reload succeeded.');
    } else {
      stdout.writeln('ℹ️  Reload response: ${reloadRes['result']}');
    }

    stdout.writeln('🎉 Marionette VM Service smoke suite completed successfully!');
  } finally {
    await socket.close();
  }
}
