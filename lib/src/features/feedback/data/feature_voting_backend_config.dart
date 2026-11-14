/// Compile-time switches for feature voting mirrors (ADR-0009, ADR-0011).
///
/// Community vote **totals** are canonical in Cloud Firestore (`feature_votes`).
/// The Appwrite mirror is best-effort and must never block the UI.
library;

import '../../../core/appwrite/appwrite_config.dart';

/// True when the Appwrite client is configured for this build.
bool get isAppwriteFeatureVotingMirrorEnabled => AppwriteConfig.fromEnvironment.isConfigured;
