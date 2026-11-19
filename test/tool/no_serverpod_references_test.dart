import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard: the tree must not keep a Serverpod client, flag, host, or server package.
///
/// The Dart package name `refuge4serverpod` is intentionally left in place.
/// Renaming it would rewrite every import and would not change the Android
/// application id or the Firebase app ids. This file is the other exception,
/// because the check has to name the tokens it rejects.
void main() {
  test('source tree has no Serverpod client, flag, host, or server package', () {
    final hits = <String>[];
    final skipDirs = {'.git', 'build', '.dart_tool', '.idea', '.gradle'};
    const binarySuffixes = {
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.ico',
      '.jar',
      '.so',
      '.dll',
      '.dylib',
      '.zip',
      '.ttf',
      '.otf',
      '.pdf',
      '.mp4',
      '.mov',
      '.webm',
      '.mp3',
      '.wav',
      '.aac',
      '.apk',
      '.aab',
    };

    void walk(Directory dir) {
      for (final entity in dir.listSync(followLinks: false)) {
        final name = entity.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
        if (entity is Directory) {
          if (skipDirs.contains(name)) continue;
          if (name == 'sanctuary_server' || name == 'serverpod_scaffold') {
            hits.add('${entity.path}/');
            continue;
          }
          walk(entity);
          continue;
        }
        if (entity is! File) continue;
        final path = entity.path;
        if (path.endsWith('test/tool/no_serverpod_references_test.dart')) continue;
        if (path.endsWith('test/core/config/no_serverpod_backend_test.dart')) continue;
        final lowerName = name.toLowerCase();
        if (binarySuffixes.any(lowerName.endsWith)) continue;
        if (entity.lengthSync() > 2000000) continue;
        final String raw;
        try {
          raw = entity.readAsStringSync();
        } on FileSystemException {
          continue;
        }
        final stripped = raw
            .replaceAll('refuge4serverpod', '')
            .replaceAll('no_serverpod_backend_test.dart', '')
            .replaceAll('no_serverpod_references_test.dart', '');
        final lower = stripped.toLowerCase();
        if (lower.contains('serverpod') ||
            stripped.contains('sanctuary_server') ||
            stripped.contains('ENABLE_SERVERPOD') ||
            stripped.contains('SERVERPOD_URL') ||
            lower.contains('serverpod.space')) {
          hits.add(path);
        }
      }
    }

    walk(Directory.current);
    expect(hits, isEmpty, reason: hits.take(80).join('\n'));
  });
}
