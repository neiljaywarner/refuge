import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a standing ban can erase reflections, comments, and direct messages', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('function standingBan(docId)'));
    expect(rules, contains('function namedAuthorIsBanned()'));
    expect(rules, contains('function authorIsBanned()'));
    expect(rules, contains('function uidBanActive(uid)'));
    expect(rules, contains('match /banned_uids/{uid}'));
    expect(rules, contains("standingBan(resource.data.get('authorName', ''))"));
    expect(rules, contains("standingBan(resource.data.get('senderName', ''))"));
    expect(rules, contains("standingBan(resource.data.get('authorId', ''))"));
    expect(rules, contains("standingBan(resource.data.get('senderId', ''))"));
    expect(
      rules,
      contains("request.auth.uid == resource.data.get('authorId', null) || authorIsBanned()"),
    );
    expect(rules, contains('isAuthorOf(resource.data) || authorIsBanned()'));
    expect(rules, contains('allow delete: if isSignedInMember() && authorIsBanned();'));
    expect(rules, contains('match /reflections/{postId}'));
    expect(rules, contains('match /reflections_dev/{postId}'));
    expect(rules, contains('match /comments/{commentId}'));
    expect(rules, contains('match /comments_dev/{commentId}'));
    expect(rules, contains('match /direct_messages/{messageId}'));
  });
}
