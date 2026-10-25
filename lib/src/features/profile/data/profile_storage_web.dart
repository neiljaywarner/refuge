// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

import 'profile_storage_stub.dart';

class WebProfileStorage implements BaseProfileStorage {
  static const _key = 'belong_member_profile_session';

  @override
  Map<String, dynamic>? load() {
    try {
      final raw = html.window.localStorage[_key];
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  @override
  void save(Map<String, dynamic> data) {
    try {
      html.window.localStorage[_key] = jsonEncode(data);
    } catch (_) {}
  }

  @override
  void clear() {
    try {
      html.window.localStorage.remove(_key);
    } catch (_) {}
  }
}

BaseProfileStorage getPlatformProfileStorage() => WebProfileStorage();
