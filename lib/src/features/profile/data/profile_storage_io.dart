import 'dart:convert';
import 'dart:io';

import 'profile_storage_stub.dart';

class IoProfileStorage implements BaseProfileStorage {
  File? get _file {
    try {
      final dir = Directory.systemTemp;
      return File('${dir.path}/belong_profile_session.json');
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? load() {
    try {
      final f = _file;
      if (f != null && f.existsSync()) {
        final content = f.readAsStringSync();
        return jsonDecode(content) as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  @override
  void save(Map<String, dynamic> data) {
    try {
      final f = _file;
      if (f != null) {
        f.writeAsStringSync(jsonEncode(data));
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

BaseProfileStorage getPlatformProfileStorage() => IoProfileStorage();
