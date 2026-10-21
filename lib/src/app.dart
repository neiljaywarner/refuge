import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_theme.dart';
import 'features/reflections/data/post_repository.dart';
import 'features/sensory_themes/presentation/sensory_theme_controller.dart';
import 'home_screen.dart';

/// Root application widget wrapping Refuge in a Riverpod ProviderScope.
class RefugeApp extends StatefulWidget {
  final PostRepository repository;
  final List<Override>? overrides;

  const RefugeApp({super.key, required this.repository, this.overrides});

  @override
  State<RefugeApp> createState() => _RefugeAppState();
}

/// Backward-compatible alias for SanctuaryApp.
typedef SanctuaryApp = RefugeApp;

class _RefugeAppState extends State<RefugeApp> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [postRepositoryProvider.overrideWithValue(widget.repository), ...?widget.overrides],
    child: ListenableBuilder(
      listenable: _themeNotifier,
      builder: (context, _) =>
          _RefugeAppContent(repository: widget.repository, themeNotifier: _themeNotifier),
    ),
  );
}

class _RefugeAppContent extends ConsumerWidget {
  final PostRepository repository;
  final ThemeNotifier themeNotifier;

  const _RefugeAppContent({required this.repository, required this.themeNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Belong',
    theme: SensoryThemeData.getTheme(themeNotifier.mode),
    localizationsDelegates: [
      FirebaseUILocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: RefugeHomeScreen(repository: repository, themeNotifier: themeNotifier),
  );
}
