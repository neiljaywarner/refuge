/// Compile-time switches for feature voting mirrors (ADR-0009, ADR-0011).
///
/// Community vote **totals** are canonical in Cloud Firestore (`feature_votes`).
/// Appwrite and Serverpod mirrors are best-effort and must never block the UI.
library;

import '../../../core/appwrite/appwrite_config.dart';

/// True when Serverpod Cloud should receive optional vote mirror writes.
bool get isServerpodFeatureVotingMirrorEnabled {
  const backend = String.fromEnvironment('BACKEND', defaultValue: 'appwrite');
  const enableServerpod = bool.fromEnvironment('ENABLE_SERVERPOD');
  return backend.toLowerCase() == 'serverpod' && enableServerpod;
}

/// True when the Appwrite client is configured for this build.
bool get isAppwriteFeatureVotingMirrorEnabled => AppwriteConfig.fromEnvironment.isConfigured;
