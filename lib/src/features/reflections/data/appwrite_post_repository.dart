import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';

import '../../../core/appwrite/appwrite_client_factory.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../admin/data/authored_document_erase.dart';
import '../domain/post.dart';
import 'local_account_scope.dart';
import 'local_post_repository.dart';
import 'pending_post_outbox.dart';
import 'post_repository.dart';

export 'post_merge.dart';

/// Cloud copy of a reflection feed. Production uses Appwrite TablesDB.
/// Tests supply an in-memory implementation so they never open a socket.
abstract class ReflectionMirror {
  Future<void> upsertPost(Post post);
  Future<void> incrementReaction({required String postId, required String column});
  Future<List<Post>> listPosts({required String spaceKey});
  Stream<Post> watchPosts({required String spaceKey});
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  });
}

/// Appwrite TablesDB mirror for reflections and quiet digests.
class AppwriteReflectionMirror implements ReflectionMirror {
  AppwriteReflectionMirror(this.services, this.config);

  final AppwriteServices services;
  final AppwriteConfig config;

  TablesDB get _tables => services.tables;

  @override
  Future<void> upsertPost(Post post) async {
    final rowId = appwriteRowId(post.id);
    final data = reflectionRowData(post);
    try {
      await _tables.updateRow(
        databaseId: config.databaseId,
        tableId: AppwriteConfig.reflectionTableId,
        rowId: rowId,
        data: data,
      );
    } on AppwriteException catch (error) {
      if (error.code != 404) rethrow;
      await _tables.createRow(
        databaseId: config.databaseId,
        tableId: AppwriteConfig.reflectionTableId,
        rowId: rowId,
        data: data,
      );
    }
  }

  @override
  Future<void> incrementReaction({required String postId, required String column}) =>
      _tables.incrementRowColumn(
        databaseId: config.databaseId,
        tableId: AppwriteConfig.reflectionTableId,
        rowId: appwriteRowId(postId),
        column: column,
        value: 1,
      );

  @override
  Future<List<Post>> listPosts({required String spaceKey}) async {
    final rows = await _tables.listRows(
      databaseId: config.databaseId,
      tableId: AppwriteConfig.reflectionTableId,
      queries: [
        Query.equal('spaceKey', canonicalSpaceKey(spaceKey)),
        Query.orderDesc('createdAt'),
        Query.limit(100),
      ],
    );
    return [for (final row in rows.rows) ?_postFromRow(row)];
  }

  @override
  Stream<Post> watchPosts({required String spaceKey}) {
    final controller = StreamController<Post>();
    final channel = Channel.tablesdb(config.databaseId)
        .table(AppwriteConfig.reflectionTableId)
        .row();
    final subscription = services.realtime.subscribe([channel]);
    final wanted = canonicalSpaceKey(spaceKey);
    final listener = subscription.stream.listen((message) {
      final post = postFromAppwritePayload(message.payload);
      if (post != null && post.spaceKey == wanted && !controller.isClosed) {
        controller.add(post);
      }
    }, onError: controller.addError);
    controller.onCancel = () async {
      await listener.cancel();
      await subscription.close();
    };
    return controller.stream;
  }

  @override
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  });
}
