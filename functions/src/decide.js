'use strict';

/**
 * Send rule for a calm direct-message email.
 *
 * This file is the JavaScript copy of
 * lib/src/features/notifications/domain/direct_message_email_policy.dart.
 * Change both together. Mail goes out only when alerts are on, the schedule
 * is not muted, and the Cloud Function has a real sign-in address. The
 * subject names the sender and says a message is waiting. It never includes
 * the message body or an email address.
 */

function isDeliverableDirectMessageAddress(email) {
  const address = typeof email === 'string' ? email.trim() : '';
  if (!address || address.includes(' ') || address.includes('\n')) return false;
  const at = address.indexOf('@');
  if (at <= 0 || at !== address.lastIndexOf('@') || at === address.length - 1) return false;
  return true;
}

/**
 * @param {{ enabled?: boolean, schedule?: string } | null} prefs
 * @param {string} email
 * @returns {boolean}
 */
function shouldSendDirectMessageEmail(prefs, email) {
  if (!prefs || prefs.enabled !== true) return false;
  if (prefs.schedule === 'muted') return false;
  return isDeliverableDirectMessageAddress(email);
}

/**
 * @param {string} senderName
 * @param {string} content
 * @returns {string}
 */
function calmDirectMessageSenderName(senderName, content) {
  const name = String(senderName || '').replace(/\s+/g, ' ').trim();
  const body = String(content || '').trim();
  if (!name || name.includes('@') || name.includes('\n')) return 'Fellow Member';
  if (body.length >= 8 && (name === body || name.includes(body))) return 'Fellow Member';
  if (name.length > 80) return name.slice(0, 80).trim();
  return name || 'Fellow Member';
}

/**
 * @param {string} senderName
 * @param {string} content
 * @returns {string}
 */
function directMessageEmailSubject(senderName, content) {
  const name = calmDirectMessageSenderName(senderName, content);
  const subject = `${name} — a message is waiting`;
  if (subject.includes('@')) return 'Fellow Member — a message is waiting';
  const body = String(content || '').trim();
  if (body.length >= 8 && subject.includes(body)) return 'Fellow Member — a message is waiting';
  return subject;
}

/**
 * @param {string} senderName
 * @param {string} content
 * @returns {string}
 */
function directMessageEmailText(senderName, content) {
  const name = calmDirectMessageSenderName(senderName, content);
  return `${name} sent you a message in Belong. Open the app when you are ready.`;
}

/**
 * Sample threads and device-only sends never create this shape.
 *
 * @param {{ senderId?: string, threadId?: string, recipientIds?: string[] } | null} message
 * @returns {boolean}
 */
function isStoredDirectMessage(message) {
  if (!message) return false;
  const sender = typeof message.senderId === 'string' ? message.senderId : '';
  const thread = typeof message.threadId === 'string' ? message.threadId : '';
  if (!sender || sender === 'local-sender') return false;
  if (thread.startsWith('thread-local-')) return false;
  if (!Array.isArray(message.recipientIds) || message.recipientIds.length === 0) return false;
  return true;
}

function isSampleRecipient(recipientId) {
  return typeof recipientId === 'string' && recipientId.startsWith('sample-');
}

module.exports = {
  shouldSendDirectMessageEmail,
  isDeliverableDirectMessageAddress,
  calmDirectMessageSenderName,
  directMessageEmailSubject,
  directMessageEmailText,
  isStoredDirectMessage,
  isSampleRecipient,
};
