import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_and_voting_models.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/optional_feedback_contact.dart';
import 'package:refuge4serverpod/src/features/feedback/data/vote_storage_service.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';

class MockFeatureVotingRepository extends Mock implements FeatureVotingRepository {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockVoteCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}

class MockVoteSnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class MockVoteDocument extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FeedbackSentiment.happy);
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<VotableFeatureItem>[]);
    registerFallbackValue(<String, dynamic>{});
  });

  group('BelongFeedbackAndVotingSheet mocked repository', () {
    late MockFeatureVotingRepository repo;
    late InMemoryFeatureVotingRepository memory;
    late StreamController<List<VotableFeatureItem>> updates;

    setUp(() {
      repo = MockFeatureVotingRepository();
      memory = InMemoryFeatureVotingRepository();
      updates = StreamController<List<VotableFeatureItem>>.broadcast();
      when(() => repo.target).thenReturn(BackendTarget.serverpod);
      when(() => repo.loadInitialFeatures()).thenReturn(kDefaultBelongVotableFeatures);
      when(() => repo.watchFeatures()).thenAnswer((_) => updates.stream);
      when(() => repo.toggleVote(any(), any())).thenAnswer((invocation) {
        final current = invocation.positionalArguments[0] as List<VotableFeatureItem>;
        final id = invocation.positionalArguments[1] as String;
        return memory.toggleVote(current, id);
      });
      when(
        () => repo.submitFeedback(
          sentiment: any(named: 'sentiment'),
          message: any(named: 'message'),
          rating: any(named: 'rating'),
          contactEmail: any(named: 'contactEmail'),
          attachmentUrl: any(named: 'attachmentUrl'),
          screenshotAttachment: any(named: 'screenshotAttachment'),
        ),
      ).thenAnswer((_) async => const FeedbackSubmissionResult(isPrivateTriage: false));
    });

    tearDown(() async {
      if (!updates.isClosed) {
        await updates.close();
      }
    });

    Future<void> pumpSheet(PatrolTester $, {int initialTabIndex = 0}) {
      $.tester.view.physicalSize = const Size(1000, 1800);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });
      return $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [featureVotingRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(body: BelongFeedbackAndVotingSheet(initialTabIndex: initialTabIndex)),
          ),
        ),
      );
    }

    patrolWidgetTest(
      'Scenario: empty praise note asks for a short message and does not call the backend',
      ($) async {
        await pumpSheet($, initialTabIndex: 1);
        await $(const Key('submit_feedback_button')).tap();
        await $.pumpAndSettle();

        expect($('Please enter a short note above so we can read your thoughts.'), findsOneWidget);
        verifyNever(
          () => repo.submitFeedback(
            sentiment: any(named: 'sentiment'),
            message: any(named: 'message'),
            rating: any(named: 'rating'),
            contactEmail: any(named: 'contactEmail'),
            attachmentUrl: any(named: 'attachmentUrl'),
            screenshotAttachment: any(named: 'screenshotAttachment'),
          ),
        );
      },
    );

    patrolWidgetTest('Scenario: public praise is recorded on the mocked repository', ($) async {
      await pumpSheet($, initialTabIndex: 1);
      await $(const Key('feedback_message_input'))
          .enterText('The prayer space feels calm and unhurried.');
      await $(const Key('feedback_contact_input')).enterText('member@belongonthespectrum.com');
      await $(const Key('submit_feedback_button')).tap();
      await $.pumpAndSettle();

      expect(
        $(
          'Thank you for your encouragement! Your praise was recorded and shared with our organizers.',
        ),
        findsOneWidget,
      );
      verify(
        () => repo.submitFeedback(
          sentiment: FeedbackSentiment.happy,
          message: 'The prayer space feels calm and unhurried.',
          rating: 5,
          contactEmail: 'member@belongonthespectrum.com',
          attachmentUrl: any(named: 'attachmentUrl'),
          screenshotAttachment: any(named: 'screenshotAttachment'),
        ),
      ).called(1);
    });

    const note = 'The prayer space feels calm and unhurried.';

    patrolWidgetTest('Scenario: a full email contact is accepted with no inline error', ($) async {
      await pumpSheet($, initialTabIndex: 1);
      await $(const Key('feedback_message_input')).enterText(note);
      await $(const Key('feedback_contact_input')).enterText('member@belongonthespectrum.com');
      await $.pumpAndSettle();

      expect($(OptionalFeedbackContact.emailError), findsNothing);

      await $(const Key('submit_feedback_button')).tap();
      await $.pumpAndSettle();

      verify(
        () => repo.submitFeedback(
          sentiment: FeedbackSentiment.happy,
          message: note,
          rating: 5,
          contactEmail: 'member@belongonthespectrum.com',
          attachmentUrl: any(named: 'attachmentUrl'),
          screenshotAttachment: any(named: 'screenshotAttachment'),
        ),
      ).called(1);
    });

    patrolWidgetTest('Scenario: a contact with @ that is not an email is blocked', ($) async {
      await pumpSheet($, initialTabIndex: 1);
      await $(const Key('feedback_message_input')).enterText(note);
      await $(const Key('feedback_contact_input')).enterText('not@email');
      await $.pumpAndSettle();

      expect($(OptionalFeedbackContact.emailError), findsOneWidget);

      await $(const Key('submit_feedback_button')).tap();
      await $.pumpAndSettle();

      expect($(OptionalFeedbackContact.emailError), findsOneWidget);
      expect(
        $(
          'Thank you for your encouragement! Your praise was recorded and shared with our organizers.',
        ),
        findsNothing,
      );
      verifyNever(
        () => repo.submitFeedback(
          sentiment: any(named: 'sentiment'),
          message: any(named: 'message'),
          rating: any(named: 'rating'),
          contactEmail: any(named: 'contactEmail'),
          attachmentUrl: any(named: 'attachmentUrl'),
          screenshotAttachment: any(named: 'screenshotAttachment'),
        ),
      );
    });

    patrolWidgetTest('Scenario: a plain name with no @ is sent as the contact', ($) async {
      await pumpSheet($, initialTabIndex: 1);
      await $(const Key('feedback_message_input')).enterText(note);
      await $(const Key('feedback_contact_input')).enterText('not-an-email');
      await $.pumpAndSettle();

      expect($(OptionalFeedbackContact.emailError), findsNothing);

      await $(const Key('submit_feedback_button')).tap();
      await $.pumpAndSettle();

      verify(
        () => repo.submitFeedback(
          sentiment: FeedbackSentiment.happy,
          message: note,
          rating: 5,
          contactEmail: 'not-an-email',
          attachmentUrl: any(named: 'attachmentUrl'),
          screenshotAttachment: any(named: 'screenshotAttachment'),
        ),
      ).called(1);
    });

    patrolWidgetTest('Scenario: an empty contact is sent as no contact', ($) async {
      await pumpSheet($, initialTabIndex: 1);
      await $(const Key('feedback_message_input')).enterText(note);
      await $.pumpAndSettle();

      expect($(OptionalFeedbackContact.emailError), findsNothing);

      await $(const Key('submit_feedback_button')).tap();
      await $.pumpAndSettle();

      final captured = verify(
        () => repo.submitFeedback(
          sentiment: FeedbackSentiment.happy,
          message: note,
          rating: 5,
          contactEmail: captureAny(named: 'contactEmail'),
          attachmentUrl: any(named: 'attachmentUrl'),
          screenshotAttachment: any(named: 'screenshotAttachment'),
        ),
      ).captured;
      expect(captured.single, isNull);
    });

    patrolWidgetTest('Scenario: a mocked backend failure stays on the sheet with a gentle error', (
      $,
    ) async {
      when(
        () => repo.submitFeedback(
          sentiment: any(named: 'sentiment'),
          message: any(named: 'message'),
          rating: any(named: 'rating'),
          contactEmail: any(named: 'contactEmail'),
          attachmentUrl: any(named: 'attachmentUrl'),
          screenshotAttachment: any(named: 'screenshotAttachment'),
        ),
      ).thenThrow(Exception('offline'));

      await pumpSheet($, initialTabIndex: 1);
      await $(const Key('feedback_message_input')).enterText('The bell label is hard to see.');
      await $(const Key('submit_feedback_button')).tap();
      await $.pumpAndSettle();

      expect($('Could not submit feedback: Exception: offline'), findsOneWidget);
    });

    patrolWidgetTest(
      'Scenario: one star explains the rating and a remote tally keeps the local vote',
      ($) async {
        await pumpSheet($);
        await $(const Key('tab_private_feedback')).tap();
        await $(const Key('star_rating_1')).tap();
        expect($('1 ★ · Broken / Very confusing'), findsOneWidget);
        expect($('What felt broken, confusing, or overwhelming?'), findsOneWidget);

        await $(const Key('tab_feature_voting')).tap();
        await $(const Key('vote_button_planned-native-store-apps')).tap();
        expect(
          find.descendant(
            of: find.byKey(const Key('vote_button_planned-native-store-apps')),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );

        updates.add([
          for (final item in kDefaultBelongVotableFeatures)
            item.id == 'planned-native-store-apps' ? item.copyWith(votes: 6) : item,
        ]);
        await $.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('vote_button_planned-native-store-apps')),
            matching: find.text('6'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('vote_button_planned-native-store-apps')),
            matching: find.byIcon(Icons.thumb_up),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('FirebaseFeatureVotingRepository with a mocked Firestore', () {
    test('watchFeatures applies remote vote counts from a mocked snapshot', () async {
      final firestore = MockFirebaseFirestore();
      final collection = MockVoteCollection();
      final snapshot = MockVoteSnapshot();
      final document = MockVoteDocument();

      when(() => firestore.collection('feature_votes')).thenReturn(collection);
      when(() => collection.snapshots()).thenAnswer((_) => Stream.value(snapshot));
      when(() => snapshot.docs).thenReturn([document]);
      when(() => document.id).thenReturn('planned-native-store-apps');
      when(() => document.data()).thenReturn({'votes': 4, 'voterIds': <String>[]});

      final repo = FirebaseFeatureVotingRepository(customFirestore: firestore);
      final features = await repo.watchFeatures().first;

      final store = features.firstWhere((item) => item.id == 'planned-native-store-apps');
      expect(store.votes, 4);
      expect(features.firstWhere((item) => item.id == 'planned-google-sign-in').votes, 0);
    });

    test('toggleVote and submitFeedback survive a mocked Firestore write', () async {
      VoteStorageService.instance.clear();
      final firestore = MockFirebaseFirestore();
      final collection = MockVoteCollection();
      final document = _MockDocumentReference();

      when(() => firestore.collection(any())).thenReturn(collection);
      when(() => collection.doc(any())).thenReturn(document);
      when(() => collection.add(any())).thenAnswer((_) async => document);
      when(() => document.set(any(), any())).thenAnswer((_) async {});

      final repo = FirebaseFeatureVotingRepository(
        customFirestore: firestore,
        memberId: () => null,
      );
      final next = repo.toggleVote(repo.loadInitialFeatures(), 'planned-native-store-apps');
      final voted = next.firstWhere((item) => item.id == 'planned-native-store-apps');
      expect(voted.userVoted, isTrue);
      expect(voted.votes, 1);

      await repo.submitFeedback(
        sentiment: FeedbackSentiment.neutral,
        message: 'Please keep the digest quiet.',
        rating: 3,
        contactEmail: 'member@belongonthespectrum.com',
      );
      expect(repo.submittedFeedbackLog.single['message'], 'Please keep the digest quiet.');
      expect(repo.submittedFeedbackLog.single['rating'], '3');
      expect(repo.submittedFeedbackLog.single['backend'], 'firebase');
    });
  });
}

class _MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
