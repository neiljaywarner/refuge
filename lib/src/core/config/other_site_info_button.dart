import 'package:flutter/material.dart';

import 'app_flavor.dart';

/// Copy for the info control that names this Hosting site and the other one.
class OtherSiteNotice {
  const OtherSiteNotice({
    required this.hereLabel,
    required this.hereUrl,
    required this.otherLabel,
    required this.otherUrl,
  });

  factory OtherSiteNotice.forFlavor(AppFlavor flavor) {
    final hereIsPublic = flavor.isProduction;
    final other = hereIsPublic ? AppFlavor.dev : AppFlavor.prod;
    return OtherSiteNotice(
      hereLabel: hereIsPublic ? 'public site' : 'development site',
      hereUrl: flavor.websiteUrl,
      otherLabel: hereIsPublic ? 'development site' : 'public site',
      otherUrl: other.websiteUrl,
    );
  }

  final String hereLabel;
  final String hereUrl;
  final String otherLabel;
  final String otherUrl;

  String get message =>
      'You are on the $hereLabel ($hereUrl). '
      'The $otherLabel is $otherUrl. '
      'The development site updates when the main branch changes. '
      'The public site updates when a release is published.';
}

/// Small info icon. Opens a dialog with this site and the other site's URL.
class OtherSiteInfoButton extends StatelessWidget {
  const OtherSiteInfoButton({super.key, this.flavor});

  /// Defaults to the compile-time `FLAVOR` dart-define, which is `dev`
  /// when the define is absent.
  final AppFlavor? flavor;

  @override
  Widget build(BuildContext context) {
    final notice = OtherSiteNotice.forFlavor(flavor ?? _compileTimeFlavor);
    return IconButton(
      key: const Key('other_site_info_button'),
      tooltip: 'Which site is this?',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Which site is this?'),
            content: SelectableText(notice.message),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          ),
        );
      },
    );
  }
}

AppFlavor get _compileTimeFlavor {
  const envFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  return AppFlavor.fromString(envFlavor);
}
