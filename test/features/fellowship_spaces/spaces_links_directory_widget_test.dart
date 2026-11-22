import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/domain/fellowship_space.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void _ignoreSpace(BelongSpaceItem item) {}

class _FakeUrlLauncher extends UrlLauncherPlatform {
  final launched = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launched.add(url);
    return true;
  }
}

void main() {
  late _FakeUrlLauncher launcher;

  setUp(() {
    launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  Future<BelongSpaceItem?> pumpAndTap(WidgetTester tester, String title) async {
    BelongSpaceItem? selected;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BelongSpacesDirectoryView(
              selectedSpaceSlug: 'general_chat',
              onSelectSpaceItem: (item) => selected = item,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LINKS'), findsOneWidget);
    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Coming Soon'), findsWidgets);

    final target = find.text(title);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return selected;
  }

  testWidgets('LINKS rows show external, install, and pending affordances', (tester) async {
    await pumpAndTap(tester, 'General Chat');
    expect(find.byIcon(Icons.open_in_new_rounded), findsWidgets);
    expect(find.byIcon(Icons.menu_book_outlined), findsWidgets);
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
  });

  testWidgets('tapping a fellowship room reports that space', (tester) async {
    final selected = await pumpAndTap(tester, 'General Chat');
    expect(selected?.slug, 'general_chat');
    expect(selected?.isComingSoon, isFalse);
  });

  testWidgets('Community Guidelines stays a pending link for the parent to open', (tester) async {
    final selected = await pumpAndTap(tester, 'Community Guidelines');
    expect(selected?.slug, 'link_community_guidelines');
    expect(selected?.isComingSoon, isTrue);
    expect(selected?.trackedIssueNumber, 29);
  });

  testWidgets('DFW Church shows the opening snackbar and does not select a room', (tester) async {
    final selected = await pumpAndTap(tester, 'DFW Church');
    expect(selected, isNull);
    expect(find.textContaining('Opening DFW Church'), findsOneWidget);
    expect(find.textContaining('https://dfwchurch.org'), findsOneWidget);
    expect(launcher.launched, ['https://dfwchurch.org']);
  });

  testWidgets('Disciples Today opens its own page', (tester) async {
    final selected = await pumpAndTap(tester, 'Disciples Today');
    expect(selected, isNull);
    expect(find.textContaining('Opening Disciples Today'), findsOneWidget);
    expect(launcher.launched, ['https://disciplestoday.org']);
  });

  testWidgets('church links stay at least 48dp from text scale 1 to 3', (tester) async {
    for (final scale in const [1.0, 1.3, 2.0, 3.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: BelongSpacesDirectoryView(
                selectedSpaceSlug: 'general_chat',
                onSelectSpaceItem: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final slug in const ['link_dfw_church', 'link_disciples_today']) {
        final tile = find.byKey(Key('space_tile_$slug'));
        await tester.scrollUntilVisible(tile, 120);
        await tester.pump();
        final rect = tester.getRect(tile);
        expect(rect.height, greaterThanOrEqualTo(48), reason: '$slug scale $scale');
        expect(rect.top, greaterThanOrEqualTo(-0.5), reason: '$slug scale $scale');
        expect(rect.bottom, lessThanOrEqualTo(900.5), reason: '$slug scale $scale');
        expect(tester.getSemantics(tile).label, isNotEmpty);
      }
    }
  });

  testWidgets('golden: church links at text scale 3', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(3)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: BelongSpacesDirectoryView(
              selectedSpaceSlug: 'general_chat',
              onSelectSpaceItem: _ignoreSpace,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = find.text('DFW Church');
    await tester.scrollUntilVisible(title, 240);
    await tester.pump();
    final card = find.ancestor(of: title, matching: find.byType(Card)).first;
    await expectLater(card, matchesGoldenFile('goldens/links_church_scale_3.png'));
  });

  testWidgets('Download the Android App opens the in-app phone guide', (tester) async {
    final selected = await pumpAndTap(tester, 'Download the Android App');
    expect(selected, isNull);
    expect(find.text('Get Belong on your phone'), findsOneWidget);
    expect(find.text('Android open beta'), findsWidgets);
  });

  testWidgets('Download the iOS App opens the website steps', (tester) async {
    final selected = await pumpAndTap(tester, 'Download the iOS App');
    expect(selected, isNull);
    expect(find.text('Get Belong on your phone'), findsOneWidget);
    expect(find.text('iPhone website'), findsOneWidget);
  });
}
