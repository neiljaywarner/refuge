import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/phone_install_links.dart';

/// Calm member guide for the Android open beta, the pending stores, and the
/// website-on-your-home-screen steps (#737).
class PhoneInstallGuideView extends StatefulWidget {
  const PhoneInstallGuideView({super.key, required this.focus});

  final PhoneInstallFocus focus;

  @override
  State<PhoneInstallGuideView> createState() => _PhoneInstallGuideViewState();
}

class _PhoneInstallGuideViewState extends State<PhoneInstallGuideView> {
  final _androidBetaKey = GlobalKey();
  final _playKey = GlobalKey();
  final _appStoreKey = GlobalKey();
  final _testFlightKey = GlobalKey();
  final _iosWebKey = GlobalKey();
  final _androidWebKey = GlobalKey();

  late final Set<String> _open = {
    widget.focus == PhoneInstallFocus.ios ? 'ios-web' : 'android-beta',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reveal(
        widget.focus == PhoneInstallFocus.ios ? _iosWebKey : _androidBetaKey,
      );
    });
  }

  Future<void> _reveal(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      alignment: 0.05,
    );
  }

  void _jump(String id, GlobalKey key) {
    setState(() => _open.add(id));
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(key));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Get Belong on your phone')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Summary(theme: theme),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Jump(
                        key: const ValueKey('phone_install_jump_android'),
                        label: 'Android app',
                        onTap: () => _jump('android-beta', _androidBetaKey),
                      ),
                      _Jump(
                        key: const ValueKey('phone_install_jump_play'),
                        label: 'Play Store',
                        onTap: () => _jump('play', _playKey),
                      ),
                      _Jump(
                        key: const ValueKey('phone_install_jump_app_store'),
                        label: 'App Store',
                        onTap: () => _jump('app-store', _appStoreKey),
                      ),
                      _Jump(
                        key: const ValueKey('phone_install_jump_testflight'),
                        label: 'TestFlight',
                        onTap: () => _jump('testflight', _testFlightKey),
                      ),
                      _Jump(
                        key: const ValueKey('phone_install_jump_ios_web'),
                        label: 'iPhone website',
                        onTap: () => _jump('ios-web', _iosWebKey),
                      ),
                      _Jump(
                        key: const ValueKey('phone_install_jump_android_web'),
                        label: 'Android website',
                        onTap: () => _jump('android-web', _androidWebKey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Section(
                    key: _androidBetaKey,
                    sectionKey: const ValueKey('phone_install_android_beta'),
                    title: 'Android app',
                    status: 'Ready',
                    pending: false,
                    blurb: 'This is the one to use day to day. Tap the button on your Android phone.',
                    expanded: _open.contains('android-beta'),
                    onToggle: () => _toggle('android-beta'),
                    leading: FilledButton.icon(
                      key: const ValueKey('phone_install_open_beta_button'),
                      onPressed: () =>
                          openPhoneInstallLink(PhoneInstallLinks.androidBeta),
                      icon: const Icon(Icons.android_rounded),
                      label: const Text('Open the Android beta'),
                    ),
                    more: const _AndroidBetaMore(),
                  ),
                  _Section(
                    key: _playKey,
                    sectionKey: const ValueKey('phone_install_play_pending'),
                    title: 'Google Play Store',
                    status: 'Pending',
                    pending: true,
                    blurb: 'Searching the Play Store will not find Belong yet.',
                    expanded: _open.contains('play'),
                    onToggle: () => _toggle('play'),
                    more: const Text(
                      'When the Play Store listing is ready, this row will open it. Until then, the Android beta above is the real app.',
                    ),
                  ),
                  _Section(
                    key: _appStoreKey,
                    sectionKey: const ValueKey(
                      'phone_install_app_store_pending',
                    ),
                    title: 'Apple App Store',
                    status: 'Pending',
                    pending: true,
                    blurb: 'Searching the App Store will not find Belong yet.',
                    expanded: _open.contains('app-store'),
                    onToggle: () => _toggle('app-store'),
                    more: const Text(
                      'There is no iPhone app to download today. The website steps below are how iPhone members use Belong until the App Store opens.',
                    ),
                  ),
                  _Section(
                    key: _testFlightKey,
                    sectionKey: const ValueKey(
                      'phone_install_testflight_pending',
                    ),
                    title: 'iPhone beta (TestFlight)',
                    status: 'Pending',
                    pending: true,
                    blurb:
                        'Apple’s try-it-early app is not open for Belong yet.',
                    expanded: _open.contains('testflight'),
                    onToggle: () => _toggle('testflight'),
                    more: const _TestFlightMore(),
                  ),
                  _Section(
                    key: _iosWebKey,
                    sectionKey: const ValueKey('phone_install_ios_web'),
                    title: 'iPhone and iPad website',
                    status: 'Ready',
                    pending: false,
                    blurb: 'This is how you use Belong on an iPhone today.',
                    expanded: _open.contains('ios-web'),
                    onToggle: () => _toggle('ios-web'),
                    more: const _IosWebMore(),
                  ),
                  _Section(
                    key: _androidWebKey,
                    sectionKey: const ValueKey('phone_install_android_web'),
                    title: 'Android website',
                    status: 'For testing',
                    pending: false,
                    blurb: 'You only need this if you are testing the website. The Android app above is the everyday choice.',
                    expanded: _open.contains('android-web'),
                    onToggle: () => _toggle('android-web'),
                    more: const _AndroidWebMore(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (_open.contains(id)) {
        _open.remove(id);
      } else {
        _open.add(id);
      }
    });
  }
}

Future<void> openPhoneInstallLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {
    // Widget tests and locked-down browsers have no handler.
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Card(
      key: const ValueKey('phone_install_summary'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A short version', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Belong already works in the browser. The Android phone app is the nicer everyday choice. GIF search there can include stickers, clips, and emoji, and message alerts are more reliable. The iPhone app is not ready, so iPhone members keep using the website.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Firebase is just the Google page that hands you the Android app before the Play Store. You do not need to learn it. A beta means the app works and we are still polishing it. A home-screen website looks like an app, but it is still the website.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Jump extends StatelessWidget {
  const _Jump({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      ActionChip(label: Text(label), onPressed: onTap);
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.status,
    required this.pending,
    required this.blurb,
    required this.expanded,
    required this.onToggle,
    required this.more,
    this.leading,
  });

  final Key sectionKey;
  final String title;
  final String status;
  final bool pending;
  final String blurb;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget more;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Card(
      key: sectionKey,
      elevation: 0,
      margin: const EdgeInsets.only(top: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: pending
                        ? theme.colorScheme.surfaceContainerHighest
                        : primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pending
                          ? theme.colorScheme.onSurfaceVariant
                          : primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              blurb,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            if (leading != null) ...[const SizedBox(height: 10), leading!],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onToggle,
                child: Text(expanded ? 'Hide the details' : 'More about this'),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DefaultTextStyle.merge(
                  style: theme.textTheme.bodyMedium!.copyWith(height: 1.4),
                  child: more,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AndroidBetaMore extends StatelessWidget {
  const _AndroidBetaMore();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '1. On your Android phone, tap Open the Android beta. A computer cannot install it onto the phone for you.',
      ),
      SizedBox(height: 6),
      Text(
        '2. Sign in with a Google account if it asks. A Gmail address is fine. You do not create a Firebase account.',
      ),
      SizedBox(height: 6),
      Text(
        '3. When you see Belong on the Spectrum, tap Download. Google may also offer an app called Firebase App Tester. That app is Google’s. It keeps this download in one place. It is optional.',
      ),
      SizedBox(height: 6),
      Text(
        '4. The phone may say it cannot install unknown apps. That warning is normal, because Belong is not in the Play Store yet. Tap Settings on that message, then turn on Allow from this source. That allows only the app you are using right now, usually Chrome or Firebase App Tester. It does not open installs for the whole phone.',
      ),
      SizedBox(height: 6),
      Text(
        '5. Go back and tap Install. Belong shows up with your other apps. When you are finished, you can turn Allow from this source off again.',
      ),
      SizedBox(height: 6),
      Text(
        '6. Leave Google Play Protect on. It may say it does not recognize Belong yet. If the warning says the app is harmful, stop and do not install it.',
      ),
      SizedBox(height: 6),
      Text(
        'If the page says you have no apps yet, the open invite is still catching up. Use the Android website steps for today, and tell an organizer.',
      ),
      SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _DocLink(
            label: 'Google’s install steps',
            url: PhoneInstallLinks.googleInstallUnknownApps,
          ),
          _DocLink(
            label: 'Firebase’s tester steps',
            url: PhoneInstallLinks.firebaseTesterHelp,
          ),
          _DocLink(
            label: 'If the phone blocks the install',
            url: PhoneInstallLinks.firebaseUnknownApps,
          ),
          _DocLink(
            label: 'About Play Protect',
            url: PhoneInstallLinks.playProtect,
          ),
        ],
      ),
    ],
  );
}

class _TestFlightMore extends StatelessWidget {
  const _TestFlightMore();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'TestFlight is Apple’s app for trying an iPhone app before it is in the App Store. Belong does not have a TestFlight link yet. When it does, this row will stop saying Pending.',
      ),
      SizedBox(height: 8),
      _DocLink(
        label: 'Apple’s TestFlight page',
        url: PhoneInstallLinks.appleTestFlight,
      ),
    ],
  );
}

class _IosWebMore extends StatelessWidget {
  const _IosWebMore();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Use Safari. Chrome on iPhone cannot add Belong the same way.'),
      SizedBox(height: 6),
      Text('1. Open Safari and go to belongonthespectrum.web.app.'),
      SizedBox(height: 6),
      Text(
        '2. Tap Share. It is a square with an arrow. On iPhone it is usually at the bottom. On iPad it may be at the top.',
      ),
      SizedBox(height: 6),
      Text(
        '3. Scroll the list and tap Add to Home Screen. If you do not see it, scroll to the bottom, tap Edit Actions, and add it.',
      ),
      SizedBox(height: 6),
      Text(
        '4. Turn on Open as Web App if you see that switch. The name should say Belong on the Spectrum. Tap Add.',
      ),
      SizedBox(height: 6),
      Text(
        '5. Tap the Belong icon on your Home Screen. It opens without Safari’s address bar.',
      ),
      SizedBox(height: 6),
      Text(
        'GIF search on the website is simpler: still pictures, without stickers, clips, or emoji. Those are in the phone apps. Message alerts are also more reliable once the iPhone app exists. Until TestFlight and the App Store open, this Home Screen icon is the way to use Belong.',
      ),
      SizedBox(height: 8),
      _DocLink(
        label: 'Apple’s Home Screen steps',
        url: PhoneInstallLinks.appleWebApp,
      ),
      _DocLink(label: 'Open Belong', url: PhoneInstallLinks.belongWeb),
    ],
  );
}

class _AndroidWebMore extends StatelessWidget {
  const _AndroidWebMore();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'You only need this if you are testing the website. The Android app is fine for everyday use, and GIF search and message alerts work better there.',
        key: ValueKey('phone_install_android_web_testing_note'),
      ),
      SizedBox(height: 6),
      Text('1. Open Chrome and go to belongonthespectrum.web.app.'),
      SizedBox(height: 6),
      Text('2. Tap the three dots at the top.'),
      SizedBox(height: 6),
      Text('3. Tap Install app, or Add to Home screen, then Install.'),
      SizedBox(height: 6),
      Text(
        '4. The Belong icon appears on your Home Screen and in the app list. It is still the website.',
      ),
      SizedBox(height: 8),
      _DocLink(
        label: 'Chrome’s install steps',
        url: PhoneInstallLinks.chromeWebApp,
      ),
      _DocLink(label: 'Open Belong', url: PhoneInstallLinks.belongWeb),
    ],
  );
}

class _DocLink extends StatelessWidget {
  const _DocLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => openPhoneInstallLink(url),
    child: Text(label),
  );
}
