import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../feedback/data/feature_voting_repository.dart';

/// 1-line switchable provider controlling which backend powers Authentication.
/// Defaults to [BackendTarget.firebase] for solid cloud auth.
final authBackendTargetProvider = Provider<BackendTarget>((ref) => BackendTarget.firebase);
