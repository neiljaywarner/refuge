import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_source_stamp.dart';

void main() {
  const previewHost = 'belongonthespectrum--feedback-659-abc.web.app';

  group('FeedbackSourceStamp web host rules', () {
    test('production hosts stay production', () {
      for (final host in [
        'belongonthespectrum.web.app',
        'belongonthespectrum.firebaseapp.com',
        'BelongOnTheSpectrum.web.app',
      ]) {
        expect(FeedbackSourceStamp.environmentForWebHost(host), 'production', reason: host);
      }
    });

    test('localhost and loopback are local', () {
      expect(
        FeedbackSourceStamp.fromWebUri(Uri.parse('http://localhost:7357/feedback')),
        isA<FeedbackSourceStamp>()
            .having((stamp) => stamp.sourceEnvironment, 'environment', 'local')
            .having((stamp) => stamp.sourceHost, 'host', 'localhost')
            .having((stamp) => stamp.sourceUrl, 'url', 'http://localhost:7357'),
      );
      expect(FeedbackSourceStamp.environmentForWebHost('127.0.0.1'), 'local');
      expect(FeedbackSourceStamp.environmentForWebHost('::1'), 'local');
      expect(FeedbackSourceStamp.environmentForWebHost(''), 'local');
    });

    test('a named dev site is dev, and a channel host is preview', () {
      expect(FeedbackSourceStamp.environmentForWebHost('dev-belongonthespectrum.web.app'), 'dev');
      expect(
        FeedbackSourceStamp.environmentForWebHost('qa-belongonthespectrum.firebaseapp.com'),
        'dev',
      );
      final preview = FeedbackSourceStamp.fromWebUri(Uri.parse('https://$previewHost/vote'));
      expect(preview.sourceEnvironment, 'preview');
      expect(preview.sourceHost, previewHost);
      expect(preview.sourceUrl, 'https://$previewHost');
      expect(
        FeedbackSourceStamp.environmentForWebHost(
          'belongonthespectrum--feedback-659-abc.firebaseapp.com',
        ),
        'preview',
      );
    });

    test('any other website is preview so it cannot look like production', () {
      expect(FeedbackSourceStamp.environmentForWebHost('example.com'), 'preview');
      expect(FeedbackSourceStamp.environmentForWebHost('other.web.app'), 'preview');
    });

    test('a preview channel host wins over a prod flavor', () {
      final stamp = FeedbackSourceStamp.current(
        isWeb: true,
        pageUri: Uri.parse('https://$previewHost/'),
        flavor: 'prod',
      );
      expect(stamp.sourceEnvironment, 'preview');
      expect(stamp.titlePrefix, '[preview] ');
      expect(stamp.issueLabels, ['preview']);
    });
  });

  group('FeedbackSourceStamp native flavor', () {
    test('prod flavor is production and other flavors are dev', () {
      final prod = FeedbackSourceStamp.current(isWeb: false, flavor: 'prod');
      expect(prod.sourceEnvironment, 'production');
      expect(prod.sourceHost, 'belongonthespectrum.web.app');
      expect(prod.titlePrefix, isEmpty);
      expect(prod.issueLabels, isEmpty);

      final dev = FeedbackSourceStamp.fromFlavor('dev');
      expect(dev.sourceEnvironment, 'dev');
      expect(dev.sourceHost, 'dev-belongonthespectrum.web.app');
      expect(dev.titlePrefix, '[dev] ');
      expect(dev.issueLabels, ['dev']);

      final local = const FeedbackSourceStamp(
        sourceEnvironment: 'local',
        sourceHost: 'localhost',
        sourceUrl: 'http://localhost',
      );
      expect(local.titlePrefix, '[local] ');
      expect(local.issueLabels, ['local']);
    });
  });
}
