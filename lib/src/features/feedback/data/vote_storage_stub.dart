abstract class BaseVoteStorage {
  Set<String> loadVotedIds();
  void saveVotedIds(Set<String> ids);
  void clear();
}

BaseVoteStorage getPlatformVoteStorage() =>
    throw UnsupportedError('Cannot create vote storage on this platform');
