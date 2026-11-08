/// Compile-time gate for the preview group call (#872).
///
/// Production release builds leave this off. A preview build turns it on
/// with `--dart-define=STREAM_VIDEO_PREVIEW=true`. The API secret is not a
/// dart-define and is not read here.
const bool streamVideoPreviewEnabled = bool.fromEnvironment('STREAM_VIDEO_PREVIEW');

const String _tokenEndpointDefine = String.fromEnvironment('STREAM_TOKEN_ENDPOINT');

/// True when this build may show the join entry.
bool groupCallEntryVisible({
  required bool compileTimePreview,
  required bool previewFeaturesEnabled,
  required bool signedIn,
}) => compileTimePreview && previewFeaturesEnabled && signedIn;

/// HTTPS token URL, or loopback HTTP for the local functions emulator.
/// Userinfo is rejected so a secret cannot hide in the URL.
Uri? parseStreamTokenEndpoint(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.userInfo.isNotEmpty) return null;
  if (uri.scheme == 'https' && uri.host.isNotEmpty) return uri;
  final loopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
  if (uri.scheme == 'http' && loopback) return uri;
  return null;
}

Uri? get streamTokenEndpoint => parseStreamTokenEndpoint(_tokenEndpointDefine);

/// Dart-defines for a dev preview build. Ignores [STREAM_API_KEY] and
/// [STREAM_API_SECRET] even when they are present in the environment.
List<String> streamVideoPreviewDartDefines(Map<String, String> environment) {
  if (environment['STREAM_VIDEO_PREVIEW']?.trim().toLowerCase() != 'true') {
    return const [];
  }
  final defines = <String>['--dart-define=STREAM_VIDEO_PREVIEW=true'];
  final endpoint = parseStreamTokenEndpoint(environment['STREAM_TOKEN_ENDPOINT'] ?? '');
  if (endpoint != null) {
    defines.add('--dart-define=STREAM_TOKEN_ENDPOINT=$endpoint');
  }
  return defines;
}

/// Presence-only log line. Does not print the endpoint or any secret.
String streamVideoPreviewDartDefinesLogLine(Map<String, String> environment) {
  final defines = streamVideoPreviewDartDefines(environment);
  if (defines.isEmpty) {
    return 'Stream video preview: off '
        '(set STREAM_VIDEO_PREVIEW=true to include the group call).';
  }
  final endpoint = defines.any(
    (define) => define.startsWith('--dart-define=STREAM_TOKEN_ENDPOINT='),
  );
  return 'Stream video preview: on. Token endpoint ${endpoint ? 'set' : 'missing'}. '
      'The API key and secret are not compiled into the app.';
}

String redactStreamVideoDartDefine(String arg) {
  const prefix = '--dart-define=STREAM_TOKEN_ENDPOINT=';
  if (arg.startsWith(prefix) && arg.length > prefix.length) {
    return '$prefix<redacted>';
  }
  return arg;
}
