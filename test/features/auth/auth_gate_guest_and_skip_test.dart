import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/auth_gate.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/guest_invite.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/presentation/sensory_theme_controller.dart';
import 'package:refuge4serverpod/src/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileStorageService.instance.clear();
  });

  tearDown(ProfileStorageService.instance.clear);

  const invite = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  Widget gate({
    required AuthRepository auth,
    bool preview = false,
    Uri? location,
    GuestInviteSignals? signals,
  }) {
    final themes = ThemeNotifier();
    addTearDown(themes.dispose);
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        appFlavorProvider.overrideWithValue(AppFlavor.dev),
        authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
      ],
      child: MaterialApp(
        home: AuthGate(
          repository: LocalPostRepository(initialPosts: []),
          themeNotifier: themes,
          groupCallPreviewCompiled: preview,
          groupCallLocation: location,
          inviteSignals: signals,
        ),
      ),
    );
  }

  test('magic-link redirects stay on the flavor host', () {
    expect(AppFlavor.dev.magicLinkRedirectUrl, 'https://dev-belongonthespectrum.web.app/auth');
    expect(AppFlavor.prod.magicLinkRedirectUrl, 'https://belongonthespectrum.web.app/auth');
    expect(AppFlavor.stg.magicLinkRedirectUrl, 'https://stg-belongonthespectrum.web.app/auth');
    expect(AppFlavor.fromString('nope'), AppFlavor.dev);
    expect(AppFlavor.dev.displayName, isNotEmpty);
    expect(AppFlavor.marketingWebsiteUrl, 'https://www.belongonthespectrum.com/');
  });

  testWidgets('an invite link opens the guest name page and a call name does not', (tester) async {
    final signals = GuestInviteSignals();
    addTearDown(signals.dispose);
    await tester.pumpWidget(gate(auth: InMemoryAuthRepository(), preview: true, signals: signals));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsOneWidget);

    signals.present(Uri.parse('https://dev-belongonthespectrum.web.app/?call=monthly'));
    await tester.pump();
    expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsOneWidget);

    signals.present(
      Uri.parse('https://dev-belongonthespectrum.web.app/?call=monthly&invite=$invite'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_call_guest_name_field')), findsOneWidget);
    expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsNothing);
  });

  testWidgets('Skip for now leaves the first-visit card and opens home', (tester) async {
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
    await tester.pumpWidget(gate(auth: InMemoryAuthRepository(initialSession: session)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first_visit_welcome_screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('first_visit_skip_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first_visit_welcome_screen')), findsNothing);
    expect(find.byType(RefugeHomeScreen), findsOneWidget);
    expect(find.text('Belong'), findsWidgets);
  });
}
