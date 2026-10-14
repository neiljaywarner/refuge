/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Server-side computational aggregation of a fellowship space's activity.
abstract class QuietDigest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  QuietDigest._({
    required this.spaceKey,
    required this.totalReflections,
    required this.totalCareAffirmations,
    required this.predominantIntent,
    this.featuredSpecialInterest,
    required this.summaryMessage,
    required this.generatedAt,
  });

  factory QuietDigest({
    required String spaceKey,
    required int totalReflections,
    required int totalCareAffirmations,
    required String predominantIntent,
    String? featuredSpecialInterest,
    required String summaryMessage,
    required DateTime generatedAt,
  }) = _QuietDigestImpl;

  factory QuietDigest.fromJson(Map<String, dynamic> jsonSerialization) {
    return QuietDigest(
      spaceKey: jsonSerialization['spaceKey'] as String,
      totalReflections: jsonSerialization['totalReflections'] as int,
      totalCareAffirmations: jsonSerialization['totalCareAffirmations'] as int,
      predominantIntent: jsonSerialization['predominantIntent'] as String,
      featuredSpecialInterest:
          jsonSerialization['featuredSpecialInterest'] as String?,
      summaryMessage: jsonSerialization['summaryMessage'] as String,
      generatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['generatedAt'],
      ),
    );
  }

  String spaceKey;

  int totalReflections;

  int totalCareAffirmations;

  String predominantIntent;

  String? featuredSpecialInterest;

  String summaryMessage;

  DateTime generatedAt;

  /// Returns a shallow copy of this [QuietDigest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  QuietDigest copyWith({
    String? spaceKey,
    int? totalReflections,
    int? totalCareAffirmations,
    String? predominantIntent,
    String? featuredSpecialInterest,
    String? summaryMessage,
    DateTime? generatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QuietDigest',
      'spaceKey': spaceKey,
      'totalReflections': totalReflections,
      'totalCareAffirmations': totalCareAffirmations,
      'predominantIntent': predominantIntent,
      if (featuredSpecialInterest != null)
        'featuredSpecialInterest': featuredSpecialInterest,
      'summaryMessage': summaryMessage,
      'generatedAt': generatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QuietDigest',
      'spaceKey': spaceKey,
      'totalReflections': totalReflections,
      'totalCareAffirmations': totalCareAffirmations,
      'predominantIntent': predominantIntent,
      if (featuredSpecialInterest != null)
        'featuredSpecialInterest': featuredSpecialInterest,
      'summaryMessage': summaryMessage,
      'generatedAt': generatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QuietDigestImpl extends QuietDigest {
  _QuietDigestImpl({
    required String spaceKey,
    required int totalReflections,
    required int totalCareAffirmations,
    required String predominantIntent,
    String? featuredSpecialInterest,
    required String summaryMessage,
    required DateTime generatedAt,
  }) : super._(
         spaceKey: spaceKey,
         totalReflections: totalReflections,
         totalCareAffirmations: totalCareAffirmations,
         predominantIntent: predominantIntent,
         featuredSpecialInterest: featuredSpecialInterest,
         summaryMessage: summaryMessage,
         generatedAt: generatedAt,
       );

  /// Returns a shallow copy of this [QuietDigest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  QuietDigest copyWith({
    String? spaceKey,
    int? totalReflections,
    int? totalCareAffirmations,
    String? predominantIntent,
    Object? featuredSpecialInterest = _Undefined,
    String? summaryMessage,
    DateTime? generatedAt,
  }) {
    return QuietDigest(
      spaceKey: spaceKey ?? this.spaceKey,
      totalReflections: totalReflections ?? this.totalReflections,
      totalCareAffirmations:
          totalCareAffirmations ?? this.totalCareAffirmations,
      predominantIntent: predominantIntent ?? this.predominantIntent,
      featuredSpecialInterest: featuredSpecialInterest is String?
          ? featuredSpecialInterest
          : this.featuredSpecialInterest,
      summaryMessage: summaryMessage ?? this.summaryMessage,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
