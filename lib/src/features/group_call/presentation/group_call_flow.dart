import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/stream_token_client.dart';
import '../data/stream_video_preview_config.dart';
import '../domain/group_call_room.dart';
import '../domain/stream_call_credentials.dart';
import 'group_call_lobby.dart';
import 'stream_group_call_page.dart';

/// Live token client for a preview binary.
///
/// Null unless this build was compiled with `STREAM_VIDEO_PREVIEW` and a
/// usable `STREAM_TOKEN_ENDPOINT`. Production builds take the null path and
/// never send a Firebase ID token to the mint function.
StreamTokenClient? buildLiveStreamTokenClient({http.Client? httpClient}) {
  final endpoint = streamTokenEndpoint;
  if (!streamVideoPreviewEnabled || endpoint == null) return null;
  return StreamTokenClient(
    endpoint: endpoint,
    httpClient: httpClient ?? http.Client(),
    readIdToken: readFirebaseIdToken,
  );
}

Future<void> pushStreamGroupCall(
  BuildContext context, {
  required GroupCallRoom room,
  required StreamCallCredentials credentials,
  required String displayName,
  required StreamTokenClient tokenClient,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => StreamGroupCallPage(
        credentials: credentials,
        displayName: displayName,
        tokenClient: tokenClient,
      ),
    ),
  );
}

Future<void> openGroupCallLobby({
  required BuildContext context,
  required String displayName,
  required String initialCallId,
  StreamTokenClientFactory? tokenClientFactory,
  GroupCallStarter? onReady,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (context) => GroupCallLobbyPage(
      displayName: displayName,
      initialCallId: initialCallId,
      tokenClientFactory: tokenClientFactory ?? buildLiveStreamTokenClient,
      onReady: onReady ?? pushStreamGroupCall,
    ),
  ),
);
