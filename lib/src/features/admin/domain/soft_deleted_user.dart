import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
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
    this.erasePending = false,
    this.eraseErrors = const [],
  });

  factory SoftDeletedUser.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawDate = map['bannedAt'];
    DateTime date;
    if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is Timestamp) {
      date = rawDate.toDate();
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
      erasePending: map['erasePending'] as bool? ?? false,
      eraseErrors: map['eraseErrors'] is List
          ? [for (final step in map['eraseErrors'] as List) step.toString()]
          : const [],
    );
  }

  SoftDeletedUser copyWith({bool? erasePending, List<String>? eraseErrors, bool? softDeleted}) =>
      SoftDeletedUser(
        userId: userId,
        displayName: displayName,
        email: email,
        bannedAt: bannedAt,
        bannedByAdminEmail: bannedByAdminEmail,
        reason: reason,
        softDeleted: softDeleted ?? this.softDeleted,
        originalData: originalData,
        erasePending: erasePending ?? this.erasePending,
        eraseErrors: eraseErrors ?? this.eraseErrors,
      );

  final String userId;
  final String displayName;
  final String? email;
  final DateTime bannedAt;
  final String bannedByAdminEmail;
  final String reason;
  final bool softDeleted;
  final Map<String, dynamic> originalData;

  /// True when the ban record is saved and content erase still needs a retry.
  final bool erasePending;
  final List<String> eraseErrors;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,
    'bannedAt': bannedAt.toIso8601String(),
    'bannedByAdminEmail': bannedByAdminEmail,
    'reason': reason,
    'softDeleted': softDeleted,
    'originalData': originalData,
    'erasePending': erasePending,
    'eraseErrors': eraseErrors,
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
    erasePending,
    eraseErrors,
  ];
}
