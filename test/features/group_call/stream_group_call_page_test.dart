import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_token_client.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/stream_call_credentials.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/stream_group_call_page.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

void main() {
  final guestUserId = 'g${'a' * 32}';
  const guestToken = 'aaa.bbb.ccc';

  test('a guest connects as a regular Stream user with the server token', () {
    final plan = streamCallConnectPlan(
      credentials: StreamCallCredentials(
        apiKey: 'public-key',
        token: guestToken,
        userId: guestUserId,
        callId: 'monthly',
        expiresAt: 30,
        role: 'guest',
        displayName: 'Alex',
      ),
      displayName: 'Fellow Member',
    );

    expect(plan.user.type, UserType.authenticated);
    expect(plan.user.id, guestUserId);
    expect(plan.user.name, 'Alex');
    expect(plan.userToken, guestToken);
    expect(plan.apiKey, 'public-key');
    expect(plan.callId, 'monthly');
    expect(plan.cameraStartsEnabled, isFalse);
    expect(plan.microphoneStartsEnabled, isFalse);
  });

  test('a member connects as a regular Stream user with the server token', () {
    const memberId = 'member1';
    const memberToken = 'ddd.eee.fff';
    final plan = streamCallConnectPlan(
      credentials: const StreamCallCredentials(
        apiKey: 'public-key',
        token: memberToken,
        userId: memberId,
        callId: 'monthly',
        expiresAt: 30,
      ),
      displayName: 'Fellow Member',
    );

    expect(plan.user.type, UserType.authenticated);
    expect(plan.user.id, memberId);
    expect(plan.user.name, 'Fellow Member');
    expect(plan.userToken, memberToken);
    expect(plan.cameraStartsEnabled, isFalse);
    expect(plan.microphoneStartsEnabled, isFalse);
  });

  testWidgets('the call page applies the server guest id and token', (tester) async {
    StreamCallConnectPlan? plan;
    await tester.pumpWidget(
      MaterialApp(
        home: StreamGroupCallPage(
          credentials: StreamCallCredentials(
            apiKey: 'public-key',
            token: guestToken,
            userId: guestUserId,
            callId: 'monthly',
            expiresAt: 30,
            role: 'guest',
            displayName: 'Alex',
          ),
          displayName: 'Fellow Member',
          tokenClient: _IdleTokens(),
          openConnection: (built) async {
            plan = built;
          },
        ),
      ),
    );
    await tester.pump();

    expect(plan, isNotNull);
    expect(plan!.user.type, UserType.authenticated);
    expect(plan!.user.id, guestUserId);
    expect(plan!.user.name, 'Alex');
    expect(plan!.userToken, guestToken);
    expect(plan!.apiKey, 'public-key');
    expect(find.textContaining('unit-test-stream-secret'), findsNothing);
  });

  testWidgets('closing during connect releases the seat after the join finishes', (tester) async {
    final gate = Completer<void>();
    final order = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: StreamGroupCallPage(
          credentials: StreamCallCredentials(
            apiKey: 'public-key',
            token: guestToken,
            userId: guestUserId,
            callId: 'monthly',
            expiresAt: 30,
            role: 'guest',
            displayName: 'Alex',
            seatKey: 's' * 43,
          ),
          displayName: 'Fellow Member',
          tokenClient: _OrderTokens(order),
          openConnection: (_) async {
            order.add('join');
            await gate.future;
            order.add('joined');
          },
        ),
      ),
    );
    await tester.pump();
    expect(order, ['join']);

    await tester.pumpWidget(const SizedBox.shrink());
    order.add('disposed');
    gate.complete();
    await tester.pump();

    expect(order, ['join', 'disposed', 'joined', 'release', 'close']);
  });
}

class _OrderTokens implements GroupCallTokenSource {
  _OrderTokens(this.order);

  final List<String> order;

  @override
  Future<StreamCallCredentials> mint({required String callId}) async {
    throw const StreamTokenException('not used');
  }

  @override
  Future<void> release() async {
    order.add('release');
  }

  @override
  void close() {
    order.add('close');
  }
}

class _IdleTokens implements GroupCallTokenSource {
  @override
  Future<StreamCallCredentials> mint({required String callId}) async {
    throw const StreamTokenException('not used');
  }

  @override
  Future<void> release() async {}

  @override
  void close() {}
}
