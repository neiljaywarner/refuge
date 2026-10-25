import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  group('firestore.rules members-only (#601)', () {
    test('defines isSignedInMember and rejects anonymous', () {
      expect(rules, contains('function isSignedInMember()'));
      expect(
        rules,
        contains("request.auth.token.firebase.sign_in_provider != 'anonymous'"),
      );
    });

    test('does not allow unauthenticated reads or pre-alpha public writes', () {
      expect(rules, isNot(contains('allow read: if true')));
      expect(rules, isNot(contains('allow create: if true')));
      expect(rules, isNot(contains('allow create, update: if true')));
      expect(rules, isNot(contains('|| true')));
    });

    test('community collections require isSignedInMember', () {
      const collections = [
        'feature_votes',
        'member_feedback',
        'posts',
        'users',
        'comments',
        'soft_deleted_users',
        'reflections',
        'reflections_dev',
        'direct_messages',
        'directory_members',
        'member_notifications',
        'self_deleted_accounts',
      ];
      for (final name in collections) {
        expect(rules, contains('match /$name/{'), reason: name);
      }
      expect(rules, contains('allow read, write: if isSignedInMember();'));
      expect(
        rules,
        contains('allow create, read, update, delete: if isSignedInMember();'),
      );
    });
  });
}
