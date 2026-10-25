import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';

/// Provides the active [CommunityBrandConfig] for the application.
///
/// Defaults to [CommunityBrandConfig.belong] (`belongonthespectrum.com`) and
/// can be overridden in `ProviderScope` for white-label partner tenants or BDD
/// tests.
final communityBrandConfigProvider = Provider<CommunityBrandConfig>(
  (ref) => const CommunityBrandConfig.belong(),
);
