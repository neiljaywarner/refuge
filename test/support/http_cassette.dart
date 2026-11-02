import 'dart:convert';
import 'dart:io';

/// JSON body from `test/fixtures/http/`. Tests replay these with `package:nock`.
///
/// `charlatan` 0.5.0 declares `sdk: '>=2.15.0 <3.0.0'` and does not resolve on
/// this repo's Dart 3.13 pin. Nock is the Dart 3 cassette stand-in: it
/// intercepts `dart:io` `HttpClient`, which is what `package:http` and the
/// Appwrite SDK use. Nothing in these tests opens a live socket.
Map<String, dynamic> loadHttpFixture(String name) {
  final file = File('test/fixtures/http/$name');
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw FormatException('HTTP fixture $name must be a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}
