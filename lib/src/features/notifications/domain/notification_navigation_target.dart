import 'package:equatable/equatable.dart';

import '../../navigation/presentation/belong_bottom_nav_bar.dart';

/// Navigation target resolved from an in-app or push notification (#330).
class NotificationNavigationTarget extends Equatable {
  const NotificationNavigationTarget({
    required this.tab,
    this.spaceKey,
    this.postId,
    this.conversationId,
    this.openDiscussion = false,
  });

  /// The bottom navigation tab to switch to.
  final BelongBottomTab tab;

  /// Optional fellowship space slug (e.g. 'prayer', 'study', 'general_chat').
  final String? spaceKey;

  /// Optional post identifier to scroll to or highlight.
  final String? postId;

  /// Optional direct message conversation thread ID.
  final String? conversationId;

  /// Whether to automatically open the threaded discussion modal.
  final bool openDiscussion;

  @override
  List<Object?> get props => [
    tab,
    spaceKey,
    postId,
    conversationId,
    openDiscussion,
  ];
}
