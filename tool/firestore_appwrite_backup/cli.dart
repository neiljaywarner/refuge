import 'dart:convert';
import 'dart:io';

import 'catalog.dart';
import 'config.dart';
import 'engine.dart';
import 'errors.dart';
import 'transport.dart';

const _encoder = JsonEncoder.withIndent('  ');

const backupUsage = '''
Firestore to Appwrite backup (first pass).

Copies the current Firestore documents into Appwrite backup_* tables so a
general restore is possible. It does not deploy an Appwrite function.
dm-mirror and dm-push stay the only live functions.

Usage:
  dart run tool/firestore_appwrite_backup.dart inventory
  dart run tool/firestore_appwrite_backup.dart schema --collection feature_votes
  dart run tool/firestore_appwrite_backup.dart provision --collection feature_votes --write
  dart run tool/firestore_appwrite_backup.dart sync --collection feature_votes --dry-run --input docs.json
  dart run tool/firestore_appwrite_backup.dart sync --collection users --write
  dart run tool/firestore_appwrite_backup.dart restore --collection feature_votes --dry-run --input snapshot.json
  dart run tool/firestore_appwrite_backup.dart restore --collection feature_votes --write --input snapshot.json

Every live command needs --write. --dry-run performs no writes.
Pass one of those flags, not both.

Environment (no flags for secrets):
  APPWRITE_API_KEY           required for --write sync and provision, and for restore without --input
  FIRESTORE_ACCESS_TOKEN     admin token for a live Firestore read or restore write
  APPWRITE_ENDPOINT          default https://nyc.cloud.appwrite.io/v1
  APPWRITE_PROJECT_ID        default 6adae5c40013c409e109
  APPWRITE_DATABASE_ID       default belong_community_db
  FIRESTORE_PROJECT_ID       default belongonthespectrum

--output must be outside this public repository. Stdout from sync --dry-run
contains document payloads. Do not paste it into an issue or pull request.
''';

/// Runs the backup CLI. Returns a process exit code and does not call [exit].
Future<int> runFirestoreAppwriteBackup(
  List<String> args, {
  BackupTransport? transport,
  Map<String, String>? environment,
  DateTime Function()? clock,
  StringSink? stdoutSink,
  StringSink? stderrSink,
  String? workingDirectory,
}) async {
  final out = stdoutSink ?? stdout;
  final err = stderrSink ?? stderr;
  final env = environment ?? Platform.environment;
  final cwd = workingDirectory ?? Directory.current.path;
  try {
    if (args.isEmpty || args.contains('--help') || args.contains('-h') || args.first == 'help') {
      out.writeln(backupUsage);
      return 0;
    }
    final command = args.first;
    final flags = _parseFlags(args.skip(1).toList());
    final config = BackupConfig.fromEnvironment(env);
    final http = transport ?? IoBackupTransport();
    final now = (clock ?? DateTime.now)().toUtc();
    switch (command) {
      case 'inventory':
        out.writeln(
          _encoder.convert([for (final collection in backupCollections) collection.toJson()]),
        );
        return 0;
      case 'schema':
        final collection = _collection(flags);
        out.writeln(_encoder.convert(_requestJson(provisionRequests(collection, config))));
        err.writeln('Schema only. No request was sent. Add X-Appwrite-Key when you provision.');
        return 0;
      case 'provision':
        final collection = _collection(flags);
        _requireMode(flags);
        if (flags.dryRun) {
          out.writeln(_encoder.convert(_requestJson(provisionRequests(collection, config))));
          err.writeln('dry-run: no table was created.');
          return 0;
        }
        await provisionCollection(collection: collection, config: config, transport: http);
        err.writeln(
          'Provisioned ${collection.tableId}. Wait until columns are available, then sync.',
        );
        return 0;
      case 'sync':
        final collection = _collection(flags);
        _requireMode(flags);
        _warnSensitive(collection, err);
        final input = _readInput(flags);
        if (!flags.dryRun && input == null && !config.hasFirestoreToken) {
          throw BackupCliException(
            'FIRESTORE_ACCESS_TOKEN is not set. Pass --input or set an admin token.',
            78,
          );
        }
        final report = await syncCollection(
          collection: collection,
          config: config,
          transport: http,
          dryRun: flags.dryRun,
          mirroredAt: now,
          inputText: input,
          since: flags.since,
        );
        final json = _encoder.convert(
          report.toJson(includeRows: flags.dryRun || flags.output != null),
        );
        if (flags.output != null) _writeOutsideRepo(flags.output!, json, cwd);
        out.writeln(
          flags.dryRun || flags.output == null
              ? json
              : _encoder.convert(report.toJson(includeRows: false)),
        );
        err.writeln(
          flags.dryRun
              ? 'dry-run: ${report.rows.length} row(s) for ${collection.tableId}. No request was sent.'
              : 'Wrote ${report.rows.length} row(s) to ${collection.tableId}.',
        );
        return 0;
      case 'restore':
        final collection = _collection(flags);
        _requireMode(flags);
        _warnSensitive(collection, err);
        final input = _readInput(flags);
        if (flags.dryRun && input == null) {
          throw BackupCliException(
            'restore --dry-run needs --input. A live read needs --write.',
            64,
          );
        }
        final report = await restoreCollection(
          collection: collection,
          config: config,
          transport: http,
          dryRun: flags.dryRun,
          inputText: input,
        );
        final json = _encoder.convert(
          report.toJson(includePatches: flags.dryRun || flags.output != null),
        );
        if (flags.output != null) _writeOutsideRepo(flags.output!, json, cwd);
        out.writeln(
          flags.dryRun || flags.output == null
              ? json
              : _encoder.convert(report.toJson(includePatches: false)),
        );
        err.writeln(
          flags.dryRun
              ? 'dry-run: ${report.patches.length} Firestore patch(es). Nothing was written.'
              : 'Restored ${report.patches.length} document(s) into ${config.firestoreProjectId}.',
        );
        return 0;
      default:
        err
          ..writeln('Unknown command: $command')
          ..writeln(backupUsage);
        return 64;
    }
  } on BackupCliException catch (error) {
    err.writeln(error.message);
    return error.exitCode;
  } on FormatException catch (error) {
    err.writeln(error.message);
    return 65;
  }
}

void _warnSensitive(BackupCollection collection, StringSink err) {
  if (!collection.sensitive && !collection.memberContent) return;
  err.writeln(
    '${collection.key} can contain member data. Do not paste stdout into a public issue or pull request.',
  );
}

BackupCollection _collection(_Flags flags) {
  final key = flags.collection;
  if (key == null || key.isEmpty) {
    throw BackupCliException('--collection is required.', 64);
  }
  return requireBackupCollection(key);
}

void _requireMode(_Flags flags) {
  if (flags.dryRun == flags.write) {
    throw BackupCliException('Pass either --dry-run or --write.', 64);
  }
}

String? _readInput(_Flags flags) {
  final path = flags.input;
  if (path == null) return null;
  final file = File(path);
  if (!file.existsSync()) throw BackupCliException('Input file not found.', 78);
  return file.readAsStringSync();
}

void _writeOutsideRepo(String path, String contents, String workingDirectory) {
  final root = Directory(workingDirectory).absolute.path;
  final resolved = Directory(workingDirectory).absolute.uri.resolve(path).toFilePath();
  final prefix = root.endsWith(Platform.pathSeparator) ? root : '$root${Platform.pathSeparator}';
  if (resolved == root || resolved.startsWith(prefix)) {
    throw BackupCliException(
      'Refusing to write backup JSON inside the repository. Choose a path outside this public repo.',
      78,
    );
  }
  File(resolved).writeAsStringSync(contents);
}

List<Map<String, Object?>> _requestJson(List<BackupRequest> requests) => [
  for (final request in requests)
    {'method': request.method, 'url': request.url.toString(), 'body': jsonDecode(request.body!)},
];

class _Flags {
  const _Flags({
    this.collection,
    this.input,
    this.output,
    this.since,
    required this.dryRun,
    required this.write,
  });

  final String? collection;
  final String? input;
  final String? output;
  final DateTime? since;
  final bool dryRun;
  final bool write;
}

_Flags _parseFlags(List<String> args) {
  String? collection;
  String? input;
  String? output;
  DateTime? since;
  var dryRun = false;
  var write = false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String? valueOf(String name) {
      final prefix = '$name=';
      if (arg.startsWith(prefix)) return arg.substring(prefix.length);
      if (arg == name) {
        if (i + 1 >= args.length) {
          throw BackupCliException('$name needs a value.', 64);
        }
        i++;
        return args[i];
      }
      return null;
    }

    final collectionValue = valueOf('--collection');
    if (collectionValue != null) {
      collection = collectionValue;
      continue;
    }
    final inputValue = valueOf('--input');
    if (inputValue != null) {
      input = inputValue;
      continue;
    }
    final outputValue = valueOf('--output');
    if (outputValue != null) {
      output = outputValue;
      continue;
    }
    final sinceValue = valueOf('--since');
    if (sinceValue != null) {
      final parsed = DateTime.tryParse(sinceValue);
      if (parsed == null) {
        throw BackupCliException('--since must be an ISO-8601 time.', 64);
      }
      since = parsed.toUtc();
      continue;
    }
    if (arg == '--dry-run') {
      dryRun = true;
      continue;
    }
    if (arg == '--write') {
      write = true;
      continue;
    }
    throw BackupCliException('Unknown argument: $arg', 64);
  }
  return _Flags(
    collection: collection,
    input: input,
    output: output,
    since: since,
    dryRun: dryRun,
    write: write,
  );
}
