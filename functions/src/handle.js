'use strict';

/**
 * Decide who gets a calm email for one new direct_messages document.
 *
 * `index.js` supplies `deps` from the Admin SDK. Tests supply fakes.
 * The document text is never copied into the subject. Sign-in addresses
 * are read only for members who already opted in, and they are not returned.
 */

const {
  shouldSendDirectMessageEmail,
  directMessageEmailSubject,
  directMessageEmailText,
  isStoredDirectMessage,
  isSampleRecipient,
} = require('./decide');

/**
 * @param {string} messageId
 * @param {Record<string, unknown>} data Firestore document fields.
 * @param {{
 *   readPreferences: (uid: string) => Promise<{ enabled?: boolean, schedule?: string } | null>,
 *   readEmail: (uid: string) => Promise<string>,
 *   canSend: boolean,
 *   sendEmail: (payload: { to: string, subject: string, text: string }) => Promise<void>,
 * }} deps
 */
async function handleDirectMessageCreated(messageId, data, deps) {
  const message = messageFromData(messageId, data);
  if (!isStoredDirectMessage(message)) {
    return { sent: 0, skipped: 0, failed: 0, reason: 'not a stored thread' };
  }

  const subject = directMessageEmailSubject(message.senderName, message.content);
  const text = directMessageEmailText(message.senderName, message.content);
  let sent = 0;
  let skipped = 0;
  let failed = 0;
  let blocked = false;

  for (const recipientId of message.recipientIds) {
    if (!recipientId || recipientId === message.senderId || isSampleRecipient(recipientId)) {
      skipped += 1;
      continue;
    }
    const prefs = await deps.readPreferences(recipientId);
    if (!prefs || prefs.enabled !== true || prefs.schedule === 'muted') {
      skipped += 1;
      continue;
    }
    const email = await deps.readEmail(recipientId);
    if (!shouldSendDirectMessageEmail(prefs, email)) {
      skipped += 1;
      continue;
    }
    if (!deps.canSend) {
      blocked = true;
      skipped += 1;
      continue;
    }
    try {
      await deps.sendEmail({ to: email, subject, text });
      sent += 1;
    } catch (_) {
      failed += 1;
    }
  }

  return {
    sent,
    skipped,
    failed,
    reason: blocked ? 'email credential is not configured' : null,
  };
}

function messageFromData(messageId, data) {
  const fields = data || {};
  return {
    id: messageId,
    threadId: asString(fields.threadId),
    senderId: asString(fields.senderId),
    senderName: asString(fields.senderName),
    recipientIds: asStringList(fields.recipientIds),
    content: asString(fields.content),
  };
}

function asString(value) {
  return typeof value === 'string' ? value : '';
}

function asStringList(value) {
  if (!Array.isArray(value)) return [];
  return value.filter((item) => typeof item === 'string' && item);
}

module.exports = {
  handleDirectMessageCreated,
  messageFromData,
};
