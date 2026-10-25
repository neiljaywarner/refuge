'use strict';

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { shouldSendDirectMessagePush, directMessagePushBody } = require('./decide');

initializeApp();

exports.shouldSendDirectMessagePush = shouldSendDirectMessagePush;

exports.onDirectMessageCreated = onDocumentCreated('direct_messages/{messageId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;

  const senderId = data.senderId;
  const recipients = Array.isArray(data.recipientIds) ? data.recipientIds : [];
  const body = directMessagePushBody(data.senderName, data.content);
  const db = getFirestore();
  const messaging = getMessaging();

  for (const uid of recipients) {
    if (!uid || uid === senderId) continue;
    const snap = await db.doc(`users/${uid}/notification_settings/push`).get();
    const prefs = snap.data();
    if (!shouldSendDirectMessagePush(prefs)) continue;

    await messaging.send({
      token: prefs.fcmToken,
      notification: {
        title: 'Belong',
        body,
      },
      data: {
        type: 'direct_message',
        category: 'direct_message',
        title: 'Belong',
        body,
      },
      android: {
        priority: 'normal',
        notification: {
          channelId: 'calm_digest_channel_v2',
          defaultSound: false,
          defaultVibrateTimings: false,
        },
      },
    });
  }
});
