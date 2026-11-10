import 'package:flutter/foundation.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../data/stream_video_preview_config.dart';

/// Debug log for [#909](https://github.com/neiljaywarner/refuge/issues/909).
///
/// Printed in debug builds and in a preview binary (`STREAM_VIDEO_PREVIEW`).
/// A production release stays quiet. The line starts with `[#909]` so
/// `adb logcat` or the browser console can grep it. Names, emails, tokens,
/// and raw device labels are not written.
void logGroupCall909(String detail) {
  if (!groupCall909LogsEnabled(
    debugMode: kDebugMode,
    preview: streamVideoPreviewEnabled,
  )) {
    return;
  }
  AppLogger.debug(groupCall909Line(detail));
}

/// True for a debug run or a preview build. Production release is false.
bool groupCall909LogsEnabled({
  required bool debugMode,
  required bool preview,
}) => debugMode || preview;

/// Prefixes [detail] and strips an email or a JWT if one was passed in.
String groupCall909Line(String detail) {
  final cleaned = detail
      .replaceAll(RegExp(r'\S+@\S+'), 'redacted')
      .replaceAll(RegExp(r'eyJ[A-Za-z0-9_-]+'), 'redacted');
  return '[#909] $cleaned';
}

/// Local microphone flags. The track id itself is not included.
String groupCall909LocalAudio(CallParticipantState? local) {
  final track = local?.audioTrack;
  final enabled = local?.isAudioEnabled ?? false;
  final muted = track?.muted ?? true;
  final present = track != null;
  return 'localAudio enabled=$enabled muted=$muted trackPresent=$present';
}

/// `send-audio` and the other grants, by name only.
String groupCall909Capabilities(Iterable<CallPermission> capabilities) {
  final names = [for (final permission in capabilities) permission.alias]
    ..sort();
  return 'ownCapabilities=${names.join(',')}';
}

/// Speaker, earpiece, external, or other. The device name is dropped.
String groupCall909Output({
  String? deviceId,
  String? deviceLabel,
  bool external = false,
  bool? speakerRequested,
}) {
  final id = (deviceId ?? '').toLowerCase();
  final label = (deviceLabel ?? '').toLowerCase();
  final speaker = id.contains('speaker') || label.contains('speaker');
  final earpiece = id.contains('earpiece') || label.contains('earpiece');
  final bucket = speaker
      ? 'speaker'
      : earpiece
      ? 'earpiece'
      : external
      ? 'external'
      : deviceId == null
      ? 'unset'
      : 'other';
  final requested = speakerRequested == null
      ? ''
      : ' speakerRequested=$speakerRequested';
  return 'audioOutput=$bucket speakerphone=${bucket == 'speaker'}$requested';
}

/// Remote audio presence. Names and ids are not included.
String groupCall909Remotes(Iterable<CallParticipantState> others) {
  var tracks = 0;
  var speaking = 0;
  var level = 0.0;
  for (final person in others) {
    if (person.audioTrack != null) tracks += 1;
    if (person.isSpeaking) speaking += 1;
    // A muted track can keep the last audioLevel (often about 0.20) after
    // the sound has already stopped. Count energy only while audio is on.
    if (person.isAudioEnabled) level += person.audioLevel;
  }
  final rounded = (level * 100).round() / 100;
  final shown = rounded == 0 ? '0' : '$rounded';
  return 'remotes audioTracks=$tracks speaking=$speaking audioLevel=$shown';
}

/// Publish or unpublish when the local audio track appears or disappears.
String? groupCall909PublishChange({
  required bool beforePresent,
  required bool afterPresent,
  required bool afterEnabled,
}) {
  if (!beforePresent && afterPresent) {
    return 'publish localAudio enabled=$afterEnabled';
  }
  if (beforePresent && !afterPresent) return 'unpublish localAudio';
  return null;
}

/// Drops a repeated remote line until [gap] has passed.
class GroupCall909Throttle {
  String? _line;
  DateTime? _at;

  bool allow(
    String line,
    DateTime now, {
    bool force = false,
    Duration gap = const Duration(seconds: 2),
  }) {
    final due =
        force || _line != line || _at == null || now.difference(_at!) >= gap;
    if (!due) return false;
    _line = line;
    _at = now;
    return true;
  }
}
