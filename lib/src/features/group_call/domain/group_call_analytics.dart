import '../../../core/firebase/community_analytics_service.dart';
import '../../../core/observability/error_reporter_service.dart';

/// Product analytics for one preview group call.
///
/// Events fan out through [CommunityAnalyticsService]. Handled failures also
/// go through [ErrorReporterService], which sends `app_error` on web, where
/// Crashlytics is not used. Properties are a role and a short code. Tokens,
/// emails, invite codes, invite URLs, and display names are not accepted.
class GroupCallTelemetry {
  GroupCallTelemetry({required this.analytics, this.errors});

  /// The app-wide recorder. Null in tests that never bind one.
  static GroupCallTelemetry? current;

  static void bind(GroupCallTelemetry telemetry) => current = telemetry;

  static void unbind() => current = null;

  final CommunityAnalyticsService analytics;
  final ErrorReporterService? errors;

  Future<void> joined({required String role}) => analytics.logCallJoined(role: role);

  Future<void> left({required String role, required int durationSeconds}) =>
      analytics.logCallLeft(role: role, durationSeconds: durationSeconds);

  Future<void> mediaToggled({
    required String role,
    required String medium,
    required bool enabled,
  }) => analytics.logCallMediaToggled(role: role, medium: medium, enabled: enabled);

  /// Records `call_failed` and a handled `app_error`. [failureReason] is a code.
  Future<void> failed({
    required String role,
    required String failureReason,
    String action = 'call',
    StackTrace? stack,
  }) async {
    final safeRole = role == 'guest' ? 'guest' : 'member';
    final reason = CommunityAnalyticsService.callFailureReasons.contains(failureReason)
        ? failureReason
        : 'unavailable';
    await analytics.logCallFailed(role: safeRole, failureReason: reason);
    await errors?.recordError(
      StateError('call_failed'),
      stack,
      reason: reason,
      context: {'area': 'group_call', 'role': safeRole, 'action': callFailureAction(action)},
    );
  }
}

/// Role used by the in-call controls. A guest is not a signed-in member.
Future<void> reportCallMediaToggle({
  required bool signedInMember,
  required String medium,
  required bool enabled,
}) =>
    GroupCallTelemetry.current?.mediaToggled(
      role: signedInMember ? 'member' : 'guest',
      medium: medium,
      enabled: enabled,
    ) ??
    Future<void>.value();

/// Handled media failure. The SDK sentence is not copied into the event.
Future<void> reportCallMediaFailure({
  required bool signedInMember,
  required String failureReason,
}) =>
    GroupCallTelemetry.current?.failed(
      role: signedInMember ? 'member' : 'guest',
      action: failureReason == 'camera_unavailable' ? 'camera' : 'microphone',
      failureReason: failureReason,
    ) ??
    Future<void>.value();

const Set<String> callFailureActions = {
  'call',
  'mint',
  'create_invite',
  'revoke_invite',
  'revoke_my_invites',
  'join_guest',
  'refresh_guest',
  'connect',
  'microphone',
  'camera',
};

String callFailureAction(String action) => callFailureActions.contains(action) ? action : 'call';

/// Maps a user-facing call sentence to a stable reason code.
///
/// Unknown text, including anything that might carry a name or a credential,
/// becomes `unavailable`. The sentence itself is never the event property.
String callFailureReasonForMessage(String message) => switch (message) {
  'A Firebase sign-in is required to join by call name. '
      'The call name alone does not let anyone in.' =>
    'sign_in_required',
  'This account cannot join a call.' => 'forbidden',
  'Video calling is not configured on this preview yet.' => 'unconfigured',
  'The call could not start. Try again in a moment.' => 'unavailable',
  'This invite link is not valid.' => 'invalid_invite',
  'This invite link has expired or was revoked.' => 'expired',
  'This call already has 10 guests. Try again after someone leaves.' => 'full',
  'This invite link is for a different call.' => 'mismatch',
  'This invite link is not valid for that seat. Open the link again.' => 'seat',
  'Too many join attempts. Wait a few minutes and try the link again.' => 'rate_limited',
  'Use a short name. Leave out email addresses and web links.' => 'invalid_name',
  'The guest link could not be created. Try again in a moment.' => 'invite_failed',
  'The link could not be revoked. Try again in a moment.' => 'invite_failed',
  _ => 'unavailable',
};
