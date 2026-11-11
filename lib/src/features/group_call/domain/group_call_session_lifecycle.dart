/// Orders "leave the call, then release the seat" when the page closes
/// while Stream is still connecting.
///
/// [shutdown] waits for [connect]. A join that finishes after shutdown is
/// left before the seat is released. [releaseOnce] runs a single time.
class GroupCallSessionLifecycle {
  Future<void>? _connecting;
  bool _shutDown = false;
  bool _holding = false;
  Future<void>? _releaseFuture;
  Future<void>? _shutdownFuture;

  bool get shutDown => _shutDown;

  Future<void> connect({
    required Future<bool> Function() join,
    required Future<void> Function() leave,
    required void Function() onReady,
    required Future<void> Function() onFailure,
  }) {
    final pending = _connectBody(join: join, leave: leave, onReady: onReady, onFailure: onFailure);
    _connecting = pending;
    return pending;
  }

  Future<void> _connectBody({
    required Future<bool> Function() join,
    required Future<void> Function() leave,
    required void Function() onReady,
    required Future<void> Function() onFailure,
  }) async {
    var joined = false;
    try {
      joined = await join();
    } catch (_) {
      joined = false;
    }
    if (!joined) {
      try {
        await leave();
      } catch (_) {}
      if (!_shutDown) await onFailure();
      return;
    }
    if (_shutDown) {
      try {
        await leave();
      } catch (_) {}
      return;
    }
    _holding = true;
    onReady();
    if (_shutDown) {
      _holding = false;
      try {
        await leave();
      } catch (_) {}
    }
  }

  /// Leaves a call this lifecycle is holding, then releases the seat.
  Future<void> shutdown({
    required Future<void> Function() leave,
    required Future<void> Function() release,
  }) {
    final existing = _shutdownFuture;
    if (existing != null) return existing;
    _shutDown = true;
    final pending = _finishShutdown(leave: leave, release: release);
    _shutdownFuture = pending;
    return pending;
  }

  Future<void> _finishShutdown({
    required Future<void> Function() leave,
    required Future<void> Function() release,
  }) async {
    try {
      await _connecting;
    } catch (_) {}
    if (_holding) {
      _holding = false;
      try {
        await leave();
      } catch (_) {}
    }
    await releaseOnce(release);
  }

  Future<void> releaseOnce(Future<void> Function() release) {
    final existing = _releaseFuture;
    if (existing != null) return existing;
    final pending = release();
    _releaseFuture = pending;
    return pending;
  }
}
