import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/post.dart';
import 'local_account_scope.dart';

/// Durable queue of reflections that are not yet confirmed by a cloud store.
///
/// Keys include the Firebase uid and the dev/prod partition so a second
/// account on the same device cannot read the first account's drafts.
class PendingPostOutbox {
  PendingPostOutbox({this.environment = 'dev', String? accountId, Map<String, String>? memory})
    : _accountId = _normalize(accountId),
      _memory = memory;

  final String environment;
  String? _accountId;

  /// When set, tests skip [SharedPreferences].
  final Map<String, String>? _memory;

  String? get accountId => _accountId;

  void adoptAccount(String? accountId) {
    _accountId = _normalize(accountId);
  }

  String get storageKey =>
      'belong_pending_posts_v1_${localAccountScope(environment: environment, accountId: _accountId)}';

  Future<bool> enqueue(Post post) async {
    final current = await readAll();
    final next = [
      for (final existing in current)
        if (existing.id != post.id) existing,
      post,
    ];
    return _write(next);
  }

  Future<List<Post>> readAll() async {
    final raw = await _readRaw();
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final posts = <Post>[];
      for (final item in decoded) {
        if (item is Map) {
          final post = Post.fromJson(Map<String, dynamic>.from(item));
          if (post.id.isNotEmpty) posts.add(post);
        }
      }
      return posts;
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> ids() async {
    final posts = await readAll();
    return {for (final post in posts) post.id};
  }

  Future<void> remove(String id) async {
    final current = await readAll();
    await _write([
      for (final post in current)
        if (post.id != id) post,
    ]);
  }

  Future<void> removeWhere(bool Function(Post post) test) async {
    final current = await readAll();
    await _write([
      for (final post in current)
        if (!test(post)) post,
    ]);
  }

  Future<String?> _readRaw() async {
    final memory = _memory;
    if (memory != null) return memory[storageKey];
    final prefs = await _safePrefs();
    return prefs?.getString(storageKey);
  }

  Future<bool> _write(List<Post> posts) async {
    final encoded = jsonEncode([for (final post in posts) post.toJson()]);
    final memory = _memory;
    if (memory != null) {
      memory[storageKey] = encoded;
      return true;
    }
    final prefs = await _safePrefs();
    if (prefs == null) return false;
    try {
      return await prefs.setString(storageKey, encoded);
    } catch (_) {
      return false;
    }
  }

  Future<SharedPreferences?> _safePrefs() {
    final result = Completer<SharedPreferences?>();
    runZonedGuarded(
      () async {
        try {
          final prefs = await SharedPreferences.getInstance().timeout(
            const Duration(milliseconds: 300),
          );
          if (!result.isCompleted) result.complete(prefs);
        } catch (_) {
          if (!result.isCompleted) result.complete(null);
        }
      },
      (Object error, StackTrace stack) {
        if (!result.isCompleted) result.complete(null);
      },
    );
    return result.future.timeout(const Duration(milliseconds: 400), onTimeout: () => null);
  }

  static String? _normalize(String? accountId) {
    final trimmed = accountId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
