import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:patrol/patrol.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_token_client.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/stream_call_credentials.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_lobby.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_session_controls.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';

import 'patrol_app_harness.dart';

/// Headless emulator journeys. They pump the app with a local repository.
///
/// Screen sharing is not on main. The in-call Start and Stop covered here are
/// the microphone and the camera, which a preview join leaves off.
///
/// ```bash
/// adb shell settings put system font_scale 2.0
/// patrol test --target integration_test/coverage_journeys_patrol_test.dart
/// adb shell settings put system font_scale 1.0
/// ```
void main() {
  patrolTest('sign-in wall, guest skip, large-text home, composer, and a muted call', ($) async {
    ProfileStorageService.instance.clear();
    addTearDown(ProfileStorageService.instance.clear);

    await $.pumpWidgetAndSettle(
      RefugeApp(
        repository: LocalPostRepository(initialPosts: []),
        enforceSignIn: true,
        overrides: [
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      ),
    );
    expect($(const Key('sign_in_title')), findsOneWidget);
    expect($('Skip for now'), findsNothing);
    expect($(const Key('reflection_composer_input')), findsNothing);

    final session = AuthSession(
      userId: 'member-1',
      displayName: 'Fellowship Member',
      email: 'member@belongonthespectrum.com',
      bio: 'Exploring Belong on the Spectrum',
      comfortBadges: const ['Literal communication appreciated'],
      isSignedIn: true,
      authMethod: 'in_memory_password',
      emailVerified: true,
    );
    await $.pumpWidgetAndSettle(
      RefugeApp(
        repository: LocalPostRepository(initialPosts: []),
        enforceSignIn: true,
        overrides: [
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository(initialSession: session)),
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      ),
    );
    expect($(const Key('first_visit_skip_button')), findsOneWidget);
    await $(const Key('first_visit_skip_button')).tap();
    expect($(const Key('first_visit_welcome_screen')), findsNothing);

    $.tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown($.tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpDevReadOnlyHome($);
    expect($('Belong'), findsWidgets);
    expect($(const Key('subnav_spaces_tab')), findsOneWidget);
    await $(const Key('subnav_spaces_tab')).tap();
    expect($(const Key('belong_spaces_directory_list')), findsOneWidget);
    await $('Feed').tap();

    await $.tester.scrollUntilVisible(
      find.byKey(const Key('reflection_composer_input')),
      400,
      scrollable: find.descendant(
        of: find.byKey(const Key('home_feed_scroll')),
        matching: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
        ),
      ),
    );
    expect($(const Key('reflection_composer_input')), findsOneWidget);
    await $(const Key('composer_expand_button')).tap();
    expect($(const Key('composer_collapse_button')), findsOneWidget);
    await $(const Key('composer_collapse_button')).tap();
    expect($(const Key('composer_expand_button')), findsOneWidget);

    var joined = false;
    await $.pumpWidgetAndSettle(
      MaterialApp(
        home: GroupCallLobbyPage(
          displayName: 'David M.',
          initialCallId: 'monthly',
          tokenClientFactory: () => _ScriptedTokenClient(),
          onReady:
              (
                context, {
                required room,
                required credentials,
                required displayName,
                required tokenClient,
              }) async {
                joined = true;
                expect(room.id, 'monthly');
                expect(credentials.token, 'aaa.bbb.ccc');
              },
        ),
      ),
    );
    expect($('You join with your microphone and camera off.'), findsOneWidget);
    await $(const Key('group_call_confirm_join_button')).tap();
    await $.pumpAndSettle();
    expect(joined, isTrue);

    var microphone = false;
    var camera = false;
    await $.pumpWidgetAndSettle(
      MaterialApp(
        home: Scaffold(
          body: GroupCallSessionControls(
            microphoneEnabled: false,
            cameraEnabled: false,
            host: false,
            onMicrophone: () => microphone = !microphone,
            onCamera: () => camera = !camera,
            onLeave: () async {},
            onRemove: (_) async {},
            onEnd: () async {},
          ),
        ),
      ),
    );
    expect($(const Key('group_call_microphone_button')), findsOneWidget);
    expect($(const Key('group_call_camera_button')), findsOneWidget);
    expect($('Start screen share'), findsNothing);
    await $(const Key('group_call_microphone_button')).tap();
    await $(const Key('group_call_camera_button')).tap();
    await $(const Key('group_call_microphone_button')).tap();
    await $(const Key('group_call_camera_button')).tap();
    expect(microphone, isFalse);
    expect(camera, isFalse);
  });
}

class _ScriptedTokenClient extends StreamTokenClient {
  _ScriptedTokenClient()
    : super(
        endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
        httpClient: _UnusedClient(),
        readIdToken: () async => 'member-id-token',
      );

  @override
  Future<StreamCallCredentials> mint({required String callId}) async => const StreamCallCredentials(
    apiKey: 'public-key',
    token: 'aaa.bbb.ccc',
    userId: 'member-1',
    callId: 'monthly',
    expiresAt: 30,
  );

  @override
  void close() {}
}

class _UnusedClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('This lobby test does not send HTTP.');
  }
}
