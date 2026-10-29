import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';

class _SignedOutProfile extends MemberProfileNotifier {
  @override
  MemberProfile build() => const MemberProfile(
    displayName: 'New Member',
    email: 'new@example.com',
    bio: '',
    comfortBadges: [],
    isSignedIn: false,
  );
}

ProviderContainer _container(AppFlavor flavor) {
  final container = ProviderContainer(
    overrides: [
      appFlavorProvider.overrideWithValue(flavor),
      memberProfileProvider.overrideWith(_SignedOutProfile.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production starts with no sample notifications and no badge (#685)', () {
    final container = _container(AppFlavor.prod);

    expect(container.read(belongNotificationsProvider), isEmpty);
    expect(container.read(unreadNotificationCountProvider), 0);
  });

  test('dev keeps the sample notifications for demos and tests', () {
    final container = _container(AppFlavor.dev);

    expect(container.read(belongNotificationsProvider), isNotEmpty);
    expect(container.read(unreadNotificationCountProvider), greaterThan(0));
  });
}
