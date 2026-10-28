import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/post.dart';

const savedPostIdsPrefsKey = 'belong_saved_post_ids_v1';
const savedPostsCachePrefsKey = 'belong_saved_posts_cache_v1';

/// Persists private "Save for Later" bookmarks locally in [SharedPreferences]
/// and mirrors them to the signed-in member's private Firestore subcollection
/// (`users/{uid}/saved_posts/{postId}`).
class SavedPostsStore {
  SavedPostsStore({this.customFirestore, this.customUserId});

  final FirebaseFirestore? customFirestore;
  final String? customUserId;

  /// Guards [SharedPreferences.getInstance] inside a dedicated zone so widget
  /// tests that do not register a `shared_preferences` mock channel never leak
  /// an unhandled `Completer.completeError` into `FakeAsync`.
  Future<SharedPreferences?> _safePrefs() {
    final result = Completer<SharedPreferences?>();
    runZonedGuarded(
      () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (!result.isCompleted) result.complete(prefs);
        } catch (_) {
          if (!result.isCompleted) result.complete(null);
        }
      },
      (Object error, StackTrace stack) {
        if (!result.isCompleted) result.complete(null);
      },
    );
    return result.future;
  }

  FirebaseFirestore? get _firestore {
    if (customFirestore != null) return customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  String? get _uid {
    final explicit = customUserId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance.currentUser?.uid;
      }
    } catch (_) {}
    return null;
  }

  /// Reads saved post IDs from local [SharedPreferences] and, when signed in,
  /// merges any IDs stored in `users/{uid}/saved_posts`.
  Future<Set<String>> readSavedIds() async {
    final ids = <String>{};
    try {
      final prefs = await _safePrefs();
      final stored = prefs?.getStringList(savedPostIdsPrefsKey);
      if (stored != null) {
        ids.addAll(stored.where((id) => id.trim().isNotEmpty));
      }
    } catch (_) {}

    final fs = _firestore;
    final uid = _uid;
    if (fs != null && uid != null) {
      try {
        final snap = await fs
            .collection('users')
            .doc(uid)
            .collection('saved_posts')
            .get()
            .timeout(const Duration(seconds: 2));
        for (final doc in snap.docs) {
          if (doc.id.trim().isNotEmpty) {
            ids.add(doc.id);
          }
        }
      } catch (_) {}
    }
    return ids;
  }

  /// Reads full cached [Post] snapshots so bookmarked cloud posts remain
  /// available offline and across restarts before their origin space is opened.
  Future<Map<String, Post>> readSavedPostSnapshots() async {
    final result = <String, Post>{};
    try {
      final prefs = await _safePrefs();
      final rawJson = prefs?.getString(savedPostsCachePrefsKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            if (value is Map) {
              final post = Post.fromJson(Map<String, dynamic>.from(value)).copyWith(isSaved: true);
              if (post.id.isNotEmpty) {
                result[post.id] = post;
              }
            }
          }
        }
      }
    } catch (_) {}

    final fs = _firestore;
    final uid = _uid;
    if (fs != null && uid != null) {
      try {
        final snap = await fs
            .collection('users')
            .doc(uid)
            .collection('saved_posts')
            .get()
            .timeout(const Duration(seconds: 2));
        for (final doc in snap.docs) {
          final data = doc.data();
          final post = Post.fromJson({...data, 'id': data['id'] ?? doc.id}).copyWith(isSaved: true);
          if (post.id.isNotEmpty) {
            result[post.id] = post;
          }
        }
      } catch (_) {}
    }
    return result;
  }

  /// Persists the updated set of saved post IDs and snapshots locally, and
  /// mirrors the specific [postId] toggle to Firestore when signed in.
  Future<void> persistToggle({
    required String postId,
    required bool isSaved,
    required Set<String> allSavedIds,
    required Iterable<Post> savedPosts,
    Post? toggledPost,
  }) async {
    try {
      final prefs = await _safePrefs();
      if (prefs != null) {
        await prefs.setStringList(savedPostIdsPrefsKey, allSavedIds.toList());
        final cacheMap = <String, Map<String, dynamic>>{
          for (final post in savedPosts)
            if (allSavedIds.contains(post.id)) post.id: post.copyWith(isSaved: true).toJson(),
        };
        if (isSaved && toggledPost != null) {
          cacheMap[postId] = toggledPost.copyWith(isSaved: true).toJson();
        } else if (!isSaved) {
          cacheMap.remove(postId);
        }
        await prefs.setString(savedPostsCachePrefsKey, jsonEncode(cacheMap));
      }
    } catch (_) {}

    final fs = _firestore;
    final uid = _uid;
    if (fs == null || uid == null) return;
    final docRef = fs.collection('users').doc(uid).collection('saved_posts').doc(postId);
    try {
      if (isSaved) {
        await docRef
            .set({
              if (toggledPost != null) ...toggledPost.copyWith(isSaved: true).toJson(),
              'id': postId,
              'savedAt': DateTime.now().toUtc().toIso8601String(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 2));
      } else {
        await docRef.delete().timeout(const Duration(seconds: 2));
      }
    } catch (_) {}
  }
}
