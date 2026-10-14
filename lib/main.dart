import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/features/reflections/data/post_repository_factory.dart';

// Re-export domain models, repositories, themes, and presentation components
// following CodeWithAndrea's feature-first architecture while maintaining
// 100% backward compatibility with all unit, widget, and BDD tests.
export 'src/app.dart';
export 'src/constants/app_theme.dart';
export 'src/features/about/presentation/about_refuge_dialog.dart';
export 'src/features/fellowship_spaces/domain/fellowship_space.dart';
export 'src/features/memes/domain/calm_meme.dart';
export 'src/features/memes/presentation/meme_gallery_modal.dart';
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
export 'src/features/sensory_themes/domain/sensory_mode.dart';
export 'src/features/sensory_themes/presentation/sensory_theme_controller.dart';
export 'src/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = PostRepositoryFactory.create();
  runApp(SanctuaryApp(repository: repository));
}
