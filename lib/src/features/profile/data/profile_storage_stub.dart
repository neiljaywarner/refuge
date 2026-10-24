abstract class BaseProfileStorage {
  Map<String, dynamic>? load();
  void save(Map<String, dynamic> data);
  void clear();
}

BaseProfileStorage getPlatformProfileStorage() =>
    throw UnsupportedError('Cannot create profile storage on this platform');
