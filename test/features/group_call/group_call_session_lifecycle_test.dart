import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_session_lifecycle.dart';

void main() {
  test('shutdown during connect leaves the call before releasing the seat', () async {
    final order = <String>[];
    final gate = Completer<void>();
    final life = GroupCallSessionLifecycle();
    final connect = life.connect(
      join: () async {
        order.add('join');
        await gate.future;
        order.add('joined');
        return true;
      },
      leave: () async {
        order.add('leave');
      },
      onReady: () {
        order.add('ready');
      },
      onFailure: () async {
        order.add('fail');
      },
    );
    final shut = life.shutdown(
      leave: () async {
        order.add('leave-held');
      },
      release: () async {
        order.add('release');
      },
    );
    expect(order, ['join']);
    gate.complete();
    await Future.wait([connect, shut]);
    expect(order, ['join', 'joined', 'leave', 'release']);
  });

  test('a connected call is left and then the seat is released', () async {
    final order = <String>[];
    final life = GroupCallSessionLifecycle();
    await life.connect(
      join: () async => true,
      leave: () async {
        order.add('leave');
      },
      onReady: () {
        order.add('ready');
      },
      onFailure: () async {},
    );
    await life.shutdown(
      leave: () async {
        order.add('leave-held');
      },
      release: () async {
        order.add('release');
      },
    );
    expect(order, ['ready', 'leave-held', 'release']);
  });
}
