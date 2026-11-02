import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/domain/fellowship_space.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncher extends UrlLauncherPlatform {
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
  }) async => true;
}

void main() {
  setUp(() {
    UrlLauncherPlatform.instance = _FakeUrlLauncher();
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
    // The row's external URL is dfwchurch.org. The live tap uses the organizer
    // remote-config partner URL, which defaults to disciplestoday.org.
    expect(find.textContaining('https://disciplestoday.org'), findsOneWidget);
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
