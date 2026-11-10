import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'video call lobby, guest join, controls, and participant grid at large text',
    () {},
    skip:
        'Group call UI is not on main. Lobby, guest join, in-call controls, '
        'and the participant grid live on unmerged PR #905 '
        '(branch cursor/stream-guest-join-2e7c). Large-text coverage for those '
        'screens is a follow-up after that branch merges. See #927.',
  );
}
