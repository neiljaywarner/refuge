import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/simple_sign_in_screen.dart';

void main() {
  test('register wall title names the community and does not say sign in', () {
    expect(
      signInWallTitle(AppFlavor.prod),
      'Sign in to Belong on the Spectrum',
    );
    expect(
      signInWallTitle(AppFlavor.prod, registering: true),
      'Belong on the Spectrum',
    );
    expect(
      signInWallTitle(AppFlavor.dev, registering: true),
      '[DEV] Belong on the Spectrum PREVIEW',
    );
    expect(
      signInWallTitle(AppFlavor.dev),
      '[DEV] Sign in to Belong on the Spectrum PREVIEW',
    );
  });
}
