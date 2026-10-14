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

/// A calm-tech fellowship reflection post persisted in PostgreSQL.
abstract class ReflectionPost
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ReflectionPost._({
    this.id,
    required this.authorName,
    required this.spaceKey,
    required this.intentTag,
    this.specialInterestTag,
    required this.content,
    required this.createdAt,
    required this.prayingCount,
    required this.standingWithCount,
    required this.peaceCount,
    required this.encouragedCount,
  });

  factory ReflectionPost({
    int? id,
    required String authorName,
    required String spaceKey,
    required String intentTag,
    String? specialInterestTag,
    required String content,
    required DateTime createdAt,
    required int prayingCount,
    required int standingWithCount,
    required int peaceCount,
    required int encouragedCount,
  }) = _ReflectionPostImpl;

  factory ReflectionPost.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReflectionPost(
      id: jsonSerialization['id'] as int?,
      authorName: jsonSerialization['authorName'] as String,
      spaceKey: jsonSerialization['spaceKey'] as String,
      intentTag: jsonSerialization['intentTag'] as String,
      specialInterestTag: jsonSerialization['specialInterestTag'] as String?,
      content: jsonSerialization['content'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      prayingCount: jsonSerialization['prayingCount'] as int,
      standingWithCount: jsonSerialization['standingWithCount'] as int,
      peaceCount: jsonSerialization['peaceCount'] as int,
      encouragedCount: jsonSerialization['encouragedCount'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String authorName;

  String spaceKey;

  String intentTag;

  String? specialInterestTag;

  String content;

  DateTime createdAt;

  int prayingCount;

  int standingWithCount;

  int peaceCount;

  int encouragedCount;

  /// Returns a shallow copy of this [ReflectionPost]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ReflectionPost copyWith({
    int? id,
    String? authorName,
    String? spaceKey,
    String? intentTag,
    String? specialInterestTag,
    String? content,
    DateTime? createdAt,
    int? prayingCount,
    int? standingWithCount,
    int? peaceCount,
    int? encouragedCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReflectionPost',
      if (id != null) 'id': id,
      'authorName': authorName,
      'spaceKey': spaceKey,
      'intentTag': intentTag,
      if (specialInterestTag != null) 'specialInterestTag': specialInterestTag,
      'content': content,
      'createdAt': createdAt.toJson(),
      'prayingCount': prayingCount,
      'standingWithCount': standingWithCount,
      'peaceCount': peaceCount,
      'encouragedCount': encouragedCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReflectionPost',
      if (id != null) 'id': id,
      'authorName': authorName,
      'spaceKey': spaceKey,
      'intentTag': intentTag,
      if (specialInterestTag != null) 'specialInterestTag': specialInterestTag,
      'content': content,
      'createdAt': createdAt.toJson(),
      'prayingCount': prayingCount,
      'standingWithCount': standingWithCount,
      'peaceCount': peaceCount,
      'encouragedCount': encouragedCount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReflectionPostImpl extends ReflectionPost {
  _ReflectionPostImpl({
    int? id,
    required String authorName,
    required String spaceKey,
    required String intentTag,
    String? specialInterestTag,
    required String content,
    required DateTime createdAt,
    required int prayingCount,
    required int standingWithCount,
    required int peaceCount,
    required int encouragedCount,
  }) : super._(
         id: id,
         authorName: authorName,
         spaceKey: spaceKey,
         intentTag: intentTag,
         specialInterestTag: specialInterestTag,
         content: content,
         createdAt: createdAt,
         prayingCount: prayingCount,
         standingWithCount: standingWithCount,
         peaceCount: peaceCount,
         encouragedCount: encouragedCount,
       );

  /// Returns a shallow copy of this [ReflectionPost]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ReflectionPost copyWith({
    Object? id = _Undefined,
    String? authorName,
    String? spaceKey,
    String? intentTag,
    Object? specialInterestTag = _Undefined,
    String? content,
    DateTime? createdAt,
    int? prayingCount,
    int? standingWithCount,
    int? peaceCount,
    int? encouragedCount,
  }) {
    return ReflectionPost(
      id: id is int? ? id : this.id,
      authorName: authorName ?? this.authorName,
      spaceKey: spaceKey ?? this.spaceKey,
      intentTag: intentTag ?? this.intentTag,
      specialInterestTag: specialInterestTag is String?
          ? specialInterestTag
          : this.specialInterestTag,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      prayingCount: prayingCount ?? this.prayingCount,
      standingWithCount: standingWithCount ?? this.standingWithCount,
      peaceCount: peaceCount ?? this.peaceCount,
      encouragedCount: encouragedCount ?? this.encouragedCount,
    );
  }
}
