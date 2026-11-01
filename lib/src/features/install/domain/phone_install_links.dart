/// Which phone-install section to show first.
enum PhoneInstallFocus { android, ios }

/// Official pages for the member install guide.
///
/// [androidBeta] is Belong's ongoing Firebase App Distribution app, not one
/// release and not a Play Store listing. Play Store, App Store, and
/// TestFlight stay pending until those listings exist.
abstract final class PhoneInstallLinks {
  static const belongWeb = 'https://belongonthespectrum.web.app';

  /// Belong Android open beta. The same page covers later beta releases.
  static const androidBeta =
      'https://appdistribution.firebase.google.com/testerapps/'
      '1:207506875171:android:e578634c4bc21da2b96296';

  /// Google's own tester steps, including the optional App Tester app.
  static const firebaseTesterHelp =
      'https://firebase.google.com/docs/app-distribution/get-set-up-as-a-tester?platform=android';

  /// Google's note for the "can't install unknown apps" alert.
  static const firebaseUnknownApps =
      'https://firebase.google.com/docs/app-distribution/troubleshooting?platform=android';

  /// Pixel Phone Help: download apps from other sources, then turn the
  /// permission off again.
  static const googleInstallUnknownApps =
      'https://support.google.com/pixelphone/answer/7391672?hl=en';

  /// Android Help: leave Play Protect on.
  static const playProtect = 'https://support.google.com/android/answer/2812853?hl=en';

  /// Chrome Help: install a website as an app on Android.
  static const chromeWebApp =
      'https://support.google.com/chrome/answer/9658361?co=GENIE.Platform%3DAndroid';

  /// iPhone User Guide: turn a website into an app.
  static const appleWebApp =
      'https://support.apple.com/guide/iphone/open-as-web-app-iphea86e5236/ios';

  /// Apple's TestFlight page. Belong's TestFlight link is not open yet.
  static const appleTestFlight = 'https://developer.apple.com/testflight/';
}
