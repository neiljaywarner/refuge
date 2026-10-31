import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_io.dart';

void main() {
  test('IoProfileStorage uses a per-process session filename (#688)', () {
    final storage = IoProfileStorage();
    storage.clear();
    storage.save({
      'displayName': 'Fellow Member',
      'email': 'tester@example.com',
    });

    final expected = File(
      '${Directory.systemTemp.path}/belong_profile_session_$pid.json',
    );
    expect(expected.existsSync(), isTrue);

    final legacyShared = File(
      '${Directory.systemTemp.path}/belong_profile_session.json',
    );
    // This process must not write the shared pre-#688 path.
    expect(
      legacyShared.existsSync() &&
          legacyShared.readAsStringSync().contains('tester@example.com'),
      isFalse,
    );

    expect(storage.load()?['email'], 'tester@example.com');
    storage.clear();
    expect(expected.existsSync(), isFalse);
  });
}
