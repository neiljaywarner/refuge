import 'package:equatable/equatable.dart';

/// Represents a user whose account and profile information has been moved into
/// the remote soft-delete table (`soft_deleted_users`).
class SoftDeletedUser extends Equatable {
  const SoftDeletedUser({
    required this.userId,
    required this.displayName,
    this.email,
    required this.bannedAt,
    required this.bannedByAdminEmail,
    this.reason = 'Violating calm community guidelines',
    this.softDeleted = true,
    this.originalData = const {},
  });

  factory SoftDeletedUser.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawDate = map['bannedAt'];
    DateTime date;
    if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return SoftDeletedUser(
      userId: id ?? (map['userId'] as String? ?? ''),
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String?,
      bannedAt: date,
      bannedByAdminEmail: map['bannedByAdminEmail'] as String? ?? '',
      reason: map['reason'] as String? ?? 'Violating calm community guidelines',
      softDeleted: map['softDeleted'] as bool? ?? true,
      originalData: map['originalData'] is Map
          ? Map<String, dynamic>.from(map['originalData'] as Map)
          : const {},
    );
  }

  final String userId;
  final String displayName;
  final String? email;
  final DateTime bannedAt;
  final String bannedByAdminEmail;
  final String reason;
  final bool softDeleted;
  final Map<String, dynamic> originalData;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'email': email,
        'bannedAt': bannedAt.toIso8601String(),
        'bannedByAdminEmail': bannedByAdminEmail,
        'reason': reason,
        'softDeleted': softDeleted,
        'originalData': originalData,
      };

  @override
  List<Object?> get props => [
        userId,
        displayName,
        email,
        bannedAt,
        bannedByAdminEmail,
        reason,
        softDeleted,
        originalData,
      ];
}
