import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../notifications/data/notification_permissions_service.dart';
import '../../notifications/domain/direct_message_push_policy.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Messenger for the root [MaterialApp]. A banner needs this because the
/// arrival listener is not under a particular screen's [BuildContext].
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Recent banner bodies, so a Firestore snapshot and a foreground push for
/// the same message do not stack two banners.
final Set<String> _shownBannerBodies = <String>{};

/// Shows the ordinary in-app banner. Used only while the app is open.
/// A closed app uses the system notification instead.
void showDirectMessageBanner(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty || !_shownBannerBodies.add(trimmed)) return;
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) {
    _shownBannerBodies.remove(trimmed);
    return;
  }
  messenger.clearMaterialBanners();
  messenger.showMaterialBanner(
    MaterialBanner(
      content: Text(trimmed),
      leading: const Icon(Icons.message_outlined),
      actions: [
        TextButton(onPressed: messenger.hideCurrentMaterialBanner, child: const Text('Dismiss')),
      ],
    ),
  );
}

/// Listens for a new direct message while Belong is open and shows a
/// [MaterialBanner]. The first snapshot is the inbox the member already has,
/// so it does not announce those. A message this member sent is skipped.
///
/// A background or closed app does not use this path. The system shows the
/// Direct messages notification.
class DirectMessageArrivalHost extends ConsumerStatefulWidget {
  const DirectMessageArrivalHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DirectMessageArrivalHost> createState() => _DirectMessageArrivalHostState();
}

class _DirectMessageArrivalHostState extends ConsumerState<DirectMessageArrivalHost>
    with WidgetsBindingObserver {
  var _resumed = true;
  var _sawInitialSnapshot = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messages;
  StreamSubscription<User?>? _auth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForSignIn();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(calmNotificationPreferencesProvider.notifier).syncCloudPushRegistration());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(calmNotificationPreferencesProvider.notifier).syncCloudPushRegistration());
    }
  }

  void _listenForSignIn() {
    if (Firebase.apps.isEmpty) return;
    try {
      _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        _messages?.cancel();
        _messages = null;
        _sawInitialSnapshot = false;
        if (user == null) return;
        _messages = FirebaseFirestore.instance
            .collection('direct_messages')
            .where('participantIds', arrayContains: user.uid)
            .snapshots()
            .listen(_onInbox, onError: (Object _) {});
      });
    } on Object {
      // Firebase was not ready. An open app simply gets no banner.
    }
  }

  void _onInbox(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (!_sawInitialSnapshot) {
      _sawInitialSnapshot = true;
      return;
    }
    if (!_resumed) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final data = change.doc.data();
      if (data == null || data['senderId'] == uid) continue;
      final sender = data['senderName']?.toString();
      final content = data['content']?.toString() ?? '';
      showDirectMessageBanner(
        directMessagePushBody(
          senderName: (sender == null || sender.trim().isEmpty) ? 'Fellow Member' : sender,
          content: content,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth?.cancel();
    _messages?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
