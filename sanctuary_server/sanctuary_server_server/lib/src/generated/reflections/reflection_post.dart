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
import 'package:serverpod/serverpod.dart' as _is;

/// A calm-tech fellowship reflection post persisted in PostgreSQL.
abstract class ReflectionPost implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      prayingCount: jsonSerialization['prayingCount'] as int,
      standingWithCount: jsonSerialization['standingWithCount'] as int,
      peaceCount: jsonSerialization['peaceCount'] as int,
      encouragedCount: jsonSerialization['encouragedCount'] as int,
    );
  }

  static final t = ReflectionPostTable();

  static const db = ReflectionPostRepository._();

  @override
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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ReflectionPost]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static ReflectionPostInclude include() {
    return ReflectionPostInclude._();
  }

  static ReflectionPostIncludeList includeList({
    _is.WhereExpressionBuilder<ReflectionPostTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ReflectionPostTable>? orderBy,
    _is.OrderByListBuilder<ReflectionPostTable>? orderByList,
    ReflectionPostInclude? include,
  }) {
    return ReflectionPostIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ReflectionPost.t),
      orderByList: orderByList?.call(ReflectionPost.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class ReflectionPostUpdateTable extends _is.UpdateTable<ReflectionPostTable> {
  ReflectionPostUpdateTable(super.table);

  _is.ColumnValue<String, String> authorName(String value) => _is.ColumnValue(
    table.authorName,
    value,
  );

  _is.ColumnValue<String, String> spaceKey(String value) => _is.ColumnValue(
    table.spaceKey,
    value,
  );

  _is.ColumnValue<String, String> intentTag(String value) => _is.ColumnValue(
    table.intentTag,
    value,
  );

  _is.ColumnValue<String, String> specialInterestTag(String? value) => _is.ColumnValue(
    table.specialInterestTag,
    value,
  );

  _is.ColumnValue<String, String> content(String value) => _is.ColumnValue(
    table.content,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) => _is.ColumnValue(
    table.createdAt,
    value,
  );

  _is.ColumnValue<int, int> prayingCount(int value) => _is.ColumnValue(
    table.prayingCount,
    value,
  );

  _is.ColumnValue<int, int> standingWithCount(int value) => _is.ColumnValue(
    table.standingWithCount,
    value,
  );

  _is.ColumnValue<int, int> peaceCount(int value) => _is.ColumnValue(
    table.peaceCount,
    value,
  );

  _is.ColumnValue<int, int> encouragedCount(int value) => _is.ColumnValue(
    table.encouragedCount,
    value,
  );
}

class ReflectionPostTable extends _is.Table<int?> {
  ReflectionPostTable({super.tableRelation}) : super(tableName: 'reflection_posts') {
    updateTable = ReflectionPostUpdateTable(this);
    authorName = _is.ColumnString(
      'authorName',
      this,
    );
    spaceKey = _is.ColumnString(
      'spaceKey',
      this,
    );
    intentTag = _is.ColumnString(
      'intentTag',
      this,
    );
    specialInterestTag = _is.ColumnString(
      'specialInterestTag',
      this,
    );
    content = _is.ColumnString(
      'content',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    prayingCount = _is.ColumnInt(
      'prayingCount',
      this,
    );
    standingWithCount = _is.ColumnInt(
      'standingWithCount',
      this,
    );
    peaceCount = _is.ColumnInt(
      'peaceCount',
      this,
    );
    encouragedCount = _is.ColumnInt(
      'encouragedCount',
      this,
    );
  }

  late final ReflectionPostUpdateTable updateTable;

  late final _is.ColumnString authorName;

  late final _is.ColumnString spaceKey;

  late final _is.ColumnString intentTag;

  late final _is.ColumnString specialInterestTag;

  late final _is.ColumnString content;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnInt prayingCount;

  late final _is.ColumnInt standingWithCount;

  late final _is.ColumnInt peaceCount;

  late final _is.ColumnInt encouragedCount;

  @override
  List<_is.Column> get columns => [
    id,
    authorName,
    spaceKey,
    intentTag,
    specialInterestTag,
    content,
    createdAt,
    prayingCount,
    standingWithCount,
    peaceCount,
    encouragedCount,
  ];
}

class ReflectionPostInclude extends _is.IncludeObject {
  ReflectionPostInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ReflectionPost.t;
}

class ReflectionPostIncludeList extends _is.IncludeList {
  ReflectionPostIncludeList._({
    _is.WhereExpressionBuilder<ReflectionPostTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ReflectionPost.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ReflectionPost.t;
}

class ReflectionPostRepository {
  const ReflectionPostRepository._();

  /// Returns a list of [ReflectionPost]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<ReflectionPost>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ReflectionPostTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ReflectionPostTable>? orderBy,
    _is.OrderByListBuilder<ReflectionPostTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ReflectionPost>(
      where: where?.call(ReflectionPost.t),
      orderBy: orderBy?.call(ReflectionPost.t),
      orderByList: orderByList?.call(ReflectionPost.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ReflectionPost] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<ReflectionPost?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ReflectionPostTable>? where,
    int? offset,
    _is.OrderByBuilder<ReflectionPostTable>? orderBy,
    _is.OrderByListBuilder<ReflectionPostTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ReflectionPost>(
      where: where?.call(ReflectionPost.t),
      orderBy: orderBy?.call(ReflectionPost.t),
      orderByList: orderByList?.call(ReflectionPost.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ReflectionPost] by its [id] or null if no such row exists.
  Future<ReflectionPost?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ReflectionPost>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ReflectionPost]s in the list and returns the inserted rows.
  ///
  /// The returned [ReflectionPost]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReflectionPost>> insert(
    _is.DatabaseSession session,
    List<ReflectionPost> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ReflectionPost>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ReflectionPost] and returns the inserted row.
  ///
  /// The returned [ReflectionPost] will have its `id` field set.
  Future<ReflectionPost> insertRow(
    _is.DatabaseSession session,
    ReflectionPost row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ReflectionPost>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ReflectionPost]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [ReflectionPost]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReflectionPost>> upsert(
    _is.DatabaseSession session,
    List<ReflectionPost> rows, {
    required _is.ColumnSelections<ReflectionPostTable> conflictColumns,
    _is.ColumnSelections<ReflectionPostTable>? updateColumns,
    _is.WhereExpressionBuilder<ReflectionPostTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ReflectionPost>(
      rows,
      conflictColumns: conflictColumns(ReflectionPost.t),
      updateColumns: updateColumns?.call(ReflectionPost.t),
      updateWhere: updateWhere?.call(ReflectionPost.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ReflectionPost] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [ReflectionPost] will have its `id` field set.
  Future<ReflectionPost?> upsertRow(
    _is.DatabaseSession session,
    ReflectionPost row, {
    required _is.ColumnSelections<ReflectionPostTable> conflictColumns,
    _is.ColumnSelections<ReflectionPostTable>? updateColumns,
    _is.WhereExpressionBuilder<ReflectionPostTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ReflectionPost>(
      row,
      conflictColumns: conflictColumns(ReflectionPost.t),
      updateColumns: updateColumns?.call(ReflectionPost.t),
      updateWhere: updateWhere?.call(ReflectionPost.t),
      transaction: transaction,
    );
  }

  /// Updates all [ReflectionPost]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReflectionPost>> update(
    _is.DatabaseSession session,
    List<ReflectionPost> rows, {
    _is.ColumnSelections<ReflectionPostTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ReflectionPost>(
      rows,
      columns: columns?.call(ReflectionPost.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ReflectionPost]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ReflectionPost> updateRow(
    _is.DatabaseSession session,
    ReflectionPost row, {
    _is.ColumnSelections<ReflectionPostTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ReflectionPost>(
      row,
      columns: columns?.call(ReflectionPost.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ReflectionPost] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ReflectionPost?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ReflectionPostUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ReflectionPost>(
      id,
      columnValues: columnValues(ReflectionPost.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ReflectionPost]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReflectionPost>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ReflectionPostUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ReflectionPostTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ReflectionPostTable>? orderBy,
    _is.OrderByListBuilder<ReflectionPostTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ReflectionPost>(
      columnValues: columnValues(ReflectionPost.t.updateTable),
      where: where(ReflectionPost.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ReflectionPost.t),
      orderByList: orderByList?.call(ReflectionPost.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ReflectionPost]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReflectionPost>> delete(
    _is.DatabaseSession session,
    List<ReflectionPost> rows, {
    _is.OrderByBuilder<ReflectionPostTable>? orderBy,
    _is.OrderByListBuilder<ReflectionPostTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ReflectionPost>(
      rows,
      orderBy: orderBy?.call(ReflectionPost.t),
      orderByList: orderByList?.call(ReflectionPost.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ReflectionPost].
  Future<ReflectionPost> deleteRow(
    _is.DatabaseSession session,
    ReflectionPost row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ReflectionPost>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReflectionPost>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ReflectionPostTable> where,
    _is.OrderByBuilder<ReflectionPostTable>? orderBy,
    _is.OrderByListBuilder<ReflectionPostTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ReflectionPost>(
      where: where(ReflectionPost.t),
      orderBy: orderBy?.call(ReflectionPost.t),
      orderByList: orderByList?.call(ReflectionPost.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ReflectionPostTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ReflectionPost>(
      where: where?.call(ReflectionPost.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ReflectionPost] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ReflectionPostTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ReflectionPost>(
      where: where(ReflectionPost.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
