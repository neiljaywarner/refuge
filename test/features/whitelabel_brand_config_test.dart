import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/branding/presentation/brand_config_provider.dart';

class _BrandPreviewProbe extends HookConsumerWidget {
  const _BrandPreviewProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(communityBrandConfigProvider);
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text(brand.shortName),
            Text(brand.fullName),
            Text(brand.partnerOrgUrl),
            Text(brand.defaultOrganizerWelcomeTitle),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('BDD Feature: White-Label CommunityBrandConfig (#17)', () {
    test('Scenario: Default tenant is Belong on the Spectrum', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final brand = container.read(communityBrandConfigProvider);
      expect(brand.tenantId, 'belong');
      expect(brand.shortName, 'Belong');
      expect(brand.fullName, 'Belong on the Spectrum');
      expect(brand.websiteUrl, 'https://www.belongonthespectrum.com/');
      expect(brand.partnerOrgName, 'DFW Church');
      expect(brand.partnerOrgUrl, 'https://dfwchurch.org');
      expect(brand.logoAssetPath, 'assets/images/belong_logo.png');
      expect(brand.creamBackgroundColor, const Color(0xFFF3EFE6));
      expect(brand.deepNavyPrimaryColor, const Color(0xFF112334));
      expect(brand.warmGoldAccentColor, const Color(0xFFC99F49));
    });

    testWidgets(
      'Scenario: Custom white-label tenant override in ProviderScope',
      (tester) async {
        const customBrand = CommunityBrandConfig.belong();
        final partnerBrand = customBrand.copyWith(
          tenantId: 'grace_spectrum',
          shortName: 'Grace Spectrum',
          fullName: 'Grace Neurodivergent Fellowship',
          defaultOrganizerWelcomeTitle: 'Welcome to Grace Spectrum',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              communityBrandConfigProvider.overrideWithValue(partnerBrand),
            ],
            child: const _BrandPreviewProbe(),
          ),
        );

        expect(find.text('Grace Spectrum'), findsOneWidget);
        expect(find.text('Grace Neurodivergent Fellowship'), findsOneWidget);
        expect(find.text('Welcome to Grace Spectrum'), findsOneWidget);
      },
    );
  });
}
