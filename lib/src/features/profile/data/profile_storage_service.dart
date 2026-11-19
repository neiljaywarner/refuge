import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'member_profile_cloud_store.dart';
import 'profile_storage_stub.dart'
    if (dart.library.io) 'profile_storage_io.dart'
    if (dart.library.html) 'profile_storage_web.dart';

/// Provides local and cloud persistent profile storage across web page refreshes,
/// app restarts, and offline sessions (#448).
class ProfileStorageService {
  ProfileStorageService._();
  static final ProfileStorageService instance = ProfileStorageService._();

  /// Cloud copy of church and preview. Tests replace this with an in-memory store.
  static MemberProfileCloudStore cloudStore = FirestoreMemberProfileCloudStore();

  final BaseProfileStorage _platformStorage = getPlatformProfileStorage();
  Map<String, dynamic>? _memoryCache;

  static const skippedFirstVisitWelcomeKey = 'skippedFirstVisitWelcome';
  static const previewFeaturesEnabledKey = 'previewFeaturesEnabled';

  /// True after the member taps Skip on the first-visit name card (#663).
  bool get skippedFirstVisitWelcome => load()?[skippedFirstVisitWelcomeKey] == true;

  void markFirstVisitSkipped() {
    final data = Map<String, dynamic>.from(load() ?? <String, dynamic>{});
    data[skippedFirstVisitWelcomeKey] = true;
    _memoryCache = data;
    _platformStorage.save(data);
  }

  Map<String, dynamic>? load() {
    if (_memoryCache != null) return _memoryCache;
    _memoryCache = _platformStorage.load();
    return _memoryCache;
  }

  void save({
    required String displayName,
    required String email,
    String? userId,
    String? bio,
    String? icocChurchAffiliation,
    List<String>? comfortBadges,
    String? avatarUrl,
    bool? previewFeaturesEnabled,
    bool syncCloud = true,
  }) {
    final data = Map<String, dynamic>.from(load() ?? <String, dynamic>{});
    final keepSkip = data[skippedFirstVisitWelcomeKey] == true;
    data
      ..['displayName'] = displayName
      ..['email'] = email
      ..['savedAt'] = DateTime.now().toIso8601String();
    if (keepSkip) {
      data[skippedFirstVisitWelcomeKey] = true;
    }
    if (userId != null && userId.isNotEmpty) data['userId'] = userId;
    if (bio != null) data['bio'] = bio;
    if (icocChurchAffiliation != null) {
      data['icocChurchAffiliation'] = icocChurchAffiliation;
    }
    if (comfortBadges != null) data['comfortBadges'] = comfortBadges;
    if (avatarUrl != null) {
      if (avatarUrl.isEmpty) {
        data.remove('avatarUrl');
      } else {
        data['avatarUrl'] = avatarUrl;
      }
    }
    if (previewFeaturesEnabled != null) {
      data[previewFeaturesEnabledKey] = previewFeaturesEnabled;
    }
    _memoryCache = data;
    _platformStorage.save(data);
    _syncAuthAndCloud(
      data: data,
      displayName: displayName,
      userId: userId,
      bio: bio,
      avatarUrl: avatarUrl,
      syncCloud: syncCloud,
    );
  }

  /// Writes the preview switch without requiring a church answer.
  void persistPreviewFeatures(bool enabled, {String? userId}) {
    final data = Map<String, dynamic>.from(load() ?? <String, dynamic>{});
    data[previewFeaturesEnabledKey] = enabled;
    if (userId != null && userId.isNotEmpty && userId != 'guest') {
      data['userId'] = userId;
    }
    _memoryCache = data;
    _platformStorage.save(data);
    final uid = _cloudUid(data['userId'] as String?);
    if (uid == null) return;
    unawaited(cloudStore.merge(uid, MemberProfileCloudFields(previewFeaturesEnabled: enabled)));
  }

  void _syncAuthAndCloud({
    required Map<String, dynamic> data,
    required String displayName,
    required String? userId,
    required String? bio,
    required String? avatarUrl,
    required bool syncCloud,
  }) {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        user.updateDisplayName(displayName);
        if (avatarUrl != null) {
          user.updatePhotoURL(avatarUrl.isEmpty ? null : avatarUrl);
        }
      }
    } catch (_) {}

    if (!syncCloud) return;
    final uid = _cloudUid(userId ?? data['userId'] as String?);
    if (uid == null) return;
    final preview = data[previewFeaturesEnabledKey];
    final church = data['icocChurchAffiliation'];
    final badges = data['comfortBadges'];
    unawaited(
      cloudStore.merge(
        uid,
        MemberProfileCloudFields(
          displayName: displayName,
          bio: bio ?? data['bio'] as String?,
          icocChurchAffiliation: church is String ? church : null,
          comfortBadges: badges is List ? badges.map((item) => item.toString()).toList() : null,
          avatarUrl: data['avatarUrl'] as String?,
          previewFeaturesEnabled: preview is bool ? preview : null,
        ),
      ),
    );
  }

  /// Firebase uid when Auth is up, otherwise the id stored with the profile.
  String? _cloudUid(String? storedUserId) {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous && user.uid.isNotEmpty) {
        return user.uid;
      }
    } catch (_) {}
    if (storedUserId == null || storedUserId.isEmpty || storedUserId == 'guest') {
      return null;
    }
    return storedUserId;
  }

  void clear() {
    _memoryCache = null;
    _platformStorage.clear();
  }
}
