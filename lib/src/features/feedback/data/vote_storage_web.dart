// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

import 'vote_storage_stub.dart';

class WebVoteStorage implements BaseVoteStorage {
  static const _key = 'belong_feature_votes_session';

  @override
  Set<String> loadVotedIds() {
    try {
      final raw = html.window.localStorage[_key];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toSet();
        }
      }
    } catch (_) {}
    return <String>{};
  }

  @override
  void saveVotedIds(Set<String> ids) {
    try {
      html.window.localStorage[_key] = jsonEncode(ids.toList());
    } catch (_) {}
  }

  @override
  void clear() {
    try {
      html.window.localStorage.remove(_key);
    } catch (_) {}
  }
}

BaseVoteStorage getPlatformVoteStorage() => WebVoteStorage();
