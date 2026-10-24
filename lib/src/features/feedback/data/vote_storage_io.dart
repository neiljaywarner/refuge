import 'dart:convert';
import 'dart:io';

import 'vote_storage_stub.dart';

class IoVoteStorage implements BaseVoteStorage {
  File? get _file {
    try {
      final dir = Directory.systemTemp;
      return File('${dir.path}/belong_feature_votes_session.json');
    } catch (_) {
      return null;
    }
  }

  @override
  Set<String> loadVotedIds() {
    try {
      final f = _file;
      if (f != null && f.existsSync()) {
        final content = f.readAsStringSync();
        final decoded = jsonDecode(content);
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
      final f = _file;
      if (f != null) {
        f.writeAsStringSync(jsonEncode(ids.toList()));
      }
    } catch (_) {}
  }

  @override
  void clear() {
    try {
      final f = _file;
      if (f != null && f.existsSync()) {
        f.deleteSync();
      }
    } catch (_) {}
  }
}

BaseVoteStorage getPlatformVoteStorage() => IoVoteStorage();
