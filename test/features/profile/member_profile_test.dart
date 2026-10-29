import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MemberProfile & ICOC Church Affiliation Domain Logic (#93)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      ProfileStorageService.instance.clear();
    });

    tearDown(() async {
      ProfileStorageService.instance.clear();
    });
    test('isIcocMember returns true for active ICOC congregations', () {
      const p1 = MemberProfile(
        displayName: 'Marty',
        email: 'marty@belongonthespectrum.com',
        bio: 'Organizer',
        comfortBadges: ['Organizer'],
        isSignedIn: true,
        icocChurchAffiliation: 'DFW Church (Partner)',
      );
      expect(p1.isIcocMember, isTrue);

      const p2 = MemberProfile(
        displayName: 'Hannah',
        email: 'hannah@belongonthespectrum.com',
        bio: 'Artist',
        comfortBadges: ['Artist'],
        isSignedIn: true,
        icocChurchAffiliation: 'Austin Christian Church',
      );
      expect(p2.isIcocMember, isTrue);
    });

    test('isIcocMember returns false for non-members, empty, or null affiliation', () {
      const nonMember = MemberProfile(
        displayName: 'Jordan',
        email: 'jordan@belong.org',
        bio: 'Ally',
        comfortBadges: ['Ally'],
        isSignedIn: true,
        icocChurchAffiliation: 'I am not a member of an ICOC church',
      );
      expect(nonMember.isIcocMember, isFalse);

      const nonFellowship = MemberProfile(
        displayName: 'Guest',
        email: 'guest@belong.org',
        bio: 'Visitor',
        comfortBadges: [],
        isSignedIn: true,
        icocChurchAffiliation: 'I am not a member of this fellowship',
      );
      expect(nonFellowship.isIcocMember, isFalse);

      const empty = MemberProfile(
        displayName: 'Anonymous',
        email: '',
        bio: '',
        comfortBadges: [],
        isSignedIn: false,
        icocChurchAffiliation: '   ',
      );
      expect(empty.isIcocMember, isFalse);

      const guest = MemberProfile.guest();
      expect(guest.isIcocMember, isFalse);
      expect(guest.icocChurchAffiliation, isNull);
    });

    test('copyWith updates and preserves icocChurchAffiliation', () {
      const original = MemberProfile(
        displayName: 'Alex',
        email: 'alex@belong.org',
        bio: 'Dev',
        comfortBadges: [],
        isSignedIn: true,
        icocChurchAffiliation: 'Boston Church of Christ',
      );

      final modified = original.copyWith(displayName: 'Alexander');
      expect(modified.displayName, 'Alexander');
      expect(modified.icocChurchAffiliation, 'Boston Church of Christ');
      expect(modified.isIcocMember, isTrue);

      final nonMember = original.copyWith(
        icocChurchAffiliation: 'I am not a member of an ICOC church',
      );
      expect(nonMember.isIcocMember, isFalse);
    });

    test('MemberProfileNotifier records affiliation during signIn', () async {
      final container = ProviderContainer(
        overrides: [authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory)],
      );
      addTearDown(container.dispose);

      expect(container.read(memberProfileProvider).isSignedIn, isFalse);
      expect(container.read(memberProfileProvider).icocChurchAffiliation, isNull);

      container
          .read(memberProfileProvider.notifier)
          .signIn(
            displayName: 'Marty Organizer',
            email: 'marty@belongonthespectrum.com',
            bio: 'Belong Organizer',
            icocChurchAffiliation: 'DFW Church (Partner)',
          );

      final state = container.read(memberProfileProvider);
      expect(state.isSignedIn, isTrue);
      expect(state.displayName, 'Marty Organizer');
      expect(state.icocChurchAffiliation, 'DFW Church (Partner)');
      expect(state.isIcocMember, isTrue);

      await container.read(memberProfileProvider.notifier).signOut();
      ProfileStorageService.instance.clear();
    });

    test('CommunityBrandConfig default belong configuration has required ICOC options', () {
      const brand = CommunityBrandConfig.belong();
      expect(brand.enableFellowshipAffiliationField, isTrue);
      expect(brand.fellowshipAffiliationPrompt, 'Which ICOC church do you attend?');
      expect(brand.fellowshipAffiliationOptions, contains('DFW Church (Partner)'));
      expect(brand.fellowshipAffiliationOptions, contains('Austin Christian Church'));
      expect(brand.fellowshipNonMemberOption, 'I am not a member of an ICOC church');
    });
  });
}
