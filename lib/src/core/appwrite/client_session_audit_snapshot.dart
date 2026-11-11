/// Keys allowed on `client_session_audits`. Anything else is PII or unused.
const sessionAuditRowKeys = <String>{
  'city',
  'timezone',
  'locale',
  'osName',
  'osVersion',
  'appVersion',
  'appBuild',
  'platform',
  'sessionStartedAt',
  'sessionEndedAt',
};

final _email = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
final _ipv4 = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');

/// Drops blank, email, and IPv4 values. Returns null when nothing safe remains.
String? sanitizeAuditText(String? value, {required int max}) {
  if (value == null) return null;
  final trimmed = value.replaceAll(RegExp(r'[\r\n\t]'), ' ').trim();
  if (trimmed.isEmpty || _email.hasMatch(trimmed) || _ipv4.hasMatch(trimmed)) {
    return null;
  }
  if (trimmed.length <= max) return trimmed;
  final cut = trimmed.substring(0, max).trimRight();
  if (cut.isEmpty) return null;
  return cut;
}

/// `DateTime.timeZoneName`, or a UTC offset when the name is blank.
String auditTimezoneLabel(DateTime now) {
  final name = now.timeZoneName.trim();
  if (name.isNotEmpty) return name;
  final offset = now.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final abs = offset.abs();
  final hours = abs.inHours.toString().padLeft(2, '0');
  final minutes = (abs.inMinutes % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hours:$minutes';
}

/// `android`, `ios`, or `web`. Desktop Flutter targets keep their OS name.
String sessionAuditPlatform({required bool isWeb, required String osName}) {
  if (isWeb) return 'web';
  return switch (osName.toLowerCase()) {
    'android' => 'android',
    'ios' => 'ios',
    'linux' || 'macos' || 'windows' || 'fuchsia' => osName.toLowerCase(),
    _ => 'unknown',
  };
}

/// Coarse place label. Country code first. An IANA zone city is the fallback.
///
/// Never call location APIs for this. GPS and IP addresses stay off the row.
String? coarseSessionCity({String? countryCode, required String timezone}) {
  final country = sanitizeAuditText(countryCode?.toUpperCase(), max: 128);
  if (country != null) return country;
  final slash = timezone.lastIndexOf('/');
  if (slash <= 0 || slash >= timezone.length - 1) return null;
  final label = timezone.substring(slash + 1).replaceAll('_', ' ');
  return sanitizeAuditText(label, max: 128);
}

/// One non-PII session-start row for `client_session_audits`.
class ClientSessionAuditSnapshot({
  required final String timezone,
  required final String osName,
  required final String appVersion,
  required final String platform,
  required final DateTime sessionStartedAt,
  final String? city,
  final String? locale,
  final String? osVersion,
  final String? appBuild,
  final DateTime? sessionEndedAt,
}) {
  Map<String, Object> toRowData() {
    final data = <String, Object>{
      'timezone': timezone,
      'osName': osName,
      'appVersion': appVersion,
      'platform': platform,
      'sessionStartedAt': sessionStartedAt.toUtc().toIso8601String(),
    };
    _add(data, 'city', city);
    _add(data, 'locale', locale);
    _add(data, 'osVersion', osVersion);
    _add(data, 'appBuild', appBuild);
    final ended = sessionEndedAt;
    if (ended != null) {
      data['sessionEndedAt'] = ended.toUtc().toIso8601String();
    }
    return data;
  }

  static void _add(Map<String, Object> data, String key, String? value) {
    if (value == null || value.isEmpty) return;
    data[key] = value;
  }
}

/// Builds a snapshot from already-collected facts. Safe to call in tests.
ClientSessionAuditSnapshot buildClientSessionAuditSnapshot({
  required DateTime now,
  required String osName,
  required String? osVersion,
  required String appVersion,
  required String? appBuild,
  required bool isWeb,
  String? countryCode,
  String? localeTag,
}) {
  final timezone = sanitizeAuditText(auditTimezoneLabel(now), max: 128) ?? 'UTC';
  final platform =
      sanitizeAuditText(sessionAuditPlatform(isWeb: isWeb, osName: osName), max: 32) ?? 'unknown';
  return ClientSessionAuditSnapshot(
    timezone: timezone,
    osName: sanitizeAuditText(isWeb ? 'web' : osName, max: 32) ?? 'unknown',
    appVersion: sanitizeAuditText(appVersion, max: 32) ?? 'unknown',
    platform: platform,
    sessionStartedAt: now.toUtc(),
    city: coarseSessionCity(countryCode: countryCode, timezone: timezone),
    locale: sanitizeAuditText(localeTag, max: 64),
    osVersion: isWeb ? null : sanitizeAuditText(osVersion, max: 64),
    appBuild: sanitizeAuditText(appBuild, max: 32),
  );
}
