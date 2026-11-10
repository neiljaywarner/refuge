import 'package:stream_video_flutter/stream_video_flutter.dart';

/// Where a preview call is running.
///
/// Publishing a share is web (`getDisplayMedia`) and Android (MediaProjection).
/// iOS needs a ReplayKit broadcast extension, which is a follow-up.
/// Viewing a share does not depend on this value.
///
/// https://getstream.io/video/docs/flutter/guides/screensharing/
enum GroupCallSharePlatform { web, android, ios, other }

/// Call custom flag a host sets so a guest may share.
///
/// Guests stay off until this is `true`. Stream's `screenshare` grant is
/// still required. A string `"true"` does not count.
///
/// https://getstream.io/video/docs/flutter/guides/screensharing/
const String guestScreenShareCustomKey = 'guestScreenShare';

/// One person, reduced to what the share layout needs.
class const GroupCallShareParticipant({
  required this.userId,
  required this.name,
  required this.local,
  required this.screenShareEnabled,
}) {
  final String userId;
  final String name;
  final bool local;
  final bool screenShareEnabled;
}

/// Who is sharing. [local] is this device.
class const GroupCallPresenter({
  required this.userId,
  required this.name,
  required this.local,
}) {
  final String userId;
  final String name;
  final bool local;
}

/// Whether this person may publish, and who is presenting.
class const GroupCallShareView({
  required this.canShare,
  required this.localSharing,
  required this.presenter,
}) {
  final bool canShare;
  final bool localSharing;

  /// Null when nobody's screen-share track is on.
  final GroupCallPresenter? presenter;

  bool get someoneSharing => presenter != null;
}

/// True when [CallPermission.screenshare] is in [CallState.ownCapabilities].
///
/// The alias is `screenshare`.
/// https://getstream.io/video/docs/flutter/guides/screensharing/
bool capabilitiesIncludeScreenshare(Iterable<CallPermission> capabilities) =>
    capabilities.contains(CallPermission.screenshare);

/// True only for a boolean `true` on [guestScreenShareCustomKey].
bool organizerAllowsGuestScreenShare(Map<String, Object> custom) =>
    custom[guestScreenShareCustomKey] == true;

/// Web and Android can publish. iOS and desktop cannot, in this client.
bool groupCallPlatformCanPublish(GroupCallSharePlatform platform) =>
    platform == GroupCallSharePlatform.web ||
    platform == GroupCallSharePlatform.android;

/// A person may share when Stream granted `screenshare`, this platform can
/// publish, and a guest also has the organizer's allow flag.
///
/// https://getstream.io/video/docs/flutter/guides/screensharing/
/// (`call.hasPermission(CallPermission.screenshare)`)
bool groupCallCanShare({
  required bool screenshareGranted,
  required bool guest,
  required bool organizerAllowsGuests,
  required GroupCallSharePlatform platform,
}) {
  if (!screenshareGranted) return false;
  if (!groupCallPlatformCanPublish(platform)) return false;
  if (guest && !organizerAllowsGuests) return false;
  return true;
}

/// Reads [CallParticipantState.isScreenShareEnabled], which is the
/// `screenShare` track when it is present and not muted.
///
/// https://getstream.io/video/docs/flutter/guides/call-and-participant-state/
GroupCallShareParticipant groupCallShareParticipant(
  CallParticipantState person,
) => GroupCallShareParticipant(
  userId: person.userId,
  name: person.name,
  local: person.isLocal,
  screenShareEnabled: person.isScreenShareEnabled,
);

/// The local sharer wins. Otherwise the first remote sharer in [people].
GroupCallPresenter? groupCallPresenter(
  Iterable<GroupCallShareParticipant> people,
) {
  GroupCallShareParticipant? remote;
  for (final person in people) {
    if (!person.screenShareEnabled) continue;
    if (person.local) {
      return GroupCallPresenter(
        userId: person.userId,
        name: person.name,
        local: true,
      );
    }
    remote ??= person;
  }
  if (remote == null) return null;
  return GroupCallPresenter(
    userId: remote.userId,
    name: remote.name,
    local: false,
  );
}

/// Builds the share view from plain flags.
GroupCallShareView groupCallShareView({
  required bool screenshareGranted,
  required bool guest,
  required bool organizerAllowsGuests,
  required GroupCallSharePlatform platform,
  required Iterable<GroupCallShareParticipant> participants,
}) {
  final people = participants.toList(growable: false);
  final presenter = groupCallPresenter(people);
  return GroupCallShareView(
    canShare: groupCallCanShare(
      screenshareGranted: screenshareGranted,
      guest: guest,
      organizerAllowsGuests: organizerAllowsGuests,
      platform: platform,
    ),
    localSharing: presenter?.local ?? false,
    presenter: presenter,
  );
}

/// Builds the share view from a live [CallState].
///
/// [guest] is Belong sign-in, not a Stream role. [platform] is this device.
GroupCallShareView groupCallShareViewFromCall({
  required Iterable<CallPermission> capabilities,
  required bool guest,
  required Map<String, Object> custom,
  required GroupCallSharePlatform platform,
  required Iterable<CallParticipantState> participants,
}) => groupCallShareView(
  screenshareGranted: capabilitiesIncludeScreenshare(capabilities),
  guest: guest,
  organizerAllowsGuests: organizerAllowsGuestScreenShare(custom),
  platform: platform,
  participants: [
    for (final person in participants) groupCallShareParticipant(person),
  ],
);
