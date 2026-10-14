import 'package:talker_flutter/talker_flutter.dart';

/// Central Talker logging service for visual debugging, RPC interception, and diagnostics.
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    maxHistoryItems: 1000,
    useConsoleLogs: true,
  ),
);
