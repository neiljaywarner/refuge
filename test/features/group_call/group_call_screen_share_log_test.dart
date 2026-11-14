import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share_log.dart';

void main() {
  test('[#screenshare] lines stay grepable and drop emails and tokens', () {
    final line = groupCallScreenShareLine(
      '${groupCallScreenShareRequest(enabled: true, platform: GroupCallSharePlatform.web, granted: true, guest: false)} '
      'member@belongonthespectrum.com eyJhbGciOiJIUzI1NiJ9.aaa.bbb',
    );

    expect(line, startsWith('[#screenshare] '));
    expect(line.contains('@'), isFalse);
    expect(line.contains('eyJ'), isFalse);
    expect(line.contains('hbGci'), isFalse);
    expect(line.contains('aaa'), isFalse);
    expect(line.contains('bbb'), isFalse);
    expect(line, contains('platform=web'));
    expect(line, contains('granted=true'));
    expect(line, contains('guest=false'));
  });

  test('share result and view lines do not carry a name', () {
    expect(
      groupCallScreenShareResult(enabled: false, accepted: true),
      'result enabled=false accepted=true',
    );
    expect(
      groupCallScreenShareViewLine(someoneSharing: true, localSharing: false),
      'view someoneSharing=true localSharing=false',
    );
  });
}
