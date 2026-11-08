import 'client_session_audit_snapshot.dart';

/// Largest JSON body the admission server will read.
const sessionAuditMaxBodyBytes = 4096;

/// One client (one hashed caller key) may open a few sessions an hour.
const sessionAuditPerCallerLimit = 8;

const sessionAuditPerCallerWindow = Duration(hours: 1);

/// Stops a tight loop without blocking a busy Sunday open.
const sessionAuditProjectBurstLimit = 120;

const sessionAuditProjectBurstWindow = Duration(minutes: 10);

/// Caps this process near 10% of the Free plan's 250,000 monthly writes.
///
/// 800 writes per rolling day is about 24,800 in a 31-day month. Restarts
/// clear the in-memory counters, so run one admission process.
const sessionAuditProjectDailyLimit = 800;

const sessionAuditProjectDailyWindow = Duration(hours: 24);

const sessionAuditMaxCallerKeys = 4096;

const sessionAuditClockSkew = Duration(minutes: 5);

const sessionAuditMaxEventAge = Duration(hours: 36);

const sessionAuditFieldMax = <String, int>{
  'city': 128,
  'timezone': 128,
  'locale': 64,
  'osName': 32,
  'osVersion': 64,
  'appVersion': 32,
  'appBuild': 32,
  'platform': 32,
};

const sessionAuditPlatformValues = <String>{
  'android',
  'ios',
  'web',
  'linux',
  'macos',
  'windows',
  'fuchsia',
  'unknown',
};

final _rowIdPattern = RegExp(r'^[A-Za-z0-9]{1,36}$');

final _fullIpv6 = RegExp(r'^(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}$', caseSensitive: false);

/// True when [value] is an IPv6 address. The client sanitizer only drops IPv4.
bool sessionAuditLooksLikeIpv6(String value) {
  if (value.contains('::')) return true;
  return _fullIpv6.hasMatch(value);
}

/// Accepts a value only when it is already safe to store unchanged.
String? exactAuditText(String value, {required int max}) {
  if (value.length > max || value != value.trim()) return null;
  if (sessionAuditLooksLikeIpv6(value)) return null;
  final cleaned = sanitizeAuditText(value, max: max);
  if (cleaned != value) return null;
  return cleaned;
}

/// UTC timestamp inside the admission window, or null.
String? canonicalAuditTimestamp(String value, DateTime now) {
  final trimmed = value.trim();
  if (trimmed.length > 40 || trimmed != value) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  final utc = parsed.toUtc();
  final earliest = now.toUtc().subtract(sessionAuditMaxEventAge);
  final latest = now.toUtc().add(sessionAuditClockSkew);
  if (utc.isBefore(earliest) || utc.isAfter(latest)) return null;
  return utc.toIso8601String();
}

/// Validated start row. Null means the request must not be written.
Map<String, Object>? admittedStartRow(Object? row, DateTime now) {
  if (row is! Map) return null;
  final keys = <String>{};
  for (final key in row.keys) {
    if (key is! String || !keys.add(key)) return null;
  }
  const required = {'timezone', 'osName', 'appVersion', 'platform', 'sessionStartedAt'};
  if (!keys.containsAll(required)) return null;
  if (!sessionAuditRowKeys.containsAll(keys)) return null;

  final data = <String, Object>{};
  for (final key in keys) {
    final value = row[key];
    if (value is! String) return null;
    if (key == 'sessionStartedAt' || key == 'sessionEndedAt') {
      final canonical = canonicalAuditTimestamp(value, now);
      if (canonical == null) return null;
      data[key] = canonical;
      continue;
    }
    final max = sessionAuditFieldMax[key];
    if (max == null) return null;
    final cleaned = exactAuditText(value, max: max);
    if (cleaned == null) return null;
    if (key == 'platform' && !sessionAuditPlatformValues.contains(cleaned)) return null;
    data[key] = cleaned;
  }
  return data;
}

bool sessionAuditRowIdOk(String value) => _rowIdPattern.hasMatch(value);

/// In-memory write budget. Keys are opaque caller ids, not raw addresses.
class SessionAuditRateGate {
  SessionAuditRateGate({
    this.perCallerLimit = sessionAuditPerCallerLimit,
    this.perCallerWindow = sessionAuditPerCallerWindow,
    this.projectBurstLimit = sessionAuditProjectBurstLimit,
    this.projectBurstWindow = sessionAuditProjectBurstWindow,
    this.projectDailyLimit = sessionAuditProjectDailyLimit,
    this.projectDailyWindow = sessionAuditProjectDailyWindow,
    this.maxCallerKeys = sessionAuditMaxCallerKeys,
  });

  final int perCallerLimit;
  final Duration perCallerWindow;
  final int projectBurstLimit;
  final Duration projectBurstWindow;
  final int projectDailyLimit;
  final Duration projectDailyWindow;
  final int maxCallerKeys;

  final List<DateTime> _projectHits = [];
  final Map<String, List<DateTime>> _callerHits = {};

  /// Records one write when both the caller and the project are under cap.
  bool tryConsume(String callerKey, {required DateTime now}) {
    final instant = now.toUtc();
    _prune(instant);
    final caller = callerKey.trim().isEmpty ? 'missing' : callerKey.trim();
    final existing = _callerHits[caller];
    if (existing == null && _callerHits.length >= maxCallerKeys) return false;
    final callerHits = existing ?? <DateTime>[];
    if (_count(callerHits, instant, perCallerWindow) >= perCallerLimit) return false;
    if (_count(_projectHits, instant, projectBurstWindow) >= projectBurstLimit) return false;
    if (_count(_projectHits, instant, projectDailyWindow) >= projectDailyLimit) return false;
    callerHits.add(instant);
    _callerHits[caller] = callerHits;
    _projectHits.add(instant);
    return true;
  }

  void _prune(DateTime now) {
    final dailyCutoff = now.subtract(projectDailyWindow);
    _projectHits.removeWhere((hit) => hit.isBefore(dailyCutoff));
    final callerCutoff = now.subtract(perCallerWindow);
    final stale = <String>[];
    for (final entry in _callerHits.entries) {
      entry.value.removeWhere((hit) => hit.isBefore(callerCutoff));
      if (entry.value.isEmpty) stale.add(entry.key);
    }
    for (final key in stale) {
      _callerHits.remove(key);
    }
  }

  int _count(List<DateTime> hits, DateTime now, Duration window) {
    final cutoff = now.subtract(window);
    var count = 0;
    for (final hit in hits) {
      if (!hit.isBefore(cutoff)) count += 1;
    }
    return count;
  }
}

/// Creates and ends rows. The Appwrite key stays behind this interface.
abstract class SessionAuditRowWriter {
  Future<String> createRow(Map<String, Object> data);

  Future<void> markEnded({required String rowId, required String sessionEndedAt});
}

/// Issues and checks the opaque token that lets a client end its own row.
abstract class SessionAuditEndTokens {
  String issue(String rowId);

  bool accepts({required String rowId, required String token});
}

class SessionAuditHttpReply {
  const SessionAuditHttpReply({required this.status, required this.body});

  final int status;
  final Map<String, Object?> body;
}

/// Validates one request, applies the write budget, then asks [writer] to store it.
class SessionAuditAdmission {
  SessionAuditAdmission({
    required this.gate,
    required this.tokens,
    this.writer,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SessionAuditRateGate gate;
  final SessionAuditEndTokens tokens;
  final SessionAuditRowWriter? writer;
  final DateTime Function() _clock;

  Future<SessionAuditHttpReply> handle({required Object? body, required String callerKey}) async {
    final now = _clock().toUtc();
    if (body is! Map) return _rejected();
    final action = body['action'];
    final keys = <String>{};
    for (final key in body.keys) {
      if (key is! String || !keys.add(key)) return _rejected();
    }
    if (action == 'start') return _start(body, keys, callerKey, now);
    if (action == 'end') return _end(body, keys, callerKey, now);
    return _rejected();
  }

  Future<SessionAuditHttpReply> _start(
    Map<dynamic, dynamic> body,
    Set<String> keys,
    String callerKey,
    DateTime now,
  ) async {
    if (keys.length != 2 || !keys.contains('row')) return _rejected();
    final row = admittedStartRow(body['row'], now);
    if (row == null) return _rejected();
    final writer = this.writer;
    if (writer == null) return _unavailable(503);
    if (!gate.tryConsume(callerKey, now: now)) return _rateLimited();
    try {
      final rowId = await writer.createRow(row);
      if (!sessionAuditRowIdOk(rowId)) return _unavailable(502);
      return SessionAuditHttpReply(
        status: 200,
        body: {'rowId': rowId, 'endToken': tokens.issue(rowId)},
      );
    } catch (_) {
      return _unavailable(502);
    }
  }

  Future<SessionAuditHttpReply> _end(
    Map<dynamic, dynamic> body,
    Set<String> keys,
    String callerKey,
    DateTime now,
  ) async {
    const expected = {'action', 'rowId', 'endToken', 'sessionEndedAt'};
    if (keys.length != expected.length || !keys.containsAll(expected)) return _rejected();
    final rowId = body['rowId'];
    final token = body['endToken'];
    final ended = body['sessionEndedAt'];
    if (rowId is! String || token is! String || ended is! String) return _rejected();
    if (!sessionAuditRowIdOk(rowId) || token.isEmpty || token.length > 128) return _rejected();
    if (!tokens.accepts(rowId: rowId, token: token)) return _rejected();
    final canonical = canonicalAuditTimestamp(ended, now);
    if (canonical == null) return _rejected();
    final writer = this.writer;
    if (writer == null) return _unavailable(503);
    if (!gate.tryConsume(callerKey, now: now)) return _rateLimited();
    try {
      await writer.markEnded(rowId: rowId, sessionEndedAt: canonical);
      return const SessionAuditHttpReply(status: 200, body: {'ok': true});
    } catch (_) {
      return _unavailable(502);
    }
  }

  SessionAuditHttpReply _rejected() =>
      const SessionAuditHttpReply(status: 400, body: {'error': 'rejected'});

  SessionAuditHttpReply _rateLimited() =>
      const SessionAuditHttpReply(status: 429, body: {'error': 'rate_limited'});

  SessionAuditHttpReply _unavailable(int status) =>
      SessionAuditHttpReply(status: status, body: const {'error': 'unavailable'});
}
