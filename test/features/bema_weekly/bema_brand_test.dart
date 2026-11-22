import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/simple_sign_in_screen.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/branding/presentation/brand_config_provider.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

void main() {
  test('the default compilation stays the Belong brand', () {
    expect(kIsBemaBrand, isFalse);
    expect(CommunityBrandConfig.resolve().fullName, 'Belong on the Spectrum');
    expect(const CommunityBrandConfig.bema().visibleSpaceSlugs, [
      'study',
      'prayer',
      'resources_videos',
    ]);
  });

  testWidgets('bema brand home and sign-in do not say Belong', (tester) async {
    const brand = CommunityBrandConfig.bema();
    final repository = LocalPostRepository(isDevMode: false);
    await repository.getPosts(spaceKey: 'study');
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> expectClean(String surface) async {
      final forbidden = RegExp(r'belong|refuge|autistic|calm tech', caseSensitive: false);
      final texts = <String>[];
      for (final widget in tester.allWidgets) {
        if (widget is Text) {
          final data = widget.data;
          if (data != null) texts.add(data);
          final span = widget.textSpan;
          if (span != null) texts.add(span.toPlainText());
        }
        if (widget is Semantics) {
          final label = widget.properties.label;
          if (label != null) texts.add(label);
        }
      }
      for (final text in texts) {
        expect(forbidden.hasMatch(text), isFalse, reason: '$surface: $text');
      }
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityBrandConfigProvider.overrideWithValue(brand),
          postRepositoryProvider.overrideWithValue(repository),
          appFlavorProvider.overrideWithValue(AppFlavor.dev),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: RefugeHomeScreen(repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('BEMA Discussion Group'), findsWidgets);
    expect(find.text('Vote & Feedback'), findsNothing);
    expect(find.text('Weekly Study'), findsWidgets);
    await expectClean('home');
  });

  testWidgets('bema brand sign-in does not say Belong', (tester) async {
    const brand = CommunityBrandConfig.bema();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityBrandConfigProvider.overrideWithValue(brand),
          appFlavorProvider.overrideWithValue(AppFlavor.dev),
        ],
        child: const MaterialApp(home: SimpleSignInScreen(firebaseReady: false)),
      ),
    );
    await tester.pump();
    expect(find.text('Sign in to BEMA Discussion Group'), findsOneWidget);
    expect(find.textContaining('[DEV]'), findsNothing);
    final forbidden = RegExp(r'belong|refuge|autistic|calm tech', caseSensitive: false);
    for (final widget in tester.allWidgets) {
      if (widget is Text && widget.data != null) {
        expect(forbidden.hasMatch(widget.data!), isFalse, reason: widget.data);
      }
    }
  });
}
