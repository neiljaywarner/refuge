import 'vote_storage_stub.dart' show BaseVoteStorage;
import 'vote_storage_stub.dart'
    if (dart.library.io) 'vote_storage_io.dart'
    if (dart.library.html) 'vote_storage_web.dart';

/// Provides persistent local feature voting state across web page reloads,
/// app restarts, and offline sessions (#487, #500).
class VoteStorageService {
  VoteStorageService._();
  static final VoteStorageService instance = VoteStorageService._();

  final BaseVoteStorage _platformStorage = getPlatformVoteStorage();
  Set<String>? _memoryCache;

  Set<String> getVotedFeatureIds() {
    if (_memoryCache != null) return _memoryCache!;
    _memoryCache = _platformStorage.loadVotedIds();
    return _memoryCache!;
  }

  bool isFeatureVoted(String featureId) => getVotedFeatureIds().contains(featureId);

  void setFeatureVoted(String featureId, bool voted) {
    final current = Set<String>.from(getVotedFeatureIds());
    if (voted) {
      current.add(featureId);
    } else {
      current.remove(featureId);
    }
    _memoryCache = current;
    _platformStorage.saveVotedIds(current);
  }

  bool toggleFeatureVoted(String featureId) {
    final voted = !isFeatureVoted(featureId);
    setFeatureVoted(featureId, voted);
    return voted;
  }

  void clear() {
    _memoryCache = <String>{};
    _platformStorage.clear();
  }
}
