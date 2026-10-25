import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/build/build_identity.dart';
import '../../../core/theme/belong_text_styles.dart';

/// Version and build number from the running package (pubspec via the platform).
class AppVersionLabel {
  const AppVersionLabel({this.version = '', this.buildNumber = ''});

  static const unknown = AppVersionLabel();

  final String version;
  final String buildNumber;

  bool get isKnown => version.trim().isNotEmpty;

  /// `v0.9.1+2`, or `v0.9.1` when there is no build number. Null when unknown.
  String? get titleSuffix {
    if (!isKnown) return null;
    final name = version.trim();
    final number = buildNumber.trim();
    if (number.isEmpty) return 'v$name';
    return 'v$name+$number';
  }

  String get versionLine => titleSuffix ?? 'unknown';
}

/// Reads [PackageInfo]. Returns [AppVersionLabel.unknown] if the platform
/// plugin is unavailable (widget tests, or a host without package metadata).
Future<AppVersionLabel> loadPackageVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.trim().isEmpty) return AppVersionLabel.unknown;
    return AppVersionLabel(
      version: info.version.trim(),
      buildNumber: info.buildNumber.trim(),
    );
  } catch (_) {
    return AppVersionLabel.unknown;
  }
}

/// Dialog title. Omits the version until [version] completes, and omits it
/// entirely when the package version is unknown.
class AboutDialogTitle extends StatelessWidget {
  const AboutDialogTitle({
    super.key,
    required this.version,
    required this.primaryColor,
    required this.isContrast,
  });

  final Future<AppVersionLabel> version;
  final Color primaryColor;
  final bool isContrast;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppVersionLabel>(
      future: version,
      builder: (context, snapshot) {
        final suffix = snapshot.connectionState == ConnectionState.done
            ? snapshot.data?.titleSuffix
            : null;
        final title = suffix == null
            ? 'Belong on the Spectrum'
            : 'Belong on the Spectrum ($suffix)';
        final titleStyle = BelongTextStyles.of(context).title.copyWith(
          color: isContrast ? const Color(0xFFFFEB3B) : primaryColor,
        );
        return Text(
          title,
          key: const Key('about_dialog_title'),
          style: titleStyle,
        );
      },
    );
  }
}

/// Calm, literal build identity under the scripture quote.
class AboutBuildStamp extends StatelessWidget {
  const AboutBuildStamp({
    super.key,
    required this.identity,
    required this.version,
  });

  final BuildIdentity identity;
  final Future<AppVersionLabel> version;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppVersionLabel>(
      future: version,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            key: const Key('about_build_stamp'),
            width: double.infinity,
            child: Text(
              'This build',
              style: BelongTextStyles.of(context).emphasis,
            ),
          );
        }
        final label = snapshot.data ?? AppVersionLabel.unknown;
        return _BuildStampBody(identity: identity, version: label);
      },
    );
  }
}

class _BuildStampBody extends StatelessWidget {
  const _BuildStampBody({required this.identity, required this.version});

  final BuildIdentity identity;
  final AppVersionLabel version;

  @override
  Widget build(BuildContext context) {
    final styles = BelongTextStyles.of(context);
    final release = identity.releaseTagOrNull;
    final commitUrl = identity.commitUrl;
    final source = identity.sourceLabel;
    return Column(
      key: const Key('about_build_stamp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This build', style: styles.emphasis),
        const Gap(4),
        Text(
          'Version: ${version.versionLine}',
          key: const Key('about_build_version'),
          style: styles.caption,
        ),
        SelectableText(
          'Git commit: ${identity.commitLabel}',
          key: const Key('about_build_commit'),
          style: styles.caption,
        ),
        Text(
          'Build time: ${identity.buildTimeLine}',
          key: const Key('about_build_time'),
          style: styles.caption,
        ),
        if (release != null)
          Text(
            'Release: $release',
            key: const Key('about_build_release'),
            style: styles.caption,
          ),
        if (commitUrl != null)
          SelectableText(
            commitUrl,
            key: const Key('about_build_commit_url'),
            style: styles.caption,
          ),
        if (source != null)
          Text(
            'Source: $source',
            key: const Key('about_build_source'),
            style: styles.caption,
          ),
      ],
    );
  }
}
