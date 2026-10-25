import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 🎭 Marionette Live Demo & Feature Showcase CLI for **Belong on the Spectrum**.
///
/// Drives live walkthroughs of Belong's calm-tech features across physical
/// Google Pixels, Android emulators, and Chrome browsers.
///
/// Run via:
/// ```bash
/// dart run tool/marionette_demo.dart --help
/// ```
void main(List<String> rawArgs) async {
  final args = parseMarionetteArgs(rawArgs);

  if (args.showHelp) {
    printMarionetteHelp();
    exit(0);
  }

  printMarionetteBanner();

  // 1. Resolve Device & Permissions
  final deviceId = args.deviceId ?? await _detectDefaultDevice();
  stdout.writeln('📱 Target Device: \x1B[1;36m$deviceId\x1B[0m');

  if (args.grantPermissions && deviceId.isNotEmpty && !deviceId.startsWith('chrome')) {
    await _grantAdbPermissions(deviceId);
  }

  // 2. Discover or Connect to VM Service / App
  final wsUri = args.vmServiceUri ?? await _discoverVmServiceUri(deviceId);
  if (wsUri == null) {
    stderr.writeln('\x1B[31m❌ Could not resolve VM Service WebSocket URI.\x1B[0m');
    stderr.writeln('   Ensure Belong is running via: flutter run -d $deviceId');
    stderr.writeln('   Or pass explicit URI: --uri ws://127.0.0.1:<PORT>/<TOKEN>/ws');
    exit(1);
  }

  stdout.writeln('🔌 Connecting to VM Service at \x1B[32m$wsUri\x1B[0m...');

  late final WebSocket socket;
  try {
    socket = await WebSocket.connect(wsUri);
    stdout.writeln('✅ Connected successfully.\n');
  } catch (e) {
    stderr.writeln('\x1B[31m❌ Connection failed: $e\x1B[0m');
    exit(1);
  }

  final driver = _MarionetteDriver(
    socket: socket,
    speed: args.speed,
    isInteractive: args.isInteractive,
    shouldCapture: args.captureScreenshots,
    deviceId: deviceId,
  );

  try {
    await driver.runFullShowcase();
    stdout.writeln('\n\x1B[1;32m🎉 Live Belong Feature Showcase completed successfully!\x1B[0m\n');
  } catch (e, st) {
    stderr.writeln('\n\x1B[31m❌ Demo encountered an error: $e\x1B[0m');
    stderr.writeln(st);
    exit(1);
  } finally {
    await socket.close();
  }
}

class MarionetteDemoArgs {
  bool showHelp = false;
  String? deviceId;
  String? vmServiceUri;
  String speed = 'normal'; // slow, normal, fast
  bool isInteractive = false;
  bool grantPermissions = true;
  bool captureScreenshots = false;
  bool isDualDevice = false;
}

MarionetteDemoArgs parseMarionetteArgs(List<String> rawArgs) {
  final res = MarionetteDemoArgs();
  for (var i = 0; i < rawArgs.length; i++) {
    final a = rawArgs[i];
    if (a == '--help' || a == '-h') {
      res.showHelp = true;
    } else if (a == '--device' || a == '-d') {
      if (i + 1 < rawArgs.length) res.deviceId = rawArgs[++i];
    } else if (a.startsWith('--device=')) {
      res.deviceId = a.substring('--device='.length);
    } else if (a == '--uri' || a == '-u') {
      if (i + 1 < rawArgs.length) res.vmServiceUri = rawArgs[++i];
    } else if (a.startsWith('--uri=')) {
      res.vmServiceUri = a.substring('--uri='.length);
    } else if (a == '--speed' || a == '-s') {
      if (i + 1 < rawArgs.length) res.speed = rawArgs[++i];
    } else if (a.startsWith('--speed=')) {
      res.speed = a.substring('--speed='.length);
    } else if (a == '--interactive' || a == '-i') {
      res.isInteractive = true;
    } else if (a == '--no-grant-permissions') {
      res.grantPermissions = false;
    } else if (a == '--capture' || a == '-c') {
      res.captureScreenshots = true;
    } else if (a == '--dual') {
      res.isDualDevice = true;
    }
  }
  return res;
}

void printMarionetteBanner() {
  stdout.writeln('''
\x1B[1;33m  ____       _                   _     _            \x1B[0m
\x1B[1;33m |  _ \\     | |                 (_)   | |           \x1B[0m
\x1B[1;33m | |_) | ___| | ___  _ __   __ _ _  __| | ___  ___  \x1B[0m
\x1B[1;33m |  _ < / _ \\ |/ _ \\| '_ \\ / _` | |/ _` |/ _ \\/ __| \x1B[0m
\x1B[1;33m | |_) |  __/ | (_) | | | | (_| | | (_| |  __/\\__ \\ \x1B[0m
\x1B[1;33m |____/ \\___|_|\\___/|_| |_|\\__, |_|\\__,_|\\___||___/ \x1B[0m
\x1B[1;33m                            __/ |                   \x1B[0m
\x1B[1;33m                           |___/                    \x1B[0m
\x1B[1;34m 🎭 Marionette Live Feature Showcase & Interactive CLI \x1B[0m
''');
}

void printMarionetteHelp() {
  printMarionetteBanner();
  stdout.writeln('''
Usage:
  dart run tool/marionette_demo.dart [options]
  bash tool/marionette_demo.sh [options]

Options:
  -d, --device <id>          Target hardware ID, emulator, or chrome.
                             Auto-detects connected Pixel (56091JEBF14039 / 58221JEBF20835)
                             or falls back to emulator-5554 / chrome.
  -u, --uri <ws_uri>         Explicit VM Service WebSocket URI
                             (e.g. ws://127.0.0.1:56283/token=/ws).
  -s, --speed <mode>         Pacing speed: slow (3s), normal (1.5s), or fast (0.5s).
                             [default: normal]
  -i, --interactive          Pause at each feature milestone with an [Enter] prompt.
  -c, --capture              Capture high-resolution screenshots at each milestone.
      --no-grant-permissions Skip automatic ADB POST_NOTIFICATIONS permission grant.
      --dual                 Run synchronized dual-device comparison flow.
  -h, --help                 Show this help message.

Examples:
  # 1. Quick automated smoke walkthrough on connected Pixel 9a
  dart run tool/marionette_demo.dart

  # 2. Interactive guided presentation with manual pause between features
  dart run tool/marionette_demo.dart -i --speed slow

  # 3. Capture milestone visual proof into /tmp
  dart run tool/marionette_demo.dart --capture

  # 4. Target specific emulator or Chrome browser
  dart run tool/marionette_demo.dart -d emulator-5554
  dart run tool/marionette_demo.dart -d chrome
''');
}

Future<String> _detectDefaultDevice() async {
  try {
    final result = await Process.run('adb', ['devices']);
    final lines = LineSplitter.split(result.stdout as String);
    final attached = <String>[];
    for (final line in lines.skip(1)) {
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1] == 'device') {
        attached.add(parts[0]);
      }
    }

    if (attached.contains('56091JEBF14039')) return '56091JEBF14039';
    if (attached.contains('58221JEBF20835')) return '58221JEBF20835';
    if (attached.contains('emulator-5554')) return 'emulator-5554';
    if (attached.isNotEmpty) return attached.first;
  } catch (_) {}
  return 'chrome';
}

Future<void> _grantAdbPermissions(String deviceId) async {
  stdout.writeln('🔐 Granting notification permissions on $deviceId...');
  try {
    await Process.run('adb', [
      '-s',
      deviceId,
      'shell',
      'pm',
      'grant',
      'com.belongonthespectrum.sanctuary',
      'android.permission.POST_NOTIFICATIONS',
    ]);
    stdout.writeln('   ✅ android.permission.POST_NOTIFICATIONS granted.');
  } catch (e) {
    stderr.writeln('   ⚠️ Could not grant adb permissions: $e');
  }
}

Future<String?> _discoverVmServiceUri(String deviceId) async {
  // If Chrome, check devtools active port
  if (deviceId == 'chrome') {
    return 'ws://127.0.0.1:9100/ws';
  }

  // Check ADB forward ports for VM Service
  try {
    final forwards = await Process.run('adb', ['-s', deviceId, 'forward', '--list']);
    final lines = LineSplitter.split(forwards.stdout as String);
    for (final line in lines) {
      if (line.contains('tcp:')) {
        final match = RegExp(r'tcp:(\d+)').firstMatch(line);
        if (match != null) {
          final port = match.group(1);
          return 'ws://127.0.0.1:$port/ws';
        }
      }
    }
  } catch (_) {}

  // Fallback to local default Flutter debugging port
  return 'ws://127.0.0.1:56283/ws';
}

class _MarionetteDriver {
  final WebSocket socket;
  final String speed;
  final bool isInteractive;
  final bool shouldCapture;
  final String deviceId;

  int _rpcId = 1;
  final _completers = <int, Completer<Map<String, dynamic>>>{};

  _MarionetteDriver({
    required this.socket,
    required this.speed,
    required this.isInteractive,
    required this.shouldCapture,
    required this.deviceId,
  }) {
    socket.listen((data) {
      try {
        final decoded = jsonDecode(data as String) as Map<String, dynamic>;
        final id = decoded['id'] as int?;
        if (id != null && _completers.containsKey(id)) {
          _completers[id]!.complete(decoded);
        }
      } catch (_) {}
    });
  }

  Duration get _stepDelay => switch (speed) {
    'slow' => const Duration(seconds: 3),
    'fast' => const Duration(milliseconds: 500),
    _ => const Duration(milliseconds: 1500),
  };

  Future<Map<String, dynamic>> callRpc(String method, [Map<String, dynamic>? params]) {
    final id = _rpcId++;
    final completer = Completer<Map<String, dynamic>>();
    _completers[id] = completer;

    final req = {'jsonrpc': '2.0', 'id': id, 'method': method};
    if (params != null) req['params'] = params;

    socket.add(jsonEncode(req));
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => {'error': 'Timeout awaiting RPC $method'},
    );
  }

  Future<void> pause(String stepDescription) async {
    if (isInteractive) {
      stdout.write(
        '\n\x1B[1;35m[Interactive Pause]\x1B[0m $stepDescription. Press [Enter] to continue: ',
      );
      stdin.readLineSync();
    } else {
      await Future<void>.delayed(_stepDelay);
    }
  }

  Future<void> capture(String name) async {
    if (!shouldCapture) return;
    final file = '/tmp/belong_showcase_${name}_$deviceId.png';
    try {
      if (deviceId.startsWith('5') || deviceId.startsWith('emulator')) {
        await Process.run('adb', [
          '-s',
          deviceId,
          'exec-out',
          'screencap',
          '-p',
        ], stdoutEncoding: null).then((res) => File(file).writeAsBytes(res.stdout as List<int>));
        stdout.writeln('   📸 Captured milestone: $file');
      }
    } catch (_) {}
  }

  Future<void> runFullShowcase() async {
    stdout.writeln('🎬 \x1B[1;34mStarting Belong on the Spectrum Feature Showcase...\x1B[0m');

    // Step 1: Initial State & Brand Header
    stdout.writeln('\n1️⃣  \x1B[1mHeader & Calm Monogram Navigation\x1B[0m');
    stdout.writeln('   Inspecting active sanctuary feed & Belong infinity logo...');
    await capture('01_home_feed');
    await pause('Home Feed & Scripture Anchor');

    // Step 2: Sensory Themes Showcase
    stdout.writeln('\n2️⃣  \x1B[1mSensory Themes & Contrast Mode\x1B[0m');
    stdout.writeln('   Toggling High Contrast Mode for neurodivergent sensory comfort...');
    await callRpc('ext.flutter.driver', {
      'command': 'tap',
      'key': 'home_high_contrast_toggle_button',
    });
    await capture('02_high_contrast');
    await pause('Toggled High Contrast Mode');

    stdout.writeln('   Restoring Sage Calm Theme...');
    await callRpc('ext.flutter.driver', {
      'command': 'tap',
      'key': 'home_high_contrast_toggle_button',
    });
    await pause('Restored Sage Theme');

    // Step 3: Fellowship Spaces Navigation
    stdout.writeln('\n3️⃣  \x1B[1mFellowship Spaces Directory\x1B[0m');
    stdout.writeln('   Navigating from Feed to Fellowship Spaces...');
    await callRpc('ext.flutter.driver', {'command': 'tap', 'key': 'subnav_spaces_tab'});
    await capture('03_spaces_directory');
    await pause('Fellowship Spaces Overview');

    // Step 4: Member Profiles & Monograms
    stdout.writeln('\n4️⃣  \x1B[1mMember Profiles & Directory\x1B[0m');
    stdout.writeln('   Browsing fellowship disciples, comfort badges, and church affiliations...');
    await callRpc('ext.flutter.driver', {'command': 'tap', 'key': 'space_tile_members_directory'});
    await capture('04_members_directory');
    await pause('Member Directory & Comfort Badges');

    // Return to Spaces
    stdout.writeln('   Returning to Fellowship Spaces...');
    await callRpc('ext.flutter.driver', {'command': 'tap', 'tooltip': 'Back to Spaces'});
    await pause('Returned to Spaces');

    // Step 5: Feature Voting & Feedback
    stdout.writeln('\n5️⃣  \x1B[1mFeature Voting & Neurodivergent Feedback\x1B[0m');
    stdout.writeln('   Opening community voting sheet...');
    await callRpc('ext.flutter.driver', {
      'command': 'tap',
      'key': 'open_feedback_and_voting_button',
    });
    await capture('05_feature_voting');
    await pause('Feature Voting & Upvoting');

    // Close voting sheet
    await callRpc('ext.flutter.driver', {'command': 'tap', 'key': 'close_voting_sheet_button'});
    await pause('Closed Voting Sheet');

    // Step 6: Calm Notifications Inbox
    stdout.writeln('\n6️⃣  \x1B[1mCalm Notifications & Unhurried Digest\x1B[0m');
    stdout.writeln('   Switching to Calm Notifications tab...');
    await callRpc('ext.flutter.driver', {'command': 'tap', 'key': 'bottom_nav_tab_notifications'});
    await capture('06_calm_notifications');
    await pause('Calm Notifications & Filters');

    // Step 7: Return to Home Feed
    stdout.writeln('\n7️⃣  \x1B[1mReturning to Feed\x1B[0m');
    await callRpc('ext.flutter.driver', {'command': 'tap', 'key': 'bottom_nav_tab_home'});
    await callRpc('ext.flutter.driver', {'command': 'tap', 'key': 'subnav_feed_tab'});
    await capture('07_final_feed');
  }
}
