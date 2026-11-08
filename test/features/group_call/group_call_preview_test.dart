import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_video_preview_config.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_room.dart';

void main() {
  test('call names stay short and the link can name the room', () {
    expect(GroupCallRoom.tryParse(' Monthly ')?.id, 'monthly');
    expect(GroupCallRoom.tryParse('fellowship hour')?.id, 'fellowship-hour');
    expect(GroupCallRoom.tryParse('ab'), isNull);
    expect(GroupCallRoom.tryParse('bad--name'), isNull);
    expect(groupCallIdFromLocation(Uri.parse('https://preview.example/?call=Monthly')), 'monthly');
    expect(
      groupCallIdFromLocation(Uri.parse('https://preview.example/#/?call=fellowship-hour')),
      'fellowship-hour',
    );
    expect(groupCallIdFromLocation(Uri.parse('https://preview.example/')), GroupCallRoom.defaultId);
  });

  test('only the room creator or a host can end or remove someone', () {
    expect(canModerateGroupCall(createdByMe: true, roles: const []), isTrue);
    expect(canModerateGroupCall(createdByMe: false, roles: const ['host']), isTrue);
    expect(canModerateGroupCall(createdByMe: false, roles: const ['user']), isFalse);
  });

  test('preview defines never forward the Stream key or secret', () {
    final endpoint =
        'https://us-central1-belongonthespectrum.cloudfunctions.net/mintStreamCallToken';
    final defines = streamVideoPreviewDartDefines({
      'STREAM_VIDEO_PREVIEW': 'true',
      'STREAM_TOKEN_ENDPOINT': endpoint,
      'STREAM_API_KEY': 'not-a-real-key',
      'STREAM_API_SECRET': 'not-a-real-secret',
    });
    final joined = defines.join('\n');
    expect(joined, contains('--dart-define=STREAM_VIDEO_PREVIEW=true'));
    expect(joined, contains('--dart-define=STREAM_TOKEN_ENDPOINT=$endpoint'));
    expect(joined, isNot(contains('STREAM_API_KEY')));
    expect(joined, isNot(contains('STREAM_API_SECRET')));
    expect(joined, isNot(contains('not-a-real-key')));
    expect(joined, isNot(contains('not-a-real-secret')));
    expect(
      streamVideoPreviewDartDefines({
        'STREAM_VIDEO_PREVIEW': 'false',
        'STREAM_TOKEN_ENDPOINT': endpoint,
      }),
      isEmpty,
    );
    expect(parseStreamTokenEndpoint('http://example.com/token'), isNull);
    expect(parseStreamTokenEndpoint('https://user:secret@example.com/token'), isNull);
    expect(parseStreamTokenEndpoint('http://127.0.0.1:5001/token'), isNotNull);
    expect(
      redactStreamVideoDartDefine('--dart-define=STREAM_TOKEN_ENDPOINT=$endpoint'),
      '--dart-define=STREAM_TOKEN_ENDPOINT=<redacted>',
    );
    expect(
      streamVideoPreviewDartDefinesLogLine({'STREAM_VIDEO_PREVIEW': 'true'}),
      isNot(contains(endpoint)),
    );
  });

  test('the group call stays hidden until the preview build, the flag, and sign-in agree', () {
    expect(
      groupCallEntryVisible(compileTimePreview: true, previewFeaturesEnabled: true, signedIn: true),
      isTrue,
    );
    expect(
      groupCallEntryVisible(
        compileTimePreview: false,
        previewFeaturesEnabled: true,
        signedIn: true,
      ),
      isFalse,
    );
    expect(
      groupCallEntryVisible(
        compileTimePreview: true,
        previewFeaturesEnabled: false,
        signedIn: true,
      ),
      isFalse,
    );
    expect(
      groupCallEntryVisible(
        compileTimePreview: true,
        previewFeaturesEnabled: true,
        signedIn: false,
      ),
      isFalse,
    );
  });
}
