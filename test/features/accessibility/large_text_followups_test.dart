import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_thread.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/belong_messages_view.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/home_screen.dart';
import 'package:refuge4serverpod/src/core/presentation/unbroken_body_text.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';

import '../../helpers/text_scale.dart';
import 'large_text_surfaces.dart';

bool _isWordChar(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 0x30 && code <= 0x39) ||
      (code >= 0x41 && code <= 0x5A) ||
      (code >= 0x61 && code <= 0x7A);
}

/// A painter for the paragraph that is actually on screen.
///
/// [RenderParagraph.getLineBoundary] is not public, so this copies the mounted
/// span. That span already includes [DefaultTextStyle], accessibility bold,
/// and text-spacing overrides.
RenderParagraph _renderedParagraph(WidgetTester tester, Finder finder) {
  final element = tester.element(finder);
  if (element.renderObject is RenderParagraph) {
    return element.renderObject! as RenderParagraph;
  }
  RenderParagraph? found;
  void walk(Element child) {
    if (found != null) return;
    if (child.renderObject is RenderParagraph) {
      found = child.renderObject! as RenderParagraph;
      return;
    }
    child.visitChildren(walk);
  }

  element.visitChildren(walk);
  return found!;
}

TextPainter _painterForRenderedText(WidgetTester tester, Finder finder) {
  final paragraph = _renderedParagraph(tester, finder);
  final constraint = paragraph.constraints.maxWidth;
  final maxWidth = !paragraph.softWrap
      ? double.infinity
      : (constraint.isFinite ? constraint : paragraph.size.width);
  return TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    maxLines: paragraph.maxLines,
    ellipsis: paragraph.overflow == TextOverflow.ellipsis ? '\u2026' : null,
    locale: paragraph.locale,
    strutStyle: paragraph.strutStyle,
    textWidthBasis: paragraph.textWidthBasis,
    textHeightBehavior: paragraph.textHeightBehavior,
    hyphens: paragraph.hyphens,
  )..layout(maxWidth: maxWidth);
}

/// Lines painted for [finder], using the rendered paragraph's style and width.
List<String> paintedLines(WidgetTester tester, Finder finder) {
  final painter = _painterForRenderedText(tester, finder);
  final plain = painter.text?.toPlainText() ?? '';
  final lines = <String>[];
  var offset = 0;
  for (var guard = 0; guard < 40 && offset < plain.length; guard++) {
    final range = painter.getLineBoundary(TextPosition(offset: offset));
    if (range.end <= offset) break;
    lines.add(plain.substring(range.start, range.end));
    offset = range.end;
  }
  painter.dispose();
  return lines;
}

void expectNoMidWordWrap(WidgetTester tester, Finder finder) {
  final painter = _painterForRenderedText(tester, finder);
  final plain = painter.text?.toPlainText() ?? '';
  final lineCount = painter.computeLineMetrics().length;
  var offset = 0;
  for (var i = 0; i < lineCount && offset < plain.length; i++) {
    final range = painter.getLineBoundary(TextPosition(offset: offset));
    if (range.end <= offset) break;
    final end = range.end;
    final wraps = i < lineCount - 1 && end < plain.length;
    if (wraps) {
      expect(
        _isWordChar(plain[end - 1]) && _isWordChar(plain[end]),
        isFalse,
        reason: 'line broke mid-word at $end in ${plain.codeUnits}',
      );
    }
    offset = end;
  }
  painter.dispose();
}

class _SignedInProfileNotifier extends MemberProfileNotifier {
  @override
  MemberProfile build() => const MemberProfile(
    displayName: 'Signed In Tester',
    email: 'tester@example.com',
    bio: 'A quiet note',
    comfortBadges: [],
    isSignedIn: true,
  );
}

class _FailingFeed extends LocalPostRepository {
  _FailingFeed() : super(initialPosts: const []);

  final _posts = StreamController<List<Post>>();

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) => _posts.stream;

  void fail() => _posts.addError(StateError('feed unavailable'));
}

class _PendingFeed extends LocalPostRepository {
  _PendingFeed() : super(initialPosts: const []);

  final _posts = StreamController<List<Post>>();

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) => _posts.stream;
}

class _NamedFieldsProfile extends MemberProfileNotifier {
  @override
  MemberProfile build() => const MemberProfile(
    displayName: 'Signed In Tester',
    email: '',
    bio: 'A quiet note',
    comfortBadges: [],
    isSignedIn: true,
  );
}

void main() {
  testWidgets('bottom nav labels do not wrap mid-word at text scale 2', (tester) async {
    final session = await pumpWithTextScale(
      tester,
      Scaffold(
        body: const SizedBox.shrink(),
        bottomNavigationBar: BelongBottomNavBar(
          currentTab: BelongBottomTab.home,
          isContrast: false,
          onSelectTab: (_) {},
        ),
      ),
      scale: 2,
      shell: (child) => ProviderScope(child: child),
    );

    for (final tab in BelongBottomTab.values) {
      final label = find.byKey(Key('bottom_nav_label_${tab.name}'));
      expect(label, findsOneWidget);
      final text = tester.widget<Text>(label);
      expect(text.maxLines, 1, reason: '${tab.label} should stay on one line');
      expect(text.softWrap, isFalse);
      expect(text.overflow, TextOverflow.ellipsis);
      expectNoMidWordWrap(tester, label);
      expect(find.byTooltip(tab.label), findsWidgets);
    }
    session.check();
  });

  testWidgets('post body keeps web.app intact at text scale 2', (tester) async {
    const url = 'https://belongonthespectrum.web.app/start';
    final session = await pumpWithTextScale(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ReflectionCard(
            post: Post(
              id: 'url-post',
              authorName: 'Fellow Member',
              spaceKey: 'prayer',
              toneTag: '[Fellowship]',
              content: 'The notes live at $url for anyone who wants them.',
              timestamp: DateTime.utc(2026, 1, 1),
              reactions: const {},
            ),
            isContrast: false,
            onAddReaction: (_) {},
          ),
        ),
      ),
      scale: 2,
      shell: (child) => ProviderScope(child: child),
    );

    final body = find.descendant(
      of: find.byKey(const Key('post_body_url-post')),
      matching: find.byType(Text),
    );
    expect(body, findsOneWidget);
    expectNoMidWordWrap(tester, body);
    final lines = paintedLines(tester, body).map((line) => line.replaceAll('\u200B', '')).toList();
    expect(lines.any((line) => line.contains('web')), isTrue, reason: 'lines=$lines');
    expect(lines.any((line) => line.contains('app')), isTrue, reason: 'lines=$lines');
    expect(tester.widget<Text>(body).semanticsLabel, contains('web.app'));
    session.check();
  });

  testWidgets('line helper uses the rendered letter spacing at text scale 2', (tester) async {
    const word = 'Note';
    final session = await pumpWithTextScale(
      tester,
      const Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 220,
              child: DefaultTextStyle(
                style: TextStyle(fontSize: 20),
                child: Text(word, key: Key('tight_note'), style: TextStyle(fontSize: 20)),
              ),
            ),
            SizedBox(
              width: 220,
              child: DefaultTextStyle(
                style: TextStyle(fontSize: 20, letterSpacing: 40),
                child: Text(word, key: Key('spaced_note'), style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
      scale: 2,
    );

    expect(paintedLines(tester, find.byKey(const Key('tight_note'))).length, 1);
    expect(paintedLines(tester, find.byKey(const Key('spaced_note'))).length, greaterThan(1));
    session.check();
  });

  testWidgets('space-free body text stays complete at text scale 2', (tester) async {
    const japanese = 'これはスペースのない日本語の段落です。省略記号で本文を消してはいけません。';
    const slug = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const linked = 'Notes: https://example.com/$slug/end';
    final session = await pumpWithTextScale(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnbrokenBodyText(
                  key: Key('space_free_japanese'),
                  text: japanese,
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
                UnbrokenBodyText(
                  key: Key('space_free_url'),
                  text: linked,
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
      scale: 2,
    );

    void expectComplete(String key, String original) {
      final finder = find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text));
      final text = tester.widget<Text>(finder);
      expect(text.data, isNot(contains('\u2026')), reason: key);
      expect(text.semanticsLabel, original, reason: key);
      expect(text.data!.replaceAll('\u200B', ''), original, reason: key);
      expect(tester.getSize(finder).height, greaterThan(48), reason: key);
    }

    expectComplete('space_free_japanese', japanese);
    expectComplete('space_free_url', linked);
    session.check();
  });

  testWidgets('wide emoji tokens wrap on grapheme boundaries at text scale 2', (tester) async {
    const family = '👩‍👧‍👦';
    final body = family * 8;
    final session = await pumpWithTextScale(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 48,
            child: UnbrokenBodyText(text: body, style: const TextStyle(fontSize: 13, height: 1.45)),
          ),
        ),
      ),
      scale: 2,
    );

    final finder = find.byType(Text);
    final text = tester.widget<Text>(finder);
    expect(text.semanticsLabel, body);
    expect(text.data!.replaceAll('\u200B', ''), body);
    expect(text.data, contains('\u200B'));
    for (final piece in text.data!.split('\u200B')) {
      if (piece.isEmpty) continue;
      expect(piece.characters.length, 1, reason: piece);
    }
    session.check();
  });

  testWidgets('body measurement uses inherited spacing and bold text at text scale 2', (
    tester,
  ) async {
    const word = 'Note';
    final session = await pumpWithTextScale(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(boldText: true),
            child: const DefaultTextStyle(
              style: TextStyle(fontSize: 14, letterSpacing: 80),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: 200,
                  child: UnbrokenBodyText(text: word, style: TextStyle(fontSize: 14, height: 1.2)),
                ),
              ),
            ),
          ),
        ),
      ),
      scale: 2,
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.fontWeight, FontWeight.bold);
    expect(text.style?.letterSpacing, 80);
    expect(text.data!.replaceAll('\u200B', ''), word);
    expect(text.data, contains('\u200B'));
    session.check();
  });

  testWidgets('last conversation scrolls clear of the bottom nav at text scale 2', (tester) async {
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(() {
      tester.view.resetViewPadding();
      tester.view.resetPadding();
    });

    final threads = List<MessageThread>.generate(
      8,
      (index) => MessageThread(
        id: 'thread-$index',
        participantName: 'Member $index',
        avatarInitials: 'M$index',
        subject: 'A calm note $index',
        previewSnippet: 'The last line of this conversation should clear the tab bar.',
        lastActivity: DateTime.utc(2026, 1, 1).add(Duration(minutes: index)),
      ),
    );

    final session = await pumpWithTextScale(
      tester,
      Scaffold(
        body: BelongMessagesView(initialThreads: threads),
        bottomNavigationBar: BelongBottomNavBar(
          currentTab: BelongBottomTab.msgs,
          isContrast: false,
          onSelectTab: (_) {},
        ),
      ),
      scale: 2,
      shell: (child) => ProviderScope(child: child),
    );

    final last = find.byKey(const Key('thread-thread-7'));
    final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable));
    expect(list, findsOneWidget);
    await tester.scrollUntilVisible(last, 400, scrollable: list);
    final position = tester.state<ScrollableState>(list).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    session.check();

    final tileBottom = tester.getRect(last).bottom;
    final navTop = tester.getRect(find.byKey(const Key('belong_bottom_nav_bar'))).top;
    expect(tileBottom, lessThanOrEqualTo(navTop - 8));
  });

  testWidgets('profile sheet scrolls and stacks actions at text scale 2', (tester) async {
    tester.view.viewPadding = const FakeViewPadding(bottom: 48, top: 24);
    tester.view.padding = const FakeViewPadding(bottom: 48, top: 24);
    addTearDown(() {
      tester.view.resetViewPadding();
      tester.view.resetPadding();
    });

    final session = await pumpWithTextScale(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              key: const Key('open_profile_sheet'),
              onPressed: () => MemberProfileDialog.show(context),
              child: const Text('Open profile'),
            ),
          ),
        ),
      ),
      scale: 2,
      shell: (child) => ProviderScope(
        overrides: [memberProfileProvider.overrideWith(_SignedInProfileNotifier.new)],
        child: child,
      ),
    );
    await tester.tap(find.byKey(const Key('open_profile_sheet')));
    await settleLargeText(tester);
    session.check();

    for (final label in ['First Name', 'Last Name', 'Bio / Note to Fellowship']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, isNull, reason: label);
      expect(text.overflow, isNot(TextOverflow.ellipsis), reason: label);
    }

    final sheet = find.byKey(const Key('profile_sheet_scroll'));
    expect(sheet, findsOneWidget);

    Future<void> reveal(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        160,
        scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)).first,
      );
      await tester.pump();
      session.check();
      final rect = tester.getRect(finder);
      expect(rect.top, greaterThanOrEqualTo(-0.5));
      expect(rect.bottom, lessThanOrEqualTo(largeTextPhoneSurface.height + 0.5));
    }

    await reveal(find.byKey(const Key('preview_mode_switch')));
    expect(tester.getSize(find.byKey(const Key('preview_mode_switch'))).height, greaterThan(24));

    final saveFinder = find.byKey(const Key('profile_save_sign_in_button'));
    final cancelFinder = find.byKey(const Key('profile_cancel_button'));
    final signOutFinder = find.byKey(const Key('profile_sign_out_button'));
    await reveal(signOutFinder);
    final save = tester.getRect(saveFinder);
    final cancel = tester.getRect(cancelFinder);
    final signOut = tester.getRect(signOutFinder);
    expect(save.width, greaterThan(180));
    expect((save.width - cancel.width).abs(), lessThan(8));
    expect((save.width - signOut.width).abs(), lessThan(8));
    expect(save.bottom, lessThanOrEqualTo(cancel.top));
    expect(cancel.bottom, lessThanOrEqualTo(signOut.top));
    expect(cancel.top - save.bottom, greaterThanOrEqualTo(4));
  });

  testWidgets('large-text profile fields keep their accessible names at text scale 2', (
    tester,
  ) async {
    final session = await pumpWithTextScale(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              key: const Key('open_profile_sheet'),
              onPressed: () => MemberProfileDialog.show(context),
              child: const Text('Open profile'),
            ),
          ),
        ),
      ),
      scale: 2,
      shell: (child) => ProviderScope(
        overrides: [memberProfileProvider.overrideWith(_NamedFieldsProfile.new)],
        child: child,
      ),
    );
    final semantics = tester.ensureSemantics();
    try {
      await tester.tap(find.byKey(const Key('open_profile_sheet')));
      await settleLargeText(tester);
      session.check();

      const fields = {
        'profile_display_name_field': 'First Name',
        'profile_last_name_field': 'Last Name',
        'profile_email_field': 'Email Address',
        'profile_bio_field': 'Bio / Note to Fellowship',
      };
      for (final entry in fields.entries) {
        expect(find.text(entry.value), findsOneWidget, reason: entry.key);
        final node = tester.getSemantics(find.byKey(Key(entry.key)));
        expect(node.label, contains(entry.value), reason: entry.key);
        expect(find.bySemanticsLabel(entry.value), findsOneWidget, reason: entry.key);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('welcome card and composer hint wrap to two lines at text scale 2', (tester) async {
    final session = await pumpHomeAtScale(tester, 2);
    final banner = find.byKey(const Key('organizer_message_banner'));
    final title = find.text('Welcome to Belong on the Spectrum');
    final titleText = tester.widget<Text>(title);
    expect(titleText.maxLines, 2);
    final titleWidth = tester.getSize(title).width;
    final oneLine = TextPainter(
      text: TextSpan(text: 'Welcome to Belong on the Spectrum', style: titleText.style),
      textDirection: TextDirection.ltr,
      textScaler: const TextScaler.linear(2),
      maxLines: 1,
    )..layout(maxWidth: titleWidth);
    expect(tester.getSize(title).height, greaterThan(oneLine.height + 2));
    oneLine.dispose();

    final message = find.textContaining('peaceful sanctuary');
    final messageText = tester.widget<Text>(message);
    expect(messageText.maxLines, anyOf(isNull, greaterThan(2)));
    expect(messageText.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.getSize(message).width, greaterThan(tester.getSize(banner).width * 0.75));

    final composer = find.byKey(const Key('reflection_composer_input'));
    await tester.scrollUntilVisible(
      composer,
      300,
      scrollable: find
          .descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable))
          .first,
    );
    await tester.pump();
    session.check();
    final field = tester.widget<TextField>(composer);
    expect(field.maxLines, isNull);
    final hint = find.textContaining('Share an unhurried thought');
    final hintText = tester.widget<Text>(hint);
    expect(hintText.maxLines, isNull);
    expect(hintText.overflow, isNot(TextOverflow.ellipsis));
    expect(hintText.data, contains('Prayer Sanctuary'));
    expect(tester.getSize(hint).height, greaterThan(28));
  });

  testWidgets('feed scroll view keeps most of a phone at text scale 2', (tester) async {
    const physical = Size(1080, 2424);
    const dpr = 2.625;
    final session = await pumpHomeAtScale(tester, 2, surface: physical, devicePixelRatio: dpr);

    final feed = find.byKey(const Key('home_feed_scroll'));
    expect(feed, findsOneWidget);
    final banner = find.byKey(const Key('organizer_message_banner'));
    final before = tester.getTopLeft(banner).dy;
    await tester.drag(feed, const Offset(0, -120));
    await tester.pump();
    session.check();

    final viewport = tester.getRect(feed);
    final screenHeight = physical.height / dpr;
    expect(viewport.height, greaterThanOrEqualTo(screenHeight * 0.60));
    expect(tester.getTopLeft(banner).dy, lessThan(before - 40));

    final scrollable = find.descendant(
      of: feed,
      matching: find.byWidgetPredicate(
        (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final position = tester.state<ScrollableState>(scrollable.first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    session.check();

    final reactions = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('reaction_button_');
    });
    expect(reactions, findsWidgets);
    var lowest = tester.getRect(reactions.at(0));
    for (var i = 1; i < reactions.evaluate().length; i++) {
      final rect = tester.getRect(reactions.at(i));
      if (rect.bottom > lowest.bottom) lowest = rect;
    }
    final navTop = tester.getRect(find.byKey(const Key('belong_bottom_nav_bar'))).top;
    expect(lowest.bottom, lessThanOrEqualTo(navTop - 8));
  });

  testWidgets('reaction chips stay inside the card at text scale 2', (tester) async {
    const physical = Size(1080, 2424);
    const dpr = 2.625;
    final session = await pumpWithTextScale(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ReflectionCard(
            post: Post(
              id: 'react-post',
              authorName: 'Fellow Member',
              spaceKey: 'prayer',
              toneTag: '[Fellowship]',
              content: 'A note with every reaction chip.',
              timestamp: DateTime.utc(2026, 1, 1),
              reactions: const {'pray': 1, 'peace': 2, 'encouraged': 0, 'relatable': 3},
            ),
            isContrast: false,
            onAddReaction: (_) {},
          ),
        ),
      ),
      scale: 2,
      surface: physical,
      devicePixelRatio: dpr,
      shell: (child) => ProviderScope(child: child),
    );

    final card = tester.getRect(find.byKey(const Key('reflection_card_react-post')));
    for (final type in ['pray', 'peace', 'encouraged', 'relatable']) {
      final chip = tester.getRect(find.byKey(Key('reaction_button_${type}_react-post')));
      expect(chip.left, greaterThanOrEqualTo(card.left - 0.5), reason: type);
      expect(chip.right, lessThanOrEqualTo(card.right + 0.5), reason: type);
      expect(chip.top, greaterThanOrEqualTo(card.top - 0.5), reason: type);
      expect(chip.bottom, lessThanOrEqualTo(card.bottom + 0.5), reason: type);
    }
    expect(find.textContaining('Encouraged'), findsOneWidget);
    expect(find.textContaining('Relatable'), findsOneWidget);
    session.check();
  });

  Future<TextScaleSession> pumpFeed(WidgetTester tester, PostRepository repository) =>
      pumpWithTextScale(
        tester,
        RefugeHomeScreen(repository: repository),
        scale: 2,
        shell: (child) => ProviderScope(
          overrides: [postRepositoryProvider.overrideWithValue(repository)],
          child: child,
        ),
      );

  testWidgets('failed and loading feeds keep space navigation at text scale 2', (tester) async {
    final failing = _FailingFeed();
    final failed = await pumpFeed(tester, failing);
    failing.fail();
    await tester.pump();
    expect(find.byKey(const Key('home_feed_scroll')), findsOneWidget);
    expect(find.byKey(const Key('subnav_spaces_tab')), findsOneWidget);
    expect(find.byKey(const Key('space_room_header')), findsOneWidget);
    final feedScroll = find.descendant(
      of: find.byKey(const Key('home_feed_scroll')),
      matching: find.byType(Scrollable),
    );
    final error = find.textContaining('Error loading reflections');
    await tester.scrollUntilVisible(error, 400, scrollable: feedScroll.first);
    expect(error, findsOneWidget);
    expect(tester.getSize(error).height, greaterThan(0));
    await tester.scrollUntilVisible(
      find.byKey(const Key('subnav_spaces_tab')),
      -400,
      scrollable: feedScroll.first,
    );
    await tester.tap(find.byKey(const Key('subnav_spaces_tab')));
    await settleLargeText(tester);
    failed.check();
    expect(find.byKey(const Key('belong_spaces_directory_list')), findsOneWidget);

    final pending = await pumpFeed(tester, _PendingFeed());
    final pendingScroll = find.descendant(
      of: find.byKey(const Key('home_feed_scroll')),
      matching: find.byType(Scrollable),
    );
    final spinner = find.byType(CircularProgressIndicator);
    expect(find.byKey(const Key('subnav_feed_tab')), findsOneWidget);
    expect(find.byKey(const Key('subnav_spaces_tab')), findsOneWidget);
    expect(find.byKey(const Key('space_room_header')), findsOneWidget);
    expect(find.textContaining('Error loading reflections'), findsNothing);
    await tester.scrollUntilVisible(spinner, 400, scrollable: pendingScroll.first);
    expect(spinner, findsOneWidget);
    pending.check();
  });

  testWidgets('post author names wrap to two lines at text scale 2', (tester) async {
    final session = await pumpWithTextScale(
      tester,
      Scaffold(
        body: ReflectionCard(
          post: Post(
            id: 'author-post',
            authorName: 'Ban And Uma',
            spaceKey: 'prayer',
            toneTag: '[Fellowship]',
            content: 'A short note.',
            timestamp: DateTime.utc(2026, 1, 1),
            reactions: const {},
          ),
          isContrast: false,
          onAddReaction: (_) {},
        ),
      ),
      scale: 2,
      shell: (child) => ProviderScope(child: child),
    );
    final name = tester.widget<Text>(find.text('Ban And Uma'));
    expect(name.maxLines, 2);
    session.check();
  });
}
