import 'package:equatable/equatable.dart';

/// Predictable, anxiety-free delivery schedules for neurodivergent members.
enum CalmDigestSchedule {
  /// Delivered at 10:00 AM & 6:00 PM local time. Recommended for unhurried presence.
  twiceDaily(
    title: 'Twice Daily Digest (Recommended)',
    description: 'Batched updates arrive unhurried at 10:00 AM & 6:00 PM.',
    emoji: '🌅',
  ),

  /// Delivered once at 9:00 AM local time.
  morningOnly(
    title: 'Morning Digest Only',
    description: 'Single gentle overview at 9:00 AM with your morning routine.',
    emoji: '☕',
  ),

  /// Delivered as calm cards without loud chimes or urgent badges.
  immediateGentle(
    title: 'Immediate Gentle Cards',
    description: 'Silent cards appear as reflections happen. Zero auditory startles.',
    emoji: '🌱',
  ),

  /// Zero notifications; check in strictly when you choose.
  muted(
    title: 'Completely Muted',
    description: 'Zero notifications. You browse purely on your own schedule.',
    emoji: '🔕',
  );

  const CalmDigestSchedule({required this.title, required this.description, required this.emoji});

  final String title;
  final String description;
  final String emoji;
}

/// Preferences model governing calm notification ethics (ADR-0010).
class CalmNotificationPreferences extends Equatable {
  const CalmNotificationPreferences({
    this.enabled = false,
    this.schedule = CalmDigestSchedule.twiceDaily,
    this.fcmToken,
    this.isWebPwaInstalled = false,
    this.isIosWebWithoutPwa = false,
    this.isSystemPermissionDenied = false,
  });

  /// Whether member has opted into receiving push/local digests.
  final bool enabled;

  /// The batched schedule preference.
  final CalmDigestSchedule schedule;

  /// The active Firebase Cloud Messaging device token (if permission granted).
  final String? fcmToken;

  /// Whether the client is running as an installed PWA (WebAPK or iOS Home Screen).
  final bool isWebPwaInstalled;

  /// Whether the client is Mobile Safari without being added to Home Screen.
  /// (Apple strictly requires "Add to Home Screen" before Web Push can activate).
  final bool isIosWebWithoutPwa;

  /// Whether the user has denied system notification permission (e.g. Android 13+ "Don't allow").
  /// Used to surface a gentle re-enable toggle in the Spaces drawer without nagging.
  final bool isSystemPermissionDenied;

  CalmNotificationPreferences copyWith({
    bool? enabled,
    CalmDigestSchedule? schedule,
    String? fcmToken,
    bool? isWebPwaInstalled,
    bool? isIosWebWithoutPwa,
    bool? isSystemPermissionDenied,
  }) => CalmNotificationPreferences(
    enabled: enabled ?? this.enabled,
    schedule: schedule ?? this.schedule,
    fcmToken: fcmToken ?? this.fcmToken,
    isWebPwaInstalled: isWebPwaInstalled ?? this.isWebPwaInstalled,
    isIosWebWithoutPwa: isIosWebWithoutPwa ?? this.isIosWebWithoutPwa,
    isSystemPermissionDenied: isSystemPermissionDenied ?? this.isSystemPermissionDenied,
  );

  @override
  List<Object?> get props => [
    enabled,
    schedule,
    fcmToken,
    isWebPwaInstalled,
    isIosWebWithoutPwa,
    isSystemPermissionDenied,
  ];
}
