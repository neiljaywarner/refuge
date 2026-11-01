import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/resilient_feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/vote_storage_service.dart';

void main() {
  setUp(() {
    VoteStorageService.instance.clear();
  });

  group('ResilientFeatureVotingRepository (tri-backend UX)', () {
    test('cloud targets wrap Firebase while preserving BackendTarget label', () {
      for (final target in [
        BackendTarget.firebase,
        BackendTarget.appwrite,
        BackendTarget.serverpod,
      ]) {
        final container = ProviderContainer(
          overrides: [featureVotingBackendTargetProvider.overrideWithValue(target)],
        );
        addTearDown(container.dispose);
        final repo = container.read(featureVotingRepositoryProvider);
        expect(repo.target, target);
        expect(repo, isA<ResilientFeatureVotingRepository>());
      }
    });

    test('mirror hook failures do not revert an optimistic vote', () async {
      var mirrorCalls = 0;
      final repo = ResilientFeatureVotingRepository(
        target: BackendTarget.firebase,
        primary: FirebaseFeatureVotingRepository(memberId: () => 'member-uid'),
        mirrorAfterPersist: ({required featureId, required votes, required voterIds}) async {
          mirrorCalls++;
          throw StateError('Appwrite mirror down');
        },
      );

      final initial = repo.loadInitialFeatures();
      final next = repo.toggleVote(initial, 'planned-native-store-apps');
      await Future<void>.delayed(Duration.zero);

      final voted = next.firstWhere((item) => item.id == 'planned-native-store-apps');
      expect(voted.userVoted, isTrue);
      expect(voted.votes, 1);
      expect(mirrorCalls, 1);
      expect(VoteStorageService.instance.isFeatureVoted('planned-native-store-apps'), isTrue);
    });
  });
}
