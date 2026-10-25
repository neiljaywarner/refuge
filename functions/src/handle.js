'use strict';

const {
  shouldSendDirectMessagePush,
  directMessagePushBody,
  directMessageAndroidConfig,
} = require('./decide');

const firebaseProjectId = 'belongonthespectrum';
const pushTable = {
  databaseId: 'belong_community_db',
  tableId: 'push_devices',
};

/**
 * Register a signed-in member's token, or send an OS notification for one
 * stored direct message. `deps` are injected so tests never touch the network.
 */
async function handleDirectMessagePush(body, deps) {
  const action = body && body.action;
  if (action === 'register') return registerDevice(body, deps);
  if (action === 'send') return sendForMessage(body, deps);
  return { status: 400, body: { error: 'unknown action' } };
}

async function registerDevice(body, deps) {
  const claims = await deps.verifyIdToken(body.idToken);
  const uid = claims.sub || claims.user_id;
  if (!uid) return { status: 401, body: { error: 'missing member' } };

  const schedule = typeof body.schedule === 'string' ? body.schedule : 'twiceDaily';
  const enabled = body.enabled === true && schedule !== 'muted';
  const rawToken = typeof body.fcmToken === 'string' ? body.fcmToken.trim() : '';
  const fcmToken = rawToken && !rawToken.startsWith('fcm_token_calm') ? rawToken : '';

  await deps.writeDevice(uid, { enabled, schedule, fcmToken });
  return { status: 200, body: { ok: true, registered: enabled && fcmToken.length > 0 } };
}

async function sendForMessage(body, deps) {
  const claims = await deps.verifyIdToken(body.idToken);
  const uid = claims.sub || claims.user_id;
  const messageId = typeof body.messageId === 'string' ? body.messageId.trim() : '';
  if (!uid || !messageId) return { status: 400, body: { error: 'missing message' } };

  const message = await deps.readMessage(messageId, body.idToken);
  if (!message) return { status: 200, body: { sent: 0, reason: 'message not readable' } };
  if (message.senderId !== uid) return { status: 403, body: { error: 'not the sender' } };

  const text = directMessagePushBody(message.senderName, message.content);
  let sent = 0;
  let skipped = 0;
  for (const recipientId of message.recipientIds || []) {
    if (!recipientId || recipientId === uid) continue;
    const prefs = await deps.readDevice(recipientId);
    if (!shouldSendDirectMessagePush(prefs)) {
      skipped += 1;
      continue;
    }
    if (!deps.canSend) {
      skipped += 1;
      continue;
    }
    await deps.sendPush({
      token: prefs.fcmToken,
      body: text,
      android: directMessageAndroidConfig(prefs.schedule),
      quiet: prefs.schedule === 'immediateGentle',
    });
    sent += 1;
  }

  return {
    status: 200,
    body: {
      sent,
      skipped,
      reason: deps.canSend ? null : 'push credential is not configured',
    },
  };
}

function firestoreString(field) {
  return field && typeof field.stringValue === 'string' ? field.stringValue : '';
}

function firestoreStringList(field) {
  const values = field && field.arrayValue && field.arrayValue.values;
  if (!Array.isArray(values)) return [];
  return values.map((item) => firestoreString(item)).filter((item) => item);
}

function messageFromFirestoreDocument(doc) {
  const fields = (doc && doc.fields) || {};
  return {
    senderId: firestoreString(fields.senderId),
    senderName: firestoreString(fields.senderName),
    content: firestoreString(fields.content),
    recipientIds: firestoreStringList(fields.recipientIds),
  };
}

module.exports = {
  handleDirectMessagePush,
  messageFromFirestoreDocument,
  firebaseProjectId,
  pushTable,
};
