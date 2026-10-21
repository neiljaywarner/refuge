import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'src/app.dart';
import 'src/core/config/app_flavor.dart';
import 'src/core/firebase/community_analytics_service.dart';
import 'src/core/firebase/firebase_initializer.dart';
import 'src/core/observability/error_reporter_service.dart';
import 'src/features/reflections/data/post_repository_factory.dart';

export 'src/core/config/app_flavor.dart';
export 'src/features/reflections/data/post_repository_factory.dart';
export 'src/src_index.dart';

/// Exports from src/features/reflections/presentation/
export 'src/features/reflections/presentation/community_anchor_banner.dart';
export 'src/features/reflections/presentation/quiet_digest_banner.dart';
export 'src/features/reflections/presentation/reflection_card.dart';
export 'src/features/reflections/presentation/reflection_composer.dart';
export 'src/features/reflections/presentation/space_navigation_bar.dart';
export 'src/features/reflections/presentation/tone_filter_row.dart';

/// Domain and provider exports
export 'src/features/reflections/domain/post.dart';
export 'src/features/reflections/domain/reflection_post.dart';
export 'src/features/reflections/data/post_repository.dart';
export 'src/features/reflections/data/local_post_repository.dart';
export 'src/features/reflections/data/serverpod_post_repository.dart';
export 'src/features/sensory_themes/domain/sensory_mode.dart';
export 'src/features/sensory_themes/presentation/sensory_theme_controller.dart';
export 'src/features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
export 'src/features/profile/presentation/belong_members_directory_view.dart';
export 'src/core/presentation/coming_soon_view.dart';
export 'src/features/events/presentation/actually_autistic_events_view.dart';
export 'src/features/navigation/presentation/belong_bottom_nav_bar.dart';
export 'src/features/messages/presentation/belong_messages_view.dart';
export 'src/features/messages/presentation/calm_notifications_view.dart';
export 'src/features/search/presentation/community_search_view.dart';
export 'src/features/observability/presentation/observability_easter_egg_dialog.dart';
export 'src/features/branding/domain/community_brand_config.dart';
export 'src/features/branding/presentation/brand_config_provider.dart';
export 'src/core/firebase/organizer_remote_config_service.dart';
export 'src/core/firebase/community_analytics_service.dart';
export 'src/features/profile/domain/member_profile.dart';
export 'src/features/profile/presentation/member_profile_sheet.dart';
export 'src/features/about/presentation/about_refuge_dialog.dart';
export 'src/features/auth/presentation/belong_auth_sheet.dart';
export 'src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';
export 'src/src_index.dart';

export 'src/app.dart';
export 'src/home_screen.dart';

/// Entrypoint with runtime flavor resolution for Dev, TestFlight/Play Beta,
/// and Production (#52, ADR-0006).
void main() async {
  const flavor = AppFlavor.dev;
  await runWithFlavor(flavor);
}

/// Backward compatibility entrypoint for `main_dev.dart` and `main_prod.dart`.
Future<void> bootstrapBelongApp({required AppFlavor flavor}) async {
  await runWithFlavor(flavor);
}

Future<void> runWithFlavor(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase lifecycle (Crashlytics + Analytics)
  await FirebaseInitializer.initialize(flavor: flavor);

  final analytics = CommunityAnalyticsService(flavor: flavor);
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

  // A single ProviderScope lives inside SanctuaryApp. Do not wrap it in another
  // ProviderScope: root-scoped providers (e.g. quietDigestProvider) would then
  // read the nested postRepositoryProvider override, which Riverpod rejects in
  // debug builds (red screen found while driving the Pixel, #73).
  runApp(
    SanctuaryApp(
      repository: PostRepositoryFactory.create(),
      overrides: [
        appFlavorProvider.overrideWithValue(flavor),
        communityAnalyticsServiceProvider.overrideWithValue(analytics),
        errorReporterServiceProvider.overrideWithValue(errorReporter),
      ],
    ),
  );
}
