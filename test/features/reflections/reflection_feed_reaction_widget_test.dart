import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/pending_post_outbox.dart';

class _DownMirror implements ReflectionMirror {
  @override
  Future<void> upsertPost(Post post) async => throw StateError('appwrite down');

  @override
  Future<void> incrementReaction({required String postId, required String column}) async =>
      throw StateError('appwrite down');

  @override
  Future<List<Post>> listPosts({required String spaceKey}) async =>
      throw StateError('appwrite down');

  @override
  Stream<Post> watchPosts({required String spaceKey}) => const Stream.empty();

  @override
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  }) async => throw StateError('appwrite down');
}

AuthSession _signedInSession() => AuthSession(
  userId: 'uid-member',
  displayName: 'Rachel S. (Dallas)',
  email: 'member@belongonthespectrum.com',
  bio: 'Fellowship member',
  comfortBadges: const ['Quiet fellowship'],
  isSignedIn: true,
  authMethod: 'in_memory_password',
  emailVerified: true,
);

void main() {
  testWidgets('signed-in feed keeps the Firestore note and Relate returns to 0', (tester) async {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fs = FakeFirebaseFirestore();
    await fs.collection('reflections_dev').doc('post-relate').set({
      'authorName': 'Fellow Member',
      'spaceKey': 'prayer',
      'content': 'A quiet note for the prayer room.',
      'createdAt': '2026-11-10T03:00:00.000Z',
      'toneTag': '[Support]',
      'reactions': {'relatable': 0},
    });
    final repo = AppwritePostRepository(
      isDevMode: true,
      customFirestore: fs,
      mirror: _DownMirror(),
      fallback: LocalPostRepository(isDevMode: false),
      outbox: PendingPostOutbox(environment: 'dev', memory: {}),
    );

    await tester.pumpWidget(
      RefugeApp(
        repository: repo,
        enforceSignIn: true,
        overrides: [
          postRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(
            InMemoryAuthRepository(initialSession: _signedInSession()),
          ),
          appFlavorProvider.overrideWithValue(AppFlavor.dev),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A quiet note for the prayer room.'), findsOneWidget);
    expect(find.byKey(const Key('empty_reflections_placeholder')), findsNothing);

    final relate = find.byKey(const Key('reaction_button_relatable_post-relate'));
    await tester.ensureVisible(relate);
    await tester.tap(relate);
    await tester.pumpAndSettle();
    expect(find.text('1 Relatable'), findsOneWidget);

    await tester.tap(relate);
    await tester.pumpAndSettle();
    expect(find.text('0 Relatable'), findsOneWidget);
    expect(find.text('2 Relatable'), findsNothing);
    expect(find.text('4 Relatable'), findsNothing);
  });
}
