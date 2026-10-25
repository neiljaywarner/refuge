import 'package:flutter/foundation.dart';

import '../../profile/presentation/belong_members_directory_view.dart';

/// A member row in the New Message recipient picker (#441).
@immutable
class MessageRecipient {
  const MessageRecipient({
    required this.id,
    required this.name,
    required this.tagline,
    this.handle,
    this.isSample = false,
  });

  /// Firebase uid for real members, or a stable sample key.
  final String id;
  final String name;
  final String tagline;
  final String? handle;
  final bool isSample;

  String get initials {
    final cleaned = name.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .map((p) => p.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), ''))
        .where((p) => p.isNotEmpty)
        .toList();
    return switch (parts) {
      [] => 'B',
      [final single] => single[0].toUpperCase(),
      [final first, ..., final last] => '${first[0]}${last[0]}'.toUpperCase(),
    };
  }

  /// Subtitle for the picker row: tagline, plus @handle when not in the name.
  String get pickerSubtitle {
    final h = handle?.trim().toLowerCase();
    if (h == null || h.isEmpty) return tagline;
    if (name.toLowerCase().contains(h)) return tagline;
    final handleLabel = '@$handle';
    if (tagline.isEmpty) return handleLabel;
    return '$tagline · $handleLabel';
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    if (tagline.toLowerCase().contains(q)) return true;
    final h = handle?.toLowerCase();
    if (h != null && h.isNotEmpty && h.contains(q)) return true;
    return false;
  }

  factory MessageRecipient.fromDevMember(DevFellowshipMember member) =>
      MessageRecipient(
        id: 'sample-${member.name}',
        name: member.name,
        tagline: member.effectiveTagline,
        isSample: true,
      );

  factory MessageRecipient.fromFirestoreUser(
    String uid,
    Map<String, dynamic> data,
  ) {
    final email = data['email'] as String? ?? '';
    final handle = email.contains('@') ? email.split('@').first : null;
    final bio = data['bio'] as String?;
    return MessageRecipient(
      id: uid,
      name: (data['displayName'] as String?)?.trim().isNotEmpty == true
          ? (data['displayName'] as String).trim()
          : 'Fellow Member',
      tagline: bio?.trim().isNotEmpty == true
          ? bio!.trim()
          : 'Community member',
      handle: handle?.isNotEmpty == true ? handle : null,
    );
  }
}
