import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/constants/app_theme.dart';
import 'src/core/config/app_flavor.dart';
import 'src/core/firebase/community_analytics_service.dart';
import 'src/core/firebase/organizer_remote_config_service.dart';
import 'src/core/logging/app_logger.dart';
import 'src/features/reflections/data/post_repository_factory.dart';
import 'src/home_screen.dart';

export 'src/constants/app_theme.dart';
export 'src/core/config/app_flavor.dart';
export 'src/core/firebase/community_analytics_service.dart';
export 'src/core/firebase/organizer_remote_config_service.dart';
export 'src/features/reflections/data/post_repository_factory.dart';
export 'src/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await bootstrapBelongApp();

  runApp(const ProviderScope(child: SanctuaryApp()));
}

Future<void> bootstrapBelongApp() async {
  AppLogger.init();
  AppFlavorConfig.logCurrentFlavor();

  await OrganizerRemoteConfigService.initialize();
  await CommunityAnalyticsService.initialize();
}

class SanctuaryApp extends ConsumerWidget {
  const SanctuaryApp({
    super.key,
    this.postRepository,
    this.remoteConfigService,
    this.analyticsService,
  });

  final PostRepository? postRepository;
  final OrganizerRemoteConfigService? remoteConfigService;
  final CommunityAnalyticsService? analyticsService;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Belong on the Spectrum',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.getTheme(SensoryMode.calm),
    home: HomeScreen(
      repository: postRepository,
      remoteConfig: remoteConfigService,
      analytics: analyticsService,
    ),
  );
}
