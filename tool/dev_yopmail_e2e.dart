/// Dev-flavor Maestro journey: timestamped yopmail signup, inbox confirm, walk, delete.
///
/// Usage (password is read from the environment, never from this file):
///
/// ```bash
/// export MAESTRO_TEST_PASSWORD   # same value as the GitHub secret
/// dart run tool/dev_yopmail_e2e.dart
/// dart run tool/dev_yopmail_e2e.dart --device emulator-5554
/// ```
///
/// Targets `com.belongonthespectrum.refuge.dev` only. Does not deploy production.
library;

import 'dart:io';

import 'package:http/http.dart' as http;

/// Inbox local-part plus `@yopmail.com`.
String timestampedYopmailAddress(int millis) => 'belong$millis@yopmail.com';

/// First Firebase email-action URL in [html], or null.
String? firebaseActionLink(String html) {
  final match = RegExp(
    r'https://[^\s"<>]*(?:firebaseapp\.com|identitytoolkit\.googleapis\.com)[^\s"<>]*',
    caseSensitive: false,
  ).firstMatch(html);
  if (match == null) return null;
  return match.group(0)!.replaceAll('&amp;', '&');
}

Future<void> main(List<String> args) async {
  final password = Platform.environment['MAESTRO_TEST_PASSWORD']?.trim() ?? '';
  if (password.isEmpty) {
    stderr.writeln('MAESTRO_TEST_PASSWORD is not set. Refusing to run.');
    exit(1);
  }

  String? device;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--device' && i + 1 < args.length) device = args[i + 1];
  }

  final email = timestampedYopmailAddress(DateTime.now().millisecondsSinceEpoch);
  final localPart = email.split('@').first;
  stdout.writeln('Dev e2e inbox: $email');

  final register = await _maestro(
    file: '.maestro/dev_e2e_register.yaml',
    email: email,
    password: password,
    device: device,
  );
  if (register != 0) exit(register);

  final confirmed = await confirmYopmailInbox(localPart);
  if (!confirmed) {
    stderr.writeln(
      'No Firebase confirmation link in the yopmail inbox. Deleting the account anyway.',
    );
  }

  final walk = await _maestro(
    file: '.maestro/dev_e2e_walk_and_delete.yaml',
    email: email,
    password: password,
    device: device,
  );
  exit(walk);
}

Future<int> _maestro({
  required String file,
  required String email,
  required String password,
  required String? device,
}) async {
  final args = <String>[
    'test',
    file,
    '-e',
    'BELONG_AUTH_EMAIL=$email',
    '-e',
    'MAESTRO_TEST_PASSWORD=$password',
  ];
  if (device != null) {
    args.addAll(['--device', device]);
  }
  final result = await Process.run('maestro', args);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  return result.exitCode;
}

/// Polls the public yopmail inbox and opens the first Firebase action link.
Future<bool> confirmYopmailInbox(String localPart) async {
  final client = http.Client();
  try {
    for (var attempt = 0; attempt < 8; attempt++) {
      final page = await client.get(Uri.parse('https://yopmail.com/en/?login=$localPart'));
      final yp = RegExp("yp='([^']+)'").firstMatch(page.body)?.group(1);
      final inboxUri = yp == null
          ? Uri.parse('https://yopmail.com/inbox?login=$localPart')
          : Uri.parse('https://yopmail.com/en/inbox?login=$localPart&p=1&yp=$yp');
      final inbox = await client.get(inboxUri);
      final link = firebaseActionLink(inbox.body);
      if (link != null) {
        final opened = await client.get(Uri.parse(link));
        stdout.writeln('Opened confirmation link (HTTP ${opened.statusCode}).');
        return opened.statusCode >= 200 && opened.statusCode < 400;
      }
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  } finally {
    client.close();
  }
  return false;
}
