import 'package:test/test.dart';
import 'package:sanctuary_server_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ReflectionEndpoint calm-tech domain logic', (
    sessionBuilder,
    endpoints,
  ) {
    test(
      'when publishing reflection with manipulative urgency keywords then ArgumentError is thrown',
      () async {
        final urgentPost = ReflectionPost(
          authorName: 'Test Author',
          spaceKey: 'quiet_room',
          intentTag: 'Quiet Reflection',
          content: 'Breaking news! Urgent announcement, act now!',
          createdAt: DateTime.now().toUtc(),
          prayingCount: 0,
          standingWithCount: 0,
          peaceCount: 0,
          encouragedCount: 0,
        );

        expect(
          () => endpoints.reflection.publishReflection(
            sessionBuilder,
            urgentPost,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'when requesting getQuietDigest on space then returns computed server aggregation',
      () async {
        final digest = await endpoints.reflection.getQuietDigest(
          sessionBuilder,
          'quiet_room',
        );

        expect(digest.spaceKey, 'quiet_room');
        expect(digest.totalReflections, greaterThanOrEqualTo(0));
        expect(digest.totalCareAffirmations, greaterThanOrEqualTo(0));
        expect(digest.summaryMessage, isNotEmpty);
      },
    );
  });
}
