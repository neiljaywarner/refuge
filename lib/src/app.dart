import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_theme.dart';
import 'features/reflections/data/post_repository.dart';
import 'features/sensory_themes/presentation/sensory_theme_controller.dart';
import 'home_screen.dart';

/// Root application widget wrapping Refuge (Sanctuary) in a Riverpod ProviderScope.
class SanctuaryApp extends StatefulWidget {
  final PostRepository repository;
  final List<Override>? overrides;

  const SanctuaryApp({super.key, required this.repository, this.overrides});

  @override
  State<SanctuaryApp> createState() => _SanctuaryAppState();
}

/// Alias for SanctuaryApp to support Refuge branding.
typedef RefugeApp = SanctuaryApp;

class _SanctuaryAppState extends State<SanctuaryApp> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [postRepositoryProvider.overrideWithValue(widget.repository), ...?widget.overrides],
    child: ListenableBuilder(
      listenable: _themeNotifier,
      builder: (context, _) =>
          _SanctuaryAppContent(repository: widget.repository, themeNotifier: _themeNotifier),
    ),
  );
}

class _SanctuaryAppContent extends ConsumerWidget {
  final PostRepository repository;
  final ThemeNotifier themeNotifier;

  const _SanctuaryAppContent({required this.repository, required this.themeNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Sanctuary Digital Clubhouse',
    theme: SensoryThemeData.getTheme(themeNotifier.mode),
    home: SanctuaryHomeScreen(repository: repository, themeNotifier: themeNotifier),
  );
}
