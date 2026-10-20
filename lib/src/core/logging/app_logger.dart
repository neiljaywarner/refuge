import 'package:talker_flutter/talker_flutter.dart';

class AppLogger {
  static late final Talker talker;

  static void init() {
    talker = TalkerFlutter.init();
  }

  static void info(String message) => talker.info(message);
  static void warning(String message) => talker.warning(message);
  static void error(String message, [Object? exception, StackTrace? stackTrace]) =>
      talker.error(message, exception, stackTrace);
}
