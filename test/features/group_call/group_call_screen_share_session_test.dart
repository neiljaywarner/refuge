import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_screen_share_session.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class _MockCall extends Mock implements Call {}

void main() {
  test('web share calls setScreenShareEnabled and nothing else', () async {
    final call = _MockCall();
    final enabled = <bool>[];
    when(
      () => call.setScreenShareEnabled(
        enabled: any(named: 'enabled'),
        constraints: any(named: 'constraints'),
      ),
    ).thenAnswer((invocation) async {
      enabled.add(invocation.namedArguments[#enabled]! as bool);
      return const Result.success(none);
    });

    final started = await setGroupCallScreenShare(
      call,
      enabled: true,
      platform: GroupCallSharePlatform.web,
    );
    final stopped = await setGroupCallScreenShare(
      call,
      enabled: false,
      platform: GroupCallSharePlatform.web,
    );

    expect(started.isSuccess, isTrue);
    expect(stopped.isSuccess, isTrue);
    expect(enabled, [true, false]);
    verifyNever(() => call.requestScreenSharePermission());
  });

  test('iOS does not start a share', () async {
    final call = _MockCall();
    final result = await setGroupCallScreenShare(
      call,
      enabled: true,
      platform: GroupCallSharePlatform.ios,
    );
    expect(result.isFailure, isTrue);
    verifyNever(
      () => call.setScreenShareEnabled(
        enabled: any(named: 'enabled'),
        constraints: any(named: 'constraints'),
      ),
    );
  });

  test(
    'Android starts the projection service and stops it if publish fails',
    () async {
      final call = _MockCall();
      when(() => call.callCid)
          .thenReturn(StreamCallCid(cid: 'default:monthly'));
      when(
        () => call.setScreenShareEnabled(
          enabled: any(named: 'enabled'),
          constraints: any(named: 'constraints'),
        ),
      ).thenAnswer((_) async => Result<None>.error('capture failed'));
      final events = <String>[];
      final hooks = GroupCallAndroidShareHooks(
        requestConsent: (call) async {
          events.add('consent');
          return true;
        },
        startNotification: (call) async {
          events.add('start');
          return true;
        },
        stopNotification: (callCid) async {
          events.add('stop:$callCid');
        },
      );

      final result = await setGroupCallScreenShare(
        call,
        enabled: true,
        platform: GroupCallSharePlatform.android,
        android: hooks,
      );

      expect(result.isFailure, isTrue);
      expect(events, ['consent', 'start', 'stop:default:monthly']);
    },
  );

  test('Android stop clears the track and the foreground service', () async {
    final call = _MockCall();
    when(() => call.callCid).thenReturn(StreamCallCid(cid: 'default:monthly'));
    when(
      () => call.setScreenShareEnabled(
        enabled: any(named: 'enabled'),
        constraints: any(named: 'constraints'),
      ),
    ).thenAnswer((_) async => const Result.success(none));
    final events = <String>[];
    final hooks = GroupCallAndroidShareHooks(
      requestConsent: (call) async => fail('consent'),
      startNotification: (call) async => fail('start'),
      stopNotification: (callCid) async => events.add('stop'),
    );

    final result = await setGroupCallScreenShare(
      call,
      enabled: false,
      platform: GroupCallSharePlatform.android,
      android: hooks,
    );

    expect(result.isSuccess, isTrue);
    expect(events, ['stop']);
  });

  test('a cancelled Android dialog does not start the service', () async {
    final call = _MockCall();
    final events = <String>[];
    final hooks = GroupCallAndroidShareHooks(
      requestConsent: (call) async {
        events.add('consent');
        return false;
      },
      startNotification: (call) async {
        events.add('start');
        return true;
      },
      stopNotification: (callCid) async => events.add('stop'),
    );

    final result = await setGroupCallScreenShare(
      call,
      enabled: true,
      platform: GroupCallSharePlatform.android,
      android: hooks,
    );

    expect(result.isFailure, isTrue);
    expect(events, ['consent']);
    verifyNever(
      () => call.setScreenShareEnabled(
        enabled: any(named: 'enabled'),
        constraints: any(named: 'constraints'),
      ),
    );
  });
}
