'use strict';

/**
 * Copy one stored direct message into Appwrite.
 *
 * `main.js` supplies `deps`. Tests supply fakes. The body from the phone is
 * not the message: `copy` reads the Firestore document and writes those fields.
 * Firestore stays the copy the app reads. A failed write is this function's
 * problem. The sender already has the Firestore document.
 *
 * Row permissions are empty. This function does not enable reflection tables
 * and it does not grant guest create or guest update.
 */

const messageIdPattern = /^[A-Za-z0-9_-]{1,128}$/;
const mirrorTable = {
  databaseId: 'belong_community_db',
  tableId: 'direct_messages',
};

/**
 * @param {object} body
 * @param {object} deps
 */
async function handleDirectMessageMirror(body, deps) {
  let claims;
  try {
    claims = await deps.verifyIdToken(body && body.idToken);
  } catch (_) {
    return { status: 401, body: { error: 'unauthorized' } };
  }
  const uid = claims && (claims.sub || claims.user_id);
  const messageId = body && typeof body.messageId === 'string' ? body.messageId.trim() : '';
  if (!uid || !messageIdPattern.test(messageId)) {
    return { status: 400, body: { error: 'missing message' } };
  }

  const message = await deps.readMessage(messageId, body.idToken);
  if (!message) {
    return { status: 200, body: { mirrored: false, reason: 'message not readable' } };
  }
  if (!isStoredDirectMessage(message)) {
    return { status: 200, body: { mirrored: false, reason: 'not a stored thread' } };
  }
  if (message.senderId !== uid) return { status: 403, body: { error: 'not the sender' } };
  if (!deps.canWrite) {
    return {
      status: 200,
      body: { mirrored: false, reason: 'mirror credential is not configured' },
    };
  }

  try {
    await deps.writeMirror(messageId, mirrorRow(message));
  } catch (_) {
    return { status: 502, body: { mirrored: false, reason: 'mirror write failed' } };
  }
  return { status: 200, body: { mirrored: true } };
}

function isStoredDirectMessage(message) {
  const sender = message.senderId || '';
  const thread = message.threadId || '';
  if (!sender || sender === 'local-sender') return false;
  if (thread.startsWith('thread-local-')) return false;
  return true;
}

/**
 * The spare row. Keys match the Firestore document.
 *
 * @param {object} message
 */
function mirrorRow(message) {
  return {
    threadId: message.threadId || '',
    senderId: message.senderId || '',
    senderName: message.senderName || '',
    recipientIds: message.recipientIds || [],
    recipientNames: message.recipientNames || [],
    participantIds: message.participantIds || [],
    subject: message.subject || '',
    content: message.content || '',
    sentAt: message.sentAt || '',
  };
}

/**
 * Create-row body. Permissions stay empty so a guest cannot write the table.
 *
 * @param {string} messageId
 * @param {object} row
 */
function mirrorCreateBody(messageId, row) {
  return { rowId: messageId, data: row, permissions: [] };
}

function firestoreString(field) {
  if (!field) return '';
  if (typeof field.stringValue === 'string') return field.stringValue;
  if (typeof field.timestampValue === 'string') return field.timestampValue;
  return '';
}

function firestoreStringList(field) {
  const values = field && field.arrayValue && field.arrayValue.values;
  if (!Array.isArray(values)) return [];
  return values.map((item) => firestoreString(item)).filter((item) => item);
}

function messageFromFirestoreDocument(doc) {
  const fields = (doc && doc.fields) || {};
  return {
    threadId: firestoreString(fields.threadId),
    senderId: firestoreString(fields.senderId),
    senderName: firestoreString(fields.senderName),
    recipientIds: firestoreStringList(fields.recipientIds),
    recipientNames: firestoreStringList(fields.recipientNames),
    participantIds: firestoreStringList(fields.participantIds),
    subject: firestoreString(fields.subject),
    content: firestoreString(fields.content),
    sentAt: firestoreString(fields.sentAt),
  };
}

module.exports = {
  handleDirectMessageMirror,
  mirrorRow,
  mirrorCreateBody,
  messageFromFirestoreDocument,
  isStoredDirectMessage,
  messageIdPattern,
  mirrorTable,
};
