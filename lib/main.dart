import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'src/app.dart';
import 'src/features/notifications/data/fcm_background_handler.dart';
import 'src/features/notifications/data/fcm_messaging_service.dart';
import 'src/core/config/app_flavor.dart';
import 'src/core/firebase/community_analytics_service.dart';
import 'src/core/firebase/firebase_initializer.dart';
import 'src/core/observability/error_reporter_service.dart';
import 'src/features/reflections/data/post_repository_factory.dart';

// Re-export domain models, repositories, themes, and presentation components
// following CodeWithAndrea's feature-first architecture while maintaining
// 100% backward compatibility with all unit, widget, and BDD tests.
export 'src/app.dart';
export 'src/constants/app_theme.dart';
export 'src/core/config/app_flavor.dart';
export 'src/core/firebase/community_analytics_service.dart';
export 'src/core/firebase/firebase_initializer.dart';
export 'src/core/firebase/organizer_remote_config_service.dart';
export 'src/core/observability/error_reporter_service.dart';
export 'src/core/presentation/coming_soon_view.dart';
export 'src/features/about/presentation/about_refuge_dialog.dart';
export 'src/features/auth/presentation/belong_auth_sheet.dart';
export 'src/features/auth/presentation/belong_firebase_auth_screen.dart';
export 'src/features/auth/presentation/simple_auth.dart';
export 'src/features/branding/domain/community_brand_config.dart';
export 'src/features/branding/presentation/brand_config_provider.dart';
export 'src/features/feedback/domain/feedback_and_voting_models.dart';
export 'src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';
export 'src/features/fellowship_spaces/domain/fellowship_space.dart';
export 'src/features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
export 'src/features/memes/domain/calm_meme.dart';
export 'src/features/memes/presentation/meme_gallery_modal.dart';
export 'src/features/navigation/presentation/belong_bottom_nav_bar.dart';
export 'src/features/profile/domain/member_profile.dart';
export 'src/features/profile/presentation/member_profile_sheet.dart';
export 'src/features/reflections/data/local_post_repository.dart';
export 'src/features/reflections/data/post_repository.dart';
export 'src/features/reflections/data/post_repository_factory.dart';
export 'src/features/reflections/data/serverpod_post_repository.dart';
export 'src/features/reflections/domain/post.dart';
export 'src/features/reflections/presentation/community_anchor_banner.dart';
export 'src/features/reflections/presentation/quiet_digest_banner.dart';
export 'src/features/reflections/presentation/reflection_card.dart';
export 'src/features/reflections/presentation/reflection_composer.dart';
export 'src/features/reflections/presentation/reflections_providers.dart';
export 'src/features/reflections/presentation/space_navigation_bar.dart';
export 'src/features/reflections/presentation/tone_filter_row.dart';
export 'src/features/search/presentation/community_search_view.dart';
export 'src/features/sensory_themes/domain/sensory_mode.dart';
export 'src/features/sensory_themes/presentation/sensory_theme_controller.dart';
export 'src/home_screen.dart';

/// Held for the process lifetime. Disposing it turns the web semantics tree
/// back off, which is what leaves Maestro unable to see any text.
SemanticsHandle? _webSemanticsHandle;

/// Flutter web paints to a canvas and does not publish the semantics DOM until
/// a screen reader toggles it (or this call). Maestro's web driver reads that
/// DOM, so without it `assertVisible` fails on text that is clearly on screen.
///
/// Mobile keeps the default: TalkBack, VoiceOver, and Maestro enable semantics
/// through the platform accessibility bridge. Forcing it there is unnecessary.
void enableWebSemanticsForAutomation() {
  if (!kIsWeb) {
    return;
  }
  _webSemanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
}

/// Default entrypoint. Honors `--dart-define=FLAVOR=` and otherwise stays on
/// `dev`, so a plain `flutter run` / `flutter build web` does not ship as prod.
/// Release deploys pass `-t lib/main_prod.dart` as well (ADR-0006).
void main() async {
  const envFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  await runWithFlavor(AppFlavor.fromString(envFlavor));
}

/// Backward compatibility entrypoint for `main_dev.dart` and `main_prod.dart`.
Future<void> bootstrapBelongApp({required AppFlavor flavor}) async {
  await runWithFlavor(flavor);
}

Future<void> runWithFlavor(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  enableWebSemanticsForAutomation();

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // 1. Initialize Firebase lifecycle (Crashlytics + Analytics)
  await FirebaseInitializer.initialize(flavor: flavor);

  final analytics = CommunityAnalyticsService(flavor: flavor);
  await FcmMessagingService.ensureInitialized(analytics: analytics);
  final errorReporter = ErrorReporterService(flavor: flavor, analyticsService: analytics);

  // 2. Global Flutter framework error hook
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (Firebase.apps.isNotEmpty && !kIsWeb) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
    errorReporter.recordError(
      details.exception,
      details.stack,
      reason: details.context?.toDescription(),
      fatal: false,
    );
  };

  // 3. Platform root dispatcher unhandled asynchronous error hook
  PlatformDispatcher.instance.onError = (error, stack) {
    if (Firebase.apps.isNotEmpty && !kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    errorReporter.recordError(error, stack, fatal: true);
    return true;
  };

  // A single ProviderScope lives inside RefugeApp. Do not wrap it in another
  // ProviderScope: root-scoped providers (e.g. quietDigestProvider) would then
  // read the nested postRepositoryProvider override, which Riverpod rejects in
  // debug builds (red screen found while driving the Pixel, #73).
  runApp(
    RefugeApp(
      repository: PostRepositoryFactory.create(flavor: flavor),
      enforceSignIn: true,
      overrides: [
        appFlavorProvider.overrideWithValue(flavor),
        communityAnalyticsServiceProvider.overrideWithValue(analytics),
        errorReporterServiceProvider.overrideWithValue(errorReporter),
      ],
    ),
  );
}
