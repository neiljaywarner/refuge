/// Which phone-install section to show first.
enum PhoneInstallFocus { android, ios }

/// Official pages for the member install guide.
///
/// The Android button opens Google's Firebase App Distribution tester home.
/// A per-release invite hash is not published in this repo, so the guide does
/// not invent one. Play Store, App Store, and TestFlight stay pending.
abstract final class PhoneInstallLinks {
  static const belongWeb = 'https://belongonthespectrum.web.app';

  /// Sign-in page testers open on the Android phone.
  static const androidBeta = 'https://appdistribution.firebase.google.com';

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
  static const playProtect =
      'https://support.google.com/android/answer/2812853?hl=en';

  /// Chrome Help: install a website as an app on Android.
  static const chromeWebApp =
      'https://support.google.com/chrome/answer/9658361?co=GENIE.Platform%3DAndroid';

  /// iPhone User Guide: turn a website into an app.
  static const appleWebApp =
      'https://support.apple.com/guide/iphone/open-as-web-app-iphea86e5236/ios';

  /// Apple's TestFlight page. Belong's TestFlight link is not open yet.
  static const appleTestFlight = 'https://developer.apple.com/testflight/';
}
