import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'profile_storage_stub.dart'
    if (dart.library.io) 'profile_storage_io.dart'
    if (dart.library.html) 'profile_storage_web.dart';

/// Provides local and cloud persistent profile storage across web page refreshes,
/// app restarts, and offline sessions (#448).
class ProfileStorageService {
  ProfileStorageService._();
  static final ProfileStorageService instance = ProfileStorageService._();

  final BaseProfileStorage _platformStorage = getPlatformProfileStorage();
  Map<String, dynamic>? _memoryCache;

  Map<String, dynamic>? load() {
    if (_memoryCache != null) return _memoryCache;
    _memoryCache = _platformStorage.load();
    return _memoryCache;
  }

  void save({
    required String displayName,
    required String email,
    String? bio,
    String? icocChurchAffiliation,
    List<String>? comfortBadges,
  }) {
    final data = <String, dynamic>{
      'displayName': displayName,
      'email': email,
      if (bio != null) 'bio': bio,
      if (icocChurchAffiliation != null)
        'icocChurchAffiliation': icocChurchAffiliation,
      if (comfortBadges != null) 'comfortBadges': comfortBadges,
      'savedAt': DateTime.now().toIso8601String(),
    };
    _memoryCache = data;
    _platformStorage.save(data);

    // Sync to Firestore if authenticated with real Firebase credentials
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        user.updateDisplayName(displayName);
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': displayName,
          'email': email,
          if (bio != null) 'bio': bio,
          if (icocChurchAffiliation != null)
            'icocChurchAffiliation': icocChurchAffiliation,
          if (comfortBadges != null) 'comfortBadges': comfortBadges,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  void clear() {
    _memoryCache = null;
    _platformStorage.clear();
  }
}
