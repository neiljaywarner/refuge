// 📱 Belong on the Spectrum — Physical Device Connection Detector & Reminder CLI
//
// Detects plugged-in physical Google Pixels, formats maintainer email reminders,
// and offers a 1-click execution trigger for the physical glass regression suite.
// Tracking: Issue #282
//
// Usage:
//   dart run tool/device_reminder.dart                 # Inspects hardware & shows status
//   dart run tool/device_reminder.dart --run           # Detects device and executes regression suite
//   dart run tool/device_reminder.dart --email-preview # Previews reminder email for neilwarner@gmail.com
//   dart run tool/device_reminder.dart --mailto        # Generates mailto: URI for 1-click email client
//   dart run tool/device_reminder.dart --watch         # Continuously monitors USB plug-in events

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AndroidDevice {
  final String id;
  final String status;
  final String model;
  final bool isPhysical;

  const AndroidDevice({
    required this.id,
    required this.status,
    required this.model,
    required this.isPhysical,
  });

  @override
  String toString() =>
      '$model ($id) [${isPhysical ? "Physical Glass" : "Emulator"}]';
}

Future<List<AndroidDevice>> detectDevices() async {
  try {
    final result = await Process.run('adb', ['devices', '-l']);
    if (result.exitCode != 0) {
      return [];
    }

    final lines = (result.stdout as String).split('\n');
    final devices = <AndroidDevice>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('List of devices')) continue;

      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1] == 'device') {
        final id = parts[0];
        final isEmulator = id.startsWith('emulator-');

        String model = 'Android Device';
        for (final part in parts) {
          if (part.startsWith('model:')) {
            model = part.substring(6).replaceAll('_', ' ');
          }
        }

        devices.add(
          AndroidDevice(
            id: id,
            status: parts[1],
            model: model,
            isPhysical: !isEmulator,
          ),
        );
      }
    }

    return devices;
  } catch (_) {
    return [];
  }
}

String formatReminderEmail({
  required AndroidDevice device,
  required String recipient,
}) {
  final buffer = StringBuffer();
  buffer.writeln('To: $recipient');
  buffer.writeln(
    'Subject: 📱 ${device.model} Plugged In — Belong Physical Glass Regression Ready\n',
  );
  buffer.writeln('Hi Neil,\n');
  buffer.writeln('Your physical test hardware has been detected over USB:');
  buffer.writeln('  • Device: ${device.model}');
  buffer.writeln('  • Hardware ID: ${device.id}');
  buffer.writeln(
    '  • Platform: Android (${device.isPhysical ? "Physical Glass" : "Emulator"})\n',
  );
  buffer.writeln(
    'Whenever you are ready, run the single-command regression suite:',
  );
  buffer.writeln(
    '  cd /Users/neil/belongonthespectrum/refuge && ./tool/run_physical_glass_regression.sh\n',
  );
  buffer.writeln('This turnkey command will:');
  buffer.writeln('  1. Wake and unlock the device screen');
  buffer.writeln('  2. Execute the sociable multi-user concurrency BDD suite');
  buffer.writeln(
    '  3. Run the interactive Maestro user journey (.maestro/belong_full_journey.yaml)',
  );
  buffer.writeln(
    '  4. Auto-capture clean-frame 1080x2160 screenshots with zero status-bar PII',
  );
  buffer.writeln(
    '  5. Generate a verified markdown report at docs/benchmarks/physical_glass_regression_report.md\n',
  );
  buffer.writeln('Blessings,\nBelong Automated QA Daemon');
  return buffer.toString();
}

void printBanner(List<AndroidDevice> devices) {
  stdout.writeln(
    '\x1B[1m\x1B[34m╔════════════════════════════════════════════════════════════════════════════╗\x1B[0m',
  );
  stdout.writeln(
    '\x1B[1m\x1B[34m║ 📱 Belong on the Spectrum — Physical Hardware & Glass Connection Monitor   ║\x1B[0m',
  );
  stdout.writeln(
    '\x1B[1m\x1B[34m╚════════════════════════════════════════════════════════════════════════════╝\x1B[0m\n',
  );

  if (devices.isEmpty) {
    stdout.writeln(
      '\x1B[33m⚠️ No connected Android devices detected via ADB.\x1B[0m',
    );
    stdout.writeln(
      '👉 Plug in your Google Pixel 9a / Pixel 8 via USB, or launch emulator-5554.',
    );
    stdout.writeln('👉 Ensure Developer Options → USB Debugging is ON.');
    return;
  }

  stdout.writeln(
    '\x1B[1mConnected Devices Detected (${devices.length}):\x1B[0m',
  );
  for (final dev in devices) {
    final badge = dev.isPhysical
        ? '\x1B[32m[PHYSICAL GLASS]\x1B[0m'
        : '\x1B[36m[EMULATOR]\x1B[0m';
    stdout.writeln(
      '   • \x1B[1m${dev.model}\x1B[0m (\x1B[33m${dev.id}\x1B[0m) $badge',
    );
  }
}

Future<void> runRegressionSuite(String? deviceId) async {
  stdout.writeln(
    '\n\x1B[1m\x1B[32m🚀 Launching Physical Glass Regression Suite...\x1B[0m',
  );
  final args = <String>[];
  if (deviceId != null && deviceId.isNotEmpty) {
    args.addAll(['--device', deviceId]);
  }

  final process = await Process.start(
    './tool/run_physical_glass_regression.sh',
    args,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode == 0) {
    stdout.writeln(
      '\n\x1B[32m✅ Regression run finished successfully with exit code 0.\x1B[0m',
    );
  } else {
    stdout.writeln(
      '\n\x1B[31m❌ Regression run exited with code $exitCode.\x1B[0m',
    );
  }
}

Future<void> main(List<String> args) async {
  final shouldRun = args.contains('--run');
  final shouldPreviewEmail = args.contains('--email-preview');
  final shouldMailto = args.contains('--mailto');
  final isWatch = args.contains('--watch');
  const recipient = 'neilwarner@gmail.com';

  final devices = await detectDevices();
  printBanner(devices);

  final physical = devices.where((d) => d.isPhysical).toList();
  final primaryDevice = physical.isNotEmpty
      ? physical.first
      : (devices.isNotEmpty ? devices.first : null);

  if (primaryDevice != null && shouldPreviewEmail) {
    stdout.writeln('\n\x1B[1m📧 Formatted Reminder Email Body:\x1B[0m\n');
    stdout.writeln(
      formatReminderEmail(device: primaryDevice, recipient: recipient),
    );
    return;
  }

  if (primaryDevice != null && shouldMailto) {
    final emailText = formatReminderEmail(
      device: primaryDevice,
      recipient: recipient,
    );
    final subject = Uri.encodeComponent(
      '📱 ${primaryDevice.model} Plugged In — Run Glass Regression',
    );
    final body = Uri.encodeComponent(emailText);
    final mailtoUri = 'mailto:$recipient?subject=$subject&body=$body';
    stdout.writeln('\n\x1B[1m🔗 Mailto URI:\x1B[0m');
    stdout.writeln(mailtoUri);
    return;
  }

  if (primaryDevice != null && shouldRun) {
    await runRegressionSuite(primaryDevice.id);
    return;
  }

  if (isWatch) {
    stdout.writeln(
      '\n\x1B[36m👀 Watching for USB device connection changes (checking every 5s)... Press Ctrl+C to stop.\x1B[0m',
    );
    var lastDeviceIds = devices.map((d) => d.id).toSet();

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      final currentDevices = await detectDevices();
      final currentIds = currentDevices.map((d) => d.id).toSet();

      final newlyAdded = currentDevices
          .where((d) => !lastDeviceIds.contains(d.id))
          .toList();
      for (final dev in newlyAdded) {
        stdout.writeln(
          '\n\x1B[1m\x1B[32m🔔 NEW DEVICE CONNECTED: ${dev.model} (${dev.id})\x1B[0m',
        );
        stdout.writeln(
          '👉 Run: ./tool/run_physical_glass_regression.sh --device ${dev.id}',
        );
      }

      final removed = lastDeviceIds.difference(currentIds);
      for (final id in removed) {
        stdout.writeln('\n\x1B[33m🔌 Device disconnected: $id\x1B[0m');
      }

      lastDeviceIds = currentIds;
    });

    await Completer<void>().future;
  }

  if (primaryDevice != null) {
    stdout.writeln('\n\x1B[1m💡 Next Steps:\x1B[0m');
    stdout.writeln(
      '   • Run regression suite immediately: \x1B[32m./tool/run_physical_glass_regression.sh\x1B[0m',
    );
    stdout.writeln(
      '   • Or via Dart CLI:                  \x1B[32mdart run tool/device_reminder.dart --run\x1B[0m',
    );
    stdout.writeln(
      '   • Preview email reminder:           \x1B[36mdart run tool/device_reminder.dart --email-preview\x1B[0m',
    );
    stdout.writeln(
      '   • Continuous USB watch mode:        \x1B[36mdart run tool/device_reminder.dart --watch\x1B[0m',
    );
  }
}
