import 'package:flutter/foundation.dart';

import '../../../core/config/app_flavor.dart';

/// Where a member-feedback note was submitted.
///
/// Preview and production share `neiljaywarner/belong_feedback`, so every
/// note records one of `production`, `preview`, `dev`, or `local`.
///
/// Web uses the page host, not the compile-time flavor. A prod build
/// (`FLAVOR=prod`) on a Firebase Hosting preview channel is `preview`.
///
/// Host rules, compared to the lowercased host:
/// - `localhost`, `127.0.0.1`, `0.0.0.0`, `::1`, or an empty host → `local`
/// - `belongonthespectrum.web.app` or
///   `belongonthespectrum.firebaseapp.com` → `production`
/// - `dev-`, `stg-`, or `qa-` plus `belongonthespectrum.web.app` /
///   `.firebaseapp.com` → `dev`
/// - `belongonthespectrum--<channel>.web.app` or `.firebaseapp.com` →
///   `preview`
/// - any other website → `preview`
///
/// Android, iOS, and desktop use the flavor instead of a device name.
/// `FLAVOR=prod` → `production`. Every other flavor → `dev`.
/// [sourceHost] for a native build is that flavor's hosting hostname.
class const FeedbackSourceStamp({
  required final String sourceEnvironment,
  required final String sourceHost,
  required final String sourceUrl,
}) {
  static const production = FeedbackSourceStamp(
    sourceEnvironment: 'production',
    sourceHost: 'belongonthespectrum.web.app',
    sourceUrl: 'https://belongonthespectrum.web.app',
  );

  static const _productionHosts = {
    'belongonthespectrum.web.app',
    'belongonthespectrum.firebaseapp.com',
  };

  static const _localHosts = {'localhost', '127.0.0.1', '0.0.0.0', '::1', '[::1]'};

  static final _namedDevSite = RegExp(
    r'^(dev|stg|qa)-belongonthespectrum\.(web\.app|firebaseapp\.com)$',
  );

  static final _previewChannel = RegExp(
    r'^belongonthespectrum--[a-z0-9-]+\.(web\.app|firebaseapp\.com)$',
  );

  static const _compileTimeFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  /// Title prefix such as `[preview] `, or empty for production.
  String get titlePrefix => switch (sourceEnvironment) {
    'production' => '',
    'dev' => '[dev] ',
    'local' => '[local] ',
    _ => '[preview] ',
  };

  /// Extra GitHub label. Production has none. Unknown values use `preview`.
  List<String> get issueLabels => switch (sourceEnvironment) {
    'production' => const <String>[],
    'dev' => const ['dev'],
    'local' => const ['local'],
    _ => const ['preview'],
  };

  /// Stamp for the running app. Tests pass [isWeb], [pageUri], and [flavor].
  static FeedbackSourceStamp current({bool? isWeb, Uri? pageUri, String? flavor}) {
    final web = isWeb ?? kIsWeb;
    if (web) return fromWebUri(pageUri ?? Uri.base);
    return fromFlavor(flavor ?? _compileTimeFlavor);
  }

  static FeedbackSourceStamp fromWebUri(Uri uri) {
    final host = _normalizeHost(uri.host);
    final environment = environmentForWebHost(host);
    return FeedbackSourceStamp(
      sourceEnvironment: environment,
      sourceHost: host.isEmpty ? 'localhost' : host,
      sourceUrl: _origin(uri, host),
    );
  }

  static FeedbackSourceStamp fromFlavor(String flavor) {
    final parsed = AppFlavor.fromString(flavor);
    final environment = parsed.isProduction ? 'production' : 'dev';
    return FeedbackSourceStamp(
      sourceEnvironment: environment,
      sourceHost: parsed.domainHost,
      sourceUrl: parsed.firebaseHostingUrl,
    );
  }

  /// One of `production`, `preview`, `dev`, or `local`.
  static String environmentForWebHost(String host) {
    final normalized = _normalizeHost(host);
    if (normalized.isEmpty || _localHosts.contains(normalized)) return 'local';
    if (_productionHosts.contains(normalized)) return 'production';
    if (_namedDevSite.hasMatch(normalized)) return 'dev';
    if (_previewChannel.hasMatch(normalized)) return 'preview';
    return 'preview';
  }

  static String _normalizeHost(String host) =>
      host.trim().toLowerCase().replaceAll(RegExp(r'\.$'), '');

  static String _origin(Uri uri, String host) {
    if (host.isEmpty) return 'http://localhost';
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    final defaultPort = scheme == 'https' ? 443 : 80;
    final port = uri.hasPort && uri.port != defaultPort ? ':${uri.port}' : '';
    return '$scheme://$host$port';
  }
}
