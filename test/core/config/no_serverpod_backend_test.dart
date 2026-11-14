import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository_factory.dart';

void main() {
  test('backend mode resolves to the appwrite default and has no serverpod value', () {
    expect(configuredBackendMode, BackendMode.appwrite);
    expect(BackendMode.values.map((mode) => mode.name), isNot(contains('serverpod')));
  });
}
