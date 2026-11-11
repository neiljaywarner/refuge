import 'dart:io' show Platform;

import 'client_session_os_facts.dart';

/// Android, iOS, and desktop. Not compiled for web.
ClientSessionOsFacts readClientSessionOsFacts() {
  final version = Platform.operatingSystemVersion.split('\n').first.trim();
  return ClientSessionOsFacts(
    osName: Platform.operatingSystem,
    osVersion: version.isEmpty ? null : version,
  );
}
