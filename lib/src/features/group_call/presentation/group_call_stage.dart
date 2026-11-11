import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

/// Grid, or a shared screen as the main tile with a presenter label.
///
/// [shareTile] is the screen-share video. Tests pass a stand-in. The live
/// call uses [StreamVideoRenderer] with [SfuTrackType.screenShare].
///
/// https://getstream.io/video/docs/flutter/video-render/
/// https://getstream.io/video/docs/flutter/guides/call-and-participant-state/
class GroupCallStage extends StatelessWidget {
  const GroupCallStage({super.key, required this.presenter, required this.grid, this.shareTile});

  final GroupCallPresenter? presenter;
  final Widget grid;
  final Widget? shareTile;

  @override
  Widget build(BuildContext context) {
    final presenter = this.presenter;
    if (presenter == null) return grid;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: KeyedSubtree(
                  key: const Key('group_call_screen_share_tile'),
                  child: shareTile ?? const ColoredBox(color: Colors.black),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: DecoratedBox(
                  key: const Key('group_call_presenter_label'),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: .circular(8)),
                  child: Padding(
                    padding: const .all(8),
                    child: Text(groupCallPresenterLabel(presenter)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 120, child: grid),
      ],
    );
  }
}

typedef GroupCallGridBuilder = Widget Function(Call call);

typedef GroupCallShareTileBuilder = Widget Function(Call call, GroupCallPresenter presenter);

/// Listens to [Call.state] and spotlights a screen-share track.
///
/// Viewing does not require permission to publish. iOS can watch a share
/// even though this client cannot start one.
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

  /// Defaults to [StreamCallParticipants].
  final GroupCallGridBuilder? gridBuilder;

  /// Defaults to a [StreamVideoRenderer] of [SfuTrackType.screenShare].
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
    final grid = widget.gridBuilder?.call(widget.call) ?? StreamCallParticipants(call: widget.call);
    final presenter = view.presenter;
    CallParticipantState? sharing;
    if (presenter != null) {
      for (final person in state.callParticipants) {
        if (person.userId == presenter.userId && person.isLocal == presenter.local) {
          sharing = person;
          break;
        }
      }
    }
    final tile = presenter == null
        ? null
        : widget.tileBuilder?.call(widget.call, presenter) ??
              (sharing == null
                  ? null
                  : StreamVideoRenderer(
                      call: widget.call,
                      participant: sharing,
                      videoTrackType: SfuTrackType.screenShare,
                      videoFit: VideoFit.contain,
                    ));
    return GroupCallStage(presenter: presenter, grid: grid, shareTile: tile);
  }
}
