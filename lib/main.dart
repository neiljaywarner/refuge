import 'package:flutter/material.dart';


import 'src/app.dart';
import 'src/core/config/app_flavor.dart';
import 'src/core/firebase/community_analytics_service.dart';
import 'src/core/observability/error_reporter_service.dart';
import 'src/features/reflections/data/post_repository_factory.dart';

// Re-export domain models, repositories, themes, and presentation components
// following CodeWithAndrea's feature-first architecture while maintaining
// 100% backward compatibility with all unit, widget, and BDD tests.
export 'src/app.dart';
export 'src/constants/app_theme.dart';
export 'src/core/config/app_flavor.dart';
export 'src/core/firebase/community_analytics_service.dart';
export 'src/core/firebase/organizer_remote_config_service.dart';
export 'src/core/observability/error_reporter_service.dart';
export 'src/core/presentation/coming_soon_view.dart';
export 'src/features/about/presentation/about_refuge_dialog.dart';
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

void bootstrapBelongApp({required AppFlavor flavor}) {
  WidgetsFlutterBinding.ensureInitialized();

  final analytics = CommunityAnalyticsService(flavor: flavor);
  final errorReporter = ErrorReporterService(flavor: flavor, analyticsService: analytics);

  // Global Flutter framework error hook
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    errorReporter.recordError(
      details.exception,
      details.stack,
      reason: details.context?.toStringShort(),
      fatal: false,
    );
  };

  // Platform root dispatcher unhandled asynchronous error hook
  PlatformDispatcher.instance.onError = (error, stack) {
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

void main() {
  const envFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  bootstrapBelongApp(flavor: AppFlavor.fromString(envFlavor));
}
