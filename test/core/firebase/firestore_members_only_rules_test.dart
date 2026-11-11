import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String firestoreRules;
  late String storageRules;
  late String firebaseConfig;

  setUpAll(() {
    firestoreRules = File('firestore.rules').readAsStringSync();
    storageRules = File('storage.rules').readAsStringSync();
    firebaseConfig = File('firebase.json').readAsStringSync();
  });

  group('firestore.rules members-only & guest audit (#601, #620)', () {
    test('defines isSignedInMember and rejects anonymous', () {
      expect(firestoreRules, contains('function isSignedInMember()'));
      expect(firestoreRules, contains('function uidBanActive(uid)'));
      expect(firestoreRules, contains('!uidBanActive(request.auth.uid)'));
      expect(storageRules, contains('function uidBanActive(uid)'));
      expect(storageRules, contains('!uidBanActive(request.auth.uid)'));
      expect(
        firestoreRules,
        contains("request.auth.token.firebase.sign_in_provider != 'anonymous'"),
      );
    });

    test('does not allow unauthenticated reads or pre-alpha public writes', () {
      expect(firestoreRules, isNot(contains('allow read: if true')));
      expect(firestoreRules, isNot(contains('allow create: if true')));
      expect(firestoreRules, isNot(contains('allow create, update: if true')));
      expect(firestoreRules, isNot(contains('|| true')));
    });

    test('community collections require isSignedInMember and exist in schema', () {
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
        expect(firestoreRules, contains('match /$name/{'), reason: name);
      }
    });

    test('feature vote updates require voterIds membership (#733)', () {
      expect(firestoreRules, contains('function featureVoteVoterIds'));
      expect(firestoreRules, contains('function featureVoteUpvote()'));
      expect(firestoreRules, contains('function featureVoteUnvote()'));
      expect(firestoreRules, contains('hasAll(featureVoteVoterIds(resource.data))'));
      expect(firestoreRules, contains("hasOnly(['votes', 'voterIds', 'lastVotedAt'])"));
    });

    test('feedback submissions are immutable to prevent tampering', () {
      expect(firestoreRules, contains('match /member_feedback/{feedbackId}'));
      expect(firestoreRules, contains('allow update, delete: if false;'));
    });

    test('comment update and delete require author check', () {
      expect(firestoreRules, contains('match /comments/{commentId}'));
      expect(firestoreRules, contains('function isAuthorOf(data)'));
      expect(firestoreRules, contains('isAuthorOf(resource.data)'));
    });

    test('post and reflection mirrors guard update and delete by authorId', () {
      expect(firestoreRules, contains('match /posts/{postId}'));
      expect(firestoreRules, contains('match /reflections/{postId}'));
      expect(firestoreRules, contains('match /reflections_dev/{postId}'));
      expect(firestoreRules, contains("request.auth.uid == resource.data.get('authorId', null)"));
    });

    test('creates must name the signed-in member', () {
      expect(firestoreRules, contains('function createsAsSelf()'));
      expect(
        firestoreRules,
        contains("request.resource.data.get('authorId', '') == request.auth.uid"),
      );
      expect(firestoreRules, contains('allow create: if isSignedInMember() && createsAsSelf();'));
    });
  });

  group('storage.rules members-only & guest audit (#620)', () {
    test('defines isSignedInMember and rejects anonymous sessions in storage', () {
      expect(storageRules, contains('function isSignedInMember()'));
      expect(storageRules, contains("request.auth.token.firebase.sign_in_provider != 'anonymous'"));
    });

    test('enforces strict path separation, size limits, and image types', () {
      expect(storageRules, contains('match /avatars/{userId}/{allPaths=**}'));
      expect(storageRules, contains('request.resource.size < 5 * 1024 * 1024'));
      expect(storageRules, contains("request.resource.contentType.matches('image/.*')"));

      expect(storageRules, contains('match /posts/{spaceSlug}/{allPaths=**}'));
      expect(storageRules, contains('request.resource.size < 10 * 1024 * 1024'));

      expect(storageRules, contains('match /feedback/{allPaths=**}'));
      expect(storageRules, contains('allow read: if false;'));

      expect(storageRules, contains('match /diagnostics/{allPaths=**}'));
      expect(storageRules, contains('request.resource.size < 2 * 1024 * 1024'));

      // Default deny
      expect(storageRules, contains('match /{allPaths=**}'));
      expect(storageRules, contains('allow read, write: if false;'));
    });
  });

  group('firebase.json multi-service configuration (#620)', () {
    test('links both firestore and storage security rules', () {
      final config = jsonDecode(firebaseConfig) as Map<String, dynamic>;
      expect(config['firestore'], isNotNull);
      expect(config['firestore']['rules'], equals('firestore.rules'));
      expect(config['storage'], isNotNull);
      expect(config['storage']['rules'], equals('storage.rules'));
    });
  });

  group('soft-launch guest re-audit', () {
    test('preview guest invites stay closed to clients', () {
      final invites = firestoreRules
          .split('match /stream_call_invites/{inviteId}')
          .last
          .split('match /stream_call_guests')
          .first;
      final guests = firestoreRules.split('match /stream_call_guests/{callId}').last;
      expect(invites, contains('allow read, write: if false'));
      expect(guests, contains('match /sessions/{guestUserId}'));
      expect(guests, contains('allow read, write: if false'));
      expect(firestoreRules, contains('match /stream_guest_request_limits/{bucket}'));
      expect(firestoreRules, isNot(contains('allow read: if true')));
    });

    test('keeps guest and anonymous sessions off every fellowship path', () {
      expect(firestoreRules, isNot(contains('allow read: if true')));
      expect(firestoreRules, isNot(contains('allow write: if true')));
      expect(firestoreRules, isNot(contains('allow read, write: if true')));
      expect(firestoreRules, isNot(contains('allow read, write: if isSignedInMember();')));
      expect(storageRules, contains('allow read, write: if false;'));
    });

    test('vote board cannot be deleted and feedback cannot be filed as someone else', () {
      expect(firestoreRules, contains('match /feature_votes/{featureId}'));
      // #733 replaced the blanket read/create/update allow with voterIds checks.
      expect(firestoreRules, contains('function featureVoteUpvote()'));
      expect(firestoreRules, contains('allow read: if isSignedInMember();'));
      expect(firestoreRules, contains('allow delete: if false;'));
      expect(
        firestoreRules,
        contains("request.resource.data.get('userId', '') == request.auth.uid"),
      );
    });

    test('admin ban writes require rules_admins and omit new email fields', () {
      expect(firestoreRules, contains('function isRulesAdmin()'));
      expect(
        firestoreRules,
        contains('exists(/databases/\$(database)/documents/rules_admins/\$(request.auth.uid))'),
      );
      expect(firestoreRules, contains('match /rules_admins/{adminId}'));
      expect(firestoreRules, isNot(contains('request.auth.token.email != null')));
      expect(firestoreRules, contains('function banCreateOmitsEmail()'));
      expect(firestoreRules, contains('allow create: if isRulesAdmin() && banCreateOmitsEmail();'));
      expect(firestoreRules, contains('allow update: if isRulesAdmin() && banEmailUnchanged();'));
    });

    test('member-readable profiles cannot gain an email or push token', () {
      expect(firestoreRules, contains('function profileCreateOmitsSecrets()'));
      expect(firestoreRules, contains('function profileSecretsUnchanged()'));
      expect(firestoreRules, contains("request.resource.data.get('email', null) == null"));
      expect(firestoreRules, contains("request.resource.data.get('fcmToken', null) == null"));
      expect(firestoreRules, contains('match /notification_settings/{docId}'));
      expect(firestoreRules, contains('match /saved_posts/{postId}'));
    });

    test('direct messages stay participant-only and a standing ban can erase them', () {
      expect(firestoreRules, contains('request.auth.uid in resource.data.participantIds'));
      expect(firestoreRules, contains('request.auth.uid in request.resource.data.participantIds'));
      expect(firestoreRules, contains('allow update: if false;'));
      expect(firestoreRules, contains('allow delete: if isSignedInMember() && authorIsBanned();'));
      expect(firestoreRules, contains('allow list: if false;'));
    });

    test('a standing ban can delete reflections and comments', () {
      expect(firestoreRules, contains('function standingBan(docId)'));
      expect(firestoreRules, contains('function namedAuthorIsBanned()'));
      expect(firestoreRules, contains('function authorIsBanned()'));
      expect(firestoreRules, contains('isAuthorOf(resource.data) || authorIsBanned()'));
      expect(
        firestoreRules,
        contains("request.auth.uid == resource.data.get('authorId', null) || authorIsBanned()"),
      );
    });
  });
}
