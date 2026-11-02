import 'client_session_os_facts.dart';

/// Web and other builds without `dart:io`.
ClientSessionOsFacts readClientSessionOsFacts() => const ClientSessionOsFacts(osName: 'web');
