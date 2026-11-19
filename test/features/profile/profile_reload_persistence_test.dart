import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/config/preview_mode_provider.dart';
import 'package:refuge4serverpod/src/core/firebase/organizer_remote_config_service.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/profile/data/member_profile_cloud_store.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';

class _MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class _MockFirebaseApp extends Mock implements FirebaseApp {}

class _MockFirebaseOptions extends Mock implements FirebaseOptions {}

class _MockUser extends Mock implements fb.User {}

const _church = 'I am not a member of an ICOC church';

class _HoldCloudStore implements MemberProfileCloudStore {
  _HoldCloudStore(this.inner);

  final MemoryMemberProfileCloudStore inner;
  final Completer<void> gate = Completer<void>();

  @override
  Future<void> merge(String uid, MemberProfileCloudFields fields) => inner.merge(uid, fields);

  @override
  Future<MemberProfileCloudFields?> load(String uid) async {
    await gate.future;
    return inner.load(uid);
  }
}

void _stubFirebaseUser(_MockFirebaseAuth auth, _MockUser user) {
  final app = _MockFirebaseApp();
  final options = _MockFirebaseOptions();
  when(() => options.apiKey).thenReturn('belong-test-api-key-0123456789');
  when(() => app.options).thenReturn(options);
  when(() => auth.app).thenReturn(app);
  when(() => user.uid).thenReturn('uid-member');
  when(() => user.email).thenReturn('member@belongonthespectrum.com');
  when(() => user.displayName).thenReturn('David M.');
  when(() => user.isAnonymous).thenReturn(false);
  when(() => user.emailVerified).thenReturn(true);
  when(() => user.photoURL).thenReturn(null);
  when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
  when(() => auth.signOut()).thenAnswer((_) async {});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryMemberProfileCloudStore cloud;
  late MemberProfileCloudStore previousCloud;

  setUp(() {
    previousCloud = ProfileStorageService.cloudStore;
    cloud = MemoryMemberProfileCloudStore();
    ProfileStorageService.cloudStore = cloud;
    ProfileStorageService.instance.clear();
    FirebaseAuthRepository.debugClearSavedSession();
  });

  tearDown(() async {
    ProfileStorageService.cloudStore = previousCloud;
    ProfileStorageService.instance.clear();
    FirebaseAuthRepository.debugClearSavedSession();
    final cleanup = ProviderContainer(
      overrides: [
        authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        organizerRemoteConfigProvider.overrideWithValue(
          OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong()),
        ),
      ],
    );
    await cleanup.read(memberProfileProvider.notifier).signOut();
    cleanup.dispose();
  });

  List<Override> previewOverrides({AuthRepository? repository}) => [
    authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
    organizerRemoteConfigProvider.overrideWithValue(
      OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong()),
    ),
    if (repository != null) authRepositoryProvider.overrideWithValue(repository),
  ];

  test(
    'reload restores church and preview from users/{firebaseUid} when local storage is gone',
    () async {
      final auth = _MockFirebaseAuth();
      final user = _MockUser();
      final app = _MockFirebaseApp();
      final options = _MockFirebaseOptions();
      when(() => options.apiKey).thenReturn('belong-test-api-key-0123456789');
      when(() => app.options).thenReturn(options);
      when(() => auth.app).thenReturn(app);
      when(() => user.uid).thenReturn('uid-member');
      when(() => user.email).thenReturn('member@belongonthespectrum.com');
      when(() => user.displayName).thenReturn('David M.');
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.emailVerified).thenReturn(true);
      when(() => user.photoURL).thenReturn(null);
      when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.signOut()).thenAnswer((_) async {});
      when(() => auth.authStateChanges())
          .thenAnswer((_) => Stream<fb.User?>.fromFuture(Future<fb.User?>.value(user)));

      final repo = FirebaseAuthRepository(firebaseAuth: auth, flavor: AppFlavor.dev);
      final container = ProviderContainer(overrides: previewOverrides(repository: repo));
      addTearDown(container.dispose);

      container
          .read(memberProfileProvider.notifier)
          .signIn(
            displayName: 'David M.',
            email: 'member@belongonthespectrum.com',
            icocChurchAffiliation: _church,
          );
      container.read(memberProfileProvider.notifier).persistPreviewFeatures(true);

      expect(container.read(memberProfileProvider).userId, 'uid-member');
      expect(cloud.documents['uid-member']?['icocChurchAffiliation'], _church);
      expect(cloud.documents['uid-member']?['previewFeaturesEnabled'], isTrue);

      // Page reload: Auth's in-memory church copy and the local blob are both gone.
      // The Firestore user document is the copy that must come back.
      await repo.signOut();
      when(() => auth.currentUser).thenReturn(user);
      ProfileStorageService.instance.clear();
      FirebaseAuthRepository.debugClearSavedSession();

      final reloadedRepo = FirebaseAuthRepository(firebaseAuth: auth, flavor: AppFlavor.dev);
      final reloaded = ProviderContainer(overrides: previewOverrides(repository: reloadedRepo));
      addTearDown(reloaded.dispose);

      await reloaded.read(memberProfileProvider.notifier).cloudHydration;

      expect(reloaded.read(memberProfileProvider).icocChurchAffiliation, _church);
      expect(reloaded.read(previewFeaturesEnabledProvider), isTrue);
      expect(reloaded.read(memberProfileProvider).userId, 'uid-member');
    },
  );

  test('restoring church does not write Auth default bio back to users/{uid}', () async {
    cloud.documents['uid-member'] = {
      'bio': 'Quiet walks and prayer.',
      'comfortBadges': const ['Literal communication appreciated'],
      'icocChurchAffiliation': _church,
      'previewFeaturesEnabled': true,
    };
    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    _stubFirebaseUser(auth, user);
    when(() => auth.currentUser).thenReturn(user);
    when(() => auth.authStateChanges())
        .thenAnswer((_) => Stream<fb.User?>.fromFuture(Future<fb.User?>.value(user)));

    final reloaded = ProviderContainer(
      overrides: previewOverrides(
        repository: FirebaseAuthRepository(firebaseAuth: auth, flavor: AppFlavor.dev),
      ),
    );
    addTearDown(reloaded.dispose);

    await reloaded.read(memberProfileProvider.notifier).cloudHydration;

    expect(reloaded.read(memberProfileProvider).icocChurchAffiliation, _church);
    expect(cloud.documents['uid-member']?['bio'], 'Quiet walks and prayer.');
    expect(cloud.documents['uid-member']?['comfortBadges'], ['Literal communication appreciated']);
  });

  test('hydration runs when auth signs in after the profile built as a guest', () async {
    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    final sessions = StreamController<fb.User?>.broadcast();
    addTearDown(sessions.close);
    _stubFirebaseUser(auth, user);
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.authStateChanges()).thenAnswer((_) => sessions.stream);
    cloud.documents['uid-member'] = {
      'icocChurchAffiliation': _church,
      'previewFeaturesEnabled': true,
    };

    final container = ProviderContainer(
      overrides: previewOverrides(
        repository: FirebaseAuthRepository(firebaseAuth: auth, flavor: AppFlavor.dev),
      ),
    );
    addTearDown(container.dispose);

    expect(container.read(memberProfileProvider).isSignedIn, isFalse);
    await container.read(memberProfileProvider.notifier).cloudHydration;

    when(() => auth.currentUser).thenReturn(user);
    sessions.add(user);
    // Broadcast auth events are delivered on a later microtask, which is when
    // the signed-in hydration flight replaces the guest one.
    await Future<void>.delayed(Duration.zero);
    await container.read(memberProfileProvider.notifier).cloudHydration;

    expect(container.read(memberProfileProvider).icocChurchAffiliation, _church);
    expect(container.read(previewFeaturesEnabledProvider), isTrue);
  });

  patrolWidgetTest('preview switch saves without a church answer and stays on after reload', (
    $,
  ) async {
    $.tester.view.devicePixelRatio = 1.0;
    $.tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(overrides: previewOverrides());
    addTearDown(container.dispose);

    container
        .read(memberProfileProvider.notifier)
        .signIn(displayName: 'David M.', email: 'member@belongonthespectrum.com');

    await $.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MemberProfileDialog())),
      ),
    );
    await $.pumpAndSettle();

    await $(const Key('preview_mode_switch')).scrollTo();
    await $(const Key('preview_mode_switch')).tap();
    await $.pumpAndSettle();

    await $(const Key('profile_save_sign_in_button')).tap();
    await $.pumpAndSettle();

    expect($(const Key('profile_affiliation_error_text')), findsOneWidget);
    expect(container.read(memberProfileProvider).icocChurchAffiliation, isNull);
    expect(container.read(previewFeaturesEnabledProvider), isTrue);

    final reloaded = ProviderContainer(overrides: previewOverrides());
    addTearDown(reloaded.dispose);
    await $.pumpWidget(
      UncontrolledProviderScope(
        container: reloaded,
        child: const MaterialApp(home: Scaffold(body: MemberProfileDialog())),
      ),
    );
    await reloaded.read(memberProfileProvider.notifier).cloudHydration;
    await $.pumpAndSettle();

    expect(reloaded.read(previewFeaturesEnabledProvider), isTrue);
    final tile = $.tester.widget<SwitchListTile>(find.byKey(const Key('preview_mode_switch')));
    expect(tile.value, isTrue);
    expect(find.text(_church), findsNothing);
  });

  patrolWidgetTest('an open profile dialog shows the church answer when cloud restore finishes', (
    $,
  ) async {
    $.tester.view.devicePixelRatio = 1.0;
    $.tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });

    final held = _HoldCloudStore(cloud);
    held.inner.documents['uid-member'] = {'icocChurchAffiliation': _church};
    ProfileStorageService.cloudStore = held;

    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    _stubFirebaseUser(auth, user);
    when(() => auth.currentUser).thenReturn(user);
    when(() => auth.authStateChanges())
        .thenAnswer((_) => Stream<fb.User?>.fromFuture(Future<fb.User?>.value(user)));

    final container = ProviderContainer(
      overrides: previewOverrides(
        repository: FirebaseAuthRepository(firebaseAuth: auth, flavor: AppFlavor.dev),
      ),
    );
    addTearDown(container.dispose);
    container.read(memberProfileProvider);

    await $.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MemberProfileDialog())),
      ),
    );
    await $.pump();

    expect(find.byKey(const Key('profile_church_affiliation_dropdown')), findsOneWidget);
    expect(
      $.tester
          .widget<TextFormField>(find.byKey(const Key('profile_church_affiliation_dropdown')))
          .controller!
          .text,
      isEmpty,
    );

    held.gate.complete();
    await container.read(memberProfileProvider.notifier).cloudHydration;
    await $.pump();

    expect(
      $.tester
          .widget<TextFormField>(find.byKey(const Key('profile_church_affiliation_dropdown')))
          .controller!
          .text,
      _church,
    );
  });
}
