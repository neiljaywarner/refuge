import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_theme.dart';
import 'core/presentation/system_insets.dart';
import 'features/reflections/data/post_repository.dart';
import 'features/sensory_themes/domain/sensory_font_scale.dart';
import 'features/sensory_themes/domain/sensory_mode.dart';
import 'features/sensory_themes/presentation/sensory_theme_controller.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'home_screen.dart';

/// Root application widget wrapping Refuge in a Riverpod ProviderScope.
class RefugeApp extends StatefulWidget {
  final PostRepository repository;
  final List<Override>? overrides;
  final Widget? homeOverride;
  final SensoryMode initialTheme;
  final bool enforceSignIn;

  const RefugeApp({
    super.key,
    required this.repository,
    this.overrides,
    this.homeOverride,
    this.initialTheme = SensoryMode.sage,
    this.enforceSignIn = false,
  });

  @override
  State<RefugeApp> createState() => _RefugeAppState();
}

/// Backward-compatible alias for SanctuaryApp.
typedef SanctuaryApp = RefugeApp;

class _RefugeAppState extends State<RefugeApp> {
  late final ThemeNotifier _themeNotifier = ThemeNotifier()
    ..setMode(widget.initialTheme);

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      postRepositoryProvider.overrideWithValue(widget.repository),
      if (widget.initialTheme != SensoryMode.sage)
        sensoryThemeModeProvider.overrideWith(
          (ref) => SensoryThemeNotifier(widget.initialTheme),
        ),
      ...?widget.overrides,
    ],
    child: ListenableBuilder(
      listenable: _themeNotifier,
      builder: (context, _) => _RefugeAppContent(
        repository: widget.repository,
        themeNotifier: _themeNotifier,
        homeOverride: widget.homeOverride,
        enforceSignIn: widget.enforceSignIn,
      ),
    ),
  );
}

class _RefugeAppContent extends ConsumerWidget {
  final PostRepository repository;
  final ThemeNotifier themeNotifier;
  final Widget? homeOverride;
  final bool enforceSignIn;

  const _RefugeAppContent({
    required this.repository,
    required this.themeNotifier,
    this.homeOverride,
    required this.enforceSignIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Belong',
    theme: SensoryThemeData.getTheme(themeNotifier.mode),
    builder: (context, child) {
      final riverpodFontScale = ref.watch(sensoryFontScaleProvider);
      final activeScale = themeNotifier.fontScale != SensoryFontScale.standard
          ? themeNotifier.fontScale
          : riverpodFontScale;
      final repaired = SystemInsets.repairPadding(MediaQuery.of(context))
          .copyWith(textScaler: TextScaler.linear(activeScale.scaleFactor));
      final theme = Theme.of(context);
      return MediaQuery(
        data: repaired,
        child: Theme(
          data: theme.copyWith(
            dialogTheme: theme.dialogTheme.copyWith(
              insetPadding: SystemInsets.dialogInsetPadding(repaired),
            ),
          ),
          child: child!,
        ),
      );
    },
    localizationsDelegates: [
      FirebaseUILocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: homeOverride ??
        (enforceSignIn
            ? AuthGate(
                repository: repository,
                themeNotifier: themeNotifier,
              )
            : RefugeHomeScreen(
                repository: repository,
                themeNotifier: themeNotifier,
              )),
  );
}
