import 'soft_deleted_user.dart';

/// Whether [userId], [email], or [displayName] matches a standing ban.
///
/// A row with `softDeleted: false` is a restored member and does not match.
/// Comparison trims whitespace and ignores email and name case.
bool isIdentityBanned({
  required List<SoftDeletedUser> bans,
  required String userId,
  required String email,
  required String displayName,
}) {
  final keys = <String>{};
  for (final ban in bans) {
    if (!ban.softDeleted) continue;
    final id = ban.userId.trim().toLowerCase();
    final name = ban.displayName.trim().toLowerCase();
    final mail = ban.email?.trim().toLowerCase() ?? '';
    if (id.isNotEmpty) keys.add(id);
    if (name.isNotEmpty) keys.add(name);
    if (mail.isNotEmpty) keys.add(mail);
  }
  if (keys.isEmpty) return false;

  final candidates = <String>[
    userId.trim().toLowerCase(),
    email.trim().toLowerCase(),
    displayName.trim().toLowerCase(),
  ].where((value) => value.isNotEmpty);
  return candidates.any(keys.contains);
}

/// Creates a post or comment only when the member is not paused.
///
/// Returns false without calling [create] when [isBanned] is true.
Future<bool> createContributionUnlessBanned({
  required bool isBanned,
  required Future<void> Function() create,
}) async {
  if (isBanned) return false;
  await create();
  return true;
}
