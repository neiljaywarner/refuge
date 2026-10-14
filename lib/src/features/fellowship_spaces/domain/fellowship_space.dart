import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Predefined calm-tech fellowship spaces in Refuge.
const Map<String, String> kFellowshipSpaces = {
  'prayer': '🙏 #prayer-sanctuary',
  'study': '📖 #weekly-study',
  'announcements': '📢 #announcements',
  'special_interests': '🧩 #special-interests-memes',
  'general': '🌿 #main-hall',
};

/// Riverpod StateProvider tracking the currently active fellowship space key.
final activeSpaceKeyProvider = StateProvider<String>((ref) => 'prayer');
