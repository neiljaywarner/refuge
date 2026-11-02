import 'package:flutter_test/flutter_test.dart';

import '../../tool/firebase_test_lab_support.dart';

void main() {
  group('extractHostingChannelPreviewUrl (#825)', () {
    test('extracts https preview URL from firebase hosting:channel:deploy JSON output', () {
      const jsonOut = '''
{
  "status": "success",
  "result": {
    "dev-belongonthespectrum": {
      "site": "dev-belongonthespectrum",
      "url": "https://dev-belongonthespectrum--walk-nov1-abc12345.web.app",
      "expireTime": "2026-11-15T22:30:00.000000000Z"
    }
  }
}
''';
      expect(
        extractHostingChannelPreviewUrl(jsonOut),
        'https://dev-belongonthespectrum--walk-nov1-abc12345.web.app',
      );
    });

    test('returns null when no url field is present', () {
      expect(extractHostingChannelPreviewUrl('{"status":"error"}'), isNull);
    });
  });

  group('buildDevReleaseNotes (#825)', () {
    test(
      'includes explicit previewChannelUrl and stable dev URL when previewChannelUrl is set',
      () {
        final notes = buildDevReleaseNotes(
          version: 'v0.9.5',
          devUrl: 'https://dev-belongonthespectrum.web.app',
          previewChannelUrl: 'https://dev-belongonthespectrum--walk-nov1-abc12345.web.app',
          packageId: devAndroidPackageId,
          gitSha: '63e7ce191543b6d2dbb142a3a30a7e50e882fe0e',
        );

        expect(
          notes,
          contains(
            'Please also try the web preview at '
            'https://dev-belongonthespectrum--walk-nov1-abc12345.web.app '
            '(or stable dev web: https://dev-belongonthespectrum.web.app)',
          ),
        );
        expect(notes, contains('Dev Android v0.9.5'));
        expect(notes, contains('Package: com.belongonthespectrum.refuge.dev'));
        expect(notes, contains('Git: 63e7ce191543b6d2dbb142a3a30a7e50e882fe0e'));
      },
    );

    test('falls back to stable devUrl when previewChannelUrl is omitted', () {
      final notes = buildDevReleaseNotes(
        version: 'v0.9.5',
        devUrl: 'https://dev-belongonthespectrum.web.app',
        packageId: devAndroidPackageId,
        gitSha: '63e7ce191543b6d2dbb142a3a30a7e50e882fe0e',
      );

      expect(
        notes,
        contains('Please also try the web preview at https://dev-belongonthespectrum.web.app'),
      );
    });
  });
}
