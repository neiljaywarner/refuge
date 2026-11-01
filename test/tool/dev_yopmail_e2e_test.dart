import 'package:flutter_test/flutter_test.dart';

import '../../tool/dev_yopmail_e2e.dart';

void main() {
  test('timestamped address stays on yopmail', () {
    expect(timestampedYopmailAddress(1700000000000), 'belong1700000000000@yopmail.com');
  });

  test('firebaseActionLink reads a firebase action url', () {
    const html =
        '<a href="https://belongonthespectrum.firebaseapp.com/__/auth/action?mode=verifyEmail&amp;oobCode=abc">confirm</a>';
    expect(
      firebaseActionLink(html),
      'https://belongonthespectrum.firebaseapp.com/__/auth/action?mode=verifyEmail&oobCode=abc',
    );
  });

  test('firebaseActionLink returns null when the inbox is empty', () {
    expect(firebaseActionLink('<p>no mail</p>'), isNull);
  });
}
