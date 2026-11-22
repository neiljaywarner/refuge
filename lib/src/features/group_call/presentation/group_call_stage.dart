import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../domain/group_call_screen_share.dart';
import '../domain/group_call_screen_share_log.dart';
import 'group_call_member_copy.dart';

/// This device. Web and Android can publish. iOS cannot, until a broadcast
/// extension exists.
///
/// https://getstream.io/video/docs/flutter/guides/screensharing/
GroupCallSharePlatform currentGroupCallSharePlatform() {
  if (kIsWeb) return GroupCallSharePlatform.web;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => GroupCallSharePlatform.android,
    TargetPlatform.iOS => GroupCallSharePlatform.ios,
    _ => GroupCallSharePlatform.other,
  };
}

/// "You are sharing" or "Fellow Member is sharing".
///
/// An email in the Stream name becomes "Fellow Member".
String groupCallPresenterLabel(GroupCallPresenter presenter) {
  if (presenter.local) return 'You are sharing';
  return '${calmGroupCallName(presenter.name)} is sharing';
}

/// Shown until a remote screen-share track is [RemoteTrackState.received].
///
/// Stream's renderer uses an empty box for that gap, so a viewer saw a blank
/// tile and had nothing to tap.
class GroupCallScreenShareStarting extends StatelessWidget {
  const GroupCallScreenShareStarting({super.key});

  static const String label = 'Screen share is starting…';

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white);
    return Center(
      child: Padding(
        padding: const .all(16),
        child: Text(
          label,
          key: const Key('group_call_screen_share_placeholder'),
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}

/// Grid, or a shared screen as the main tile with a presenter label.
///
/// A new share opens on the main tile. Back to grid keeps the share as a
/// tile the viewer can tap anywhere to open again. [shareTile] is the
/// screen-share video. Tests pass a stand-in. The live call uses
/// [StreamVideoRenderer] with [SfuTrackType.screenShare].
///
/// https://getstream.io/video/docs/flutter/video-render/
/// https://getstream.io/video/docs/flutter/guides/call-and-participant-state/
class GroupCallStage extends StatefulWidget {
  const GroupCallStage({super.key, required this.presenter, required this.grid, this.shareTile});

  final GroupCallPresenter? presenter;
  final Widget grid;
  final Widget? shareTile;

  @override
  State<GroupCallStage> createState() => _GroupCallStageState();
}

class _GroupCallStageState extends State<GroupCallStage> {
  var _spotlight = false;

  @override
  void initState() {
    super.initState();
    _spotlight = widget.presenter != null;
  }

  @override
  void didUpdateWidget(GroupCallStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.presenter;
    final previous = oldWidget.presenter;
    if (next == null) {
      _spotlight = false;
      return;
    }
    final changed =
        previous == null || previous.userId != next.userId || previous.local != next.local;
    if (changed) _spotlight = true;
  }

  void _openShare() {
    if (_spotlight) return;
    setState(() => _spotlight = true);
  }

  @override
  Widget build(BuildContext context) {
    final presenter = widget.presenter;
    if (presenter == null) return widget.grid;
    if (!_spotlight) return _gridWithTile(context, presenter);
    return _spotlightLayout(context, presenter);
  }

  Widget _gridWithTile(BuildContext context, GroupCallPresenter presenter) {
    return Column(
      key: const Key('group_call_share_grid'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: widget.grid),
        _tile(context, presenter, expandPicture: false),
      ],
    );
  }

  Widget _spotlightLayout(BuildContext context, GroupCallPresenter presenter) {
    return Column(
      key: const Key('group_call_share_spotlight'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: _tile(context, presenter, expandPicture: true)),
        Padding(
          padding: const .symmetric(horizontal: 12, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('group_call_back_to_grid'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF2A2A2E),
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
                padding: const .symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => setState(() => _spotlight = false),
              child: const Text('Back to grid'),
            ),
          ),
        ),
        Expanded(child: widget.grid),
      ],
    );
  }

  /// One semantics node. The whole tile is the tap target, including the
  /// label and the empty area while the picture is still starting.
  Widget _tile(BuildContext context, GroupCallPresenter presenter, {required bool expandPicture}) {
    final label = groupCallPresenterLabel(presenter);
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white);
    final picture = widget.shareTile ?? const GroupCallScreenShareStarting();
    final body = expandPicture
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: picture),
              _presenterLabel(label, style),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 48, width: double.infinity, child: picture),
              _presenterLabel(label, style),
            ],
          );
    return Semantics(
      key: const Key('group_call_screen_share_tile'),
      container: true,
      button: true,
      label: label,
      onTap: _openShare,
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        const CustomSemanticsAction(label: 'open shared screen'): _openShare,
      },
      child: ExcludeSemantics(
        child: Material(
          color: const Color(0xFF1C1C1E),
          child: Stack(
            children: [
              body,
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: _openShare, child: const SizedBox.expand()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _presenterLabel(String label, TextStyle? style) {
  return ColoredBox(
    key: const Key('group_call_presenter_label'),
    color: const Color(0xFF2A2A2E),
    child: Padding(
      padding: const .symmetric(horizontal: 12, vertical: 8),
      child: Text(label, style: style),
    ),
  );
}

typedef GroupCallGridBuilder = Widget Function(Call call);

typedef GroupCallShareTileBuilder = Widget Function(Call call, GroupCallPresenter presenter);

/// Listens to [Call.state] and spotlights a screen-share track.
///
/// Viewing does not require permission to publish. iOS can watch a share
/// even though this client cannot start one. The camera grid passed to
/// Stream omits the screen-share track so Stream's own layout does not
/// squeeze that picture into the filmstrip.
class GroupCallParticipantsArea extends StatefulWidget {
  const GroupCallParticipantsArea({
    super.key,
    required this.call,
    required this.guest,
    this.platform,
    this.gridBuilder,
    this.tileBuilder,
  });

  final Call call;
  final bool guest;
  final GroupCallSharePlatform? platform;

  /// Defaults to a camera grid. The screen-share track is left off that
  /// grid so it is not drawn twice.
  final GroupCallGridBuilder? gridBuilder;

  /// Defaults to a [StreamVideoRenderer] of [SfuTrackType.screenShare].
  /// While the remote track is not received, that renderer shows
  /// [GroupCallScreenShareStarting].
  final GroupCallShareTileBuilder? tileBuilder;

  @override
  State<GroupCallParticipantsArea> createState() => _GroupCallParticipantsAreaState();
}

class _GroupCallParticipantsAreaState extends State<GroupCallParticipantsArea> {
  StreamSubscription<CallState>? _subscription;
  String? _viewLine;

  @override
  void initState() {
    super.initState();
    _rememberView(widget.call.state.value);
    _subscription = widget.call.state.valueStream.listen((next) {
      _rememberView(next);
      if (mounted) setState(() {});
    });
  }

  void _rememberView(CallState state) {
    final view = groupCallShareViewFromCall(
      capabilities: state.ownCapabilities,
      guest: widget.guest,
      custom: state.custom,
      platform: widget.platform ?? currentGroupCallSharePlatform(),
      participants: state.callParticipants,
    );
    final line = groupCallScreenShareViewLine(
      someoneSharing: view.someoneSharing,
      localSharing: view.localSharing,
    );
    if (line == _viewLine) return;
    _viewLine = line;
    logGroupCallScreenShare(line);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.call.state.value;
    final view = groupCallShareViewFromCall(
      capabilities: state.ownCapabilities,
      guest: widget.guest,
      custom: state.custom,
      platform: widget.platform ?? currentGroupCallSharePlatform(),
      participants: state.callParticipants,
    );
    final grid = widget.gridBuilder?.call(widget.call) ?? _cameraGrid(widget.call, state);
    final presenter = view.presenter;
    final sharing = presenter == null
        ? null
        : groupCallPresenterParticipant(presenter: presenter, participants: state.callParticipants);
    final pending = sharing != null && groupCallScreenSharePending(sharing);
    // A test stand-in stands in for a picture that has already arrived.
    // The live renderer stays mounted while the track is pending so the
    // subscription still starts, and its placeholder is the starting line.
    final tile = presenter == null
        ? null
        : widget.tileBuilder != null && !pending
        ? widget.tileBuilder!(widget.call, presenter)
        : sharing == null
        ? null
        : StreamVideoRenderer(
            call: widget.call,
            participant: sharing,
            videoTrackType: SfuTrackType.screenShare,
            videoFit: VideoFit.contain,
            persistTrackIfNotVisible: true,
            placeholderBuilder: (_) => const GroupCallScreenShareStarting(),
          );
    return GroupCallStage(presenter: presenter, grid: grid, shareTile: tile);
  }
}

/// Camera tiles only. [StreamCallParticipants] would otherwise replace the
/// whole grid with its screen-share layout, which then sits in the short
/// filmstrip and clips.
Widget _cameraGrid(Call call, CallState state) {
  return StreamCallParticipants(
    call: call,
    participants: [
      for (final person in state.callParticipants)
        person.copyWith(
          publishedTracks: {
            for (final entry in person.publishedTracks.entries)
              if (entry.key != SfuTrackType.screenShare) entry.key: entry.value,
          },
        ),
    ],
  );
}
