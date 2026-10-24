import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';

void main() {
  test('web app URLs use Firebase Hosting .web.app (dev prefix / prod bare)', () {
    expect(AppFlavor.hostingBaseDomain, 'belongonthespectrum.web.app');
    expect(AppFlavor.dev.urlPrefix, 'dev-');
    expect(AppFlavor.dev.websiteUrl, 'https://dev-belongonthespectrum.web.app/');
    expect(AppFlavor.dev.firebaseHostingUrl, 'https://dev-belongonthespectrum.web.app');
    expect(AppFlavor.dev.applicationId, 'com.belongonthespectrum.refuge.dev');
    expect(AppFlavor.prod.urlPrefix, '');
    expect(AppFlavor.prod.websiteUrl, 'https://belongonthespectrum.web.app/');
    expect(AppFlavor.prod.firebaseHostingUrl, 'https://belongonthespectrum.web.app');
    expect(AppFlavor.prod.applicationId, 'com.belongonthespectrum.refuge');
    expect(AppFlavor.stg.websiteUrl, 'https://stg-belongonthespectrum.web.app/');
    expect(AppFlavor.qa.websiteUrl, 'https://qa-belongonthespectrum.web.app/');
    expect(
      CommunityBrandConfig.forFlavor(AppFlavor.dev).websiteUrl,
      'https://dev-belongonthespectrum.web.app/',
    );
    expect(
      CommunityBrandConfig.forFlavor(AppFlavor.prod).websiteUrl,
      'https://belongonthespectrum.web.app/',
    );
    expect(
      const CommunityBrandConfig.belong().websiteUrl,
      'https://www.belongonthespectrum.com/',
    );
  });
}
