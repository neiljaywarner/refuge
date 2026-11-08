'use strict';

/**
 * Calm email when a direct_messages document is created (#570).
 *
 * The phone does not send this mail. Firestore invokes
 * `calmDirectMessageEmail` after a real document is stored. Sample threads
 * and device-only sends never create that document.
 *
 * Deploy needs the Blaze plan. The Spark plan cannot build Cloud Functions.
 * Set the secret DM_EMAIL_TRANSPORT_JSON. Do not commit it.
 *
 * {
 *   "endpoint": "https://api.resend.com/emails",
 *   "apiKey": "<provider key>",
 *   "from": "Belong <notifications@belongonthespectrum.com>"
 * }
 *
 * The function reads users/{uid}/notification_settings/push with the Admin
 * SDK, then the sign-in address from Firebase Auth. The public profile is
 * not used. The address is not written into the subject or the logs.
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { handleDirectMessageCreated } = require('./handle');
const { parseEmailTransport } = require('./transport');
const { handleMintStreamCallToken } = require('./stream_call');
const { FirestoreInviteStore } = require('./stream_invite_store');
const { prepareGuestOnCall } = require('./stream_video_api');
const crypto = require('node:crypto');

const transportSecret = defineSecret('DM_EMAIL_TRANSPORT_JSON');
const streamApiKey = defineSecret('STREAM_API_KEY');
const streamApiSecret = defineSecret('STREAM_API_SECRET');

if (getApps().length === 0) initializeApp();

async function readPreferences(uid) {
  const doc = await getFirestore().doc(`users/${uid}/notification_settings/push`).get();
  if (!doc.exists) return null;
  const data = doc.data() || {};
  return {
    enabled: data.enabled === true,
    schedule: typeof data.schedule === 'string' ? data.schedule : 'twiceDaily',
  };
}

async function readEmail(uid) {
  try {
    const user = await getAuth().getUser(uid);
    return typeof user.email === 'string' ? user.email : '';
  } catch (_) {
    return '';
  }
}

async function sendEmail(transport, payload) {
  const response = await fetch(transport.endpoint, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${transport.apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: transport.from,
      to: [payload.to],
      subject: payload.subject,
      text: payload.text,
    }),
  });
  if (!response.ok) throw new Error(`email was refused (${response.status})`);
}

exports.calmDirectMessageEmail = onDocumentCreated(
  {
    document: 'direct_messages/{messageId}',
    secrets: [transportSecret],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    let raw = '';
    try {
      raw = transportSecret.value() || '';
    } catch (_) {
      raw = '';
    }
    const transport = parseEmailTransport(raw);
    const messageId = (event.params && event.params.messageId) || snap.id;
    const result = await handleDirectMessageCreated(messageId, snap.data() || {}, {
      readPreferences,
      readEmail,
      canSend: transport != null,
      sendEmail: (payload) => sendEmail(transport, payload),
    });
    console.info(
      JSON.stringify({
        event: 'calmDirectMessageEmail',
        sent: result.sent,
        skipped: result.skipped,
        failed: result.failed,
        reason: result.reason,
      }),
    );
  },
);

function readBoundSecret(secret) {
  try {
    return secret.value() || '';
  } catch (_) {
    return '';
  }
}

/**
 * Preview-only Stream Video tokens (#872, #904).
 *
 * The API secret stays in this function. The direct-message email function
 * does not receive it, and this function does not read direct messages.
 * IAM is public so a browser can POST. Member actions still require a
 * Firebase ID token. A guest join requires an invite token instead.
 * The response never includes the secret.
 *
 * Invites live in Firestore under the Admin SDK. Clients cannot read them.
 *
 * `cors: false` turns off Firebase's open CORS helper. The handler allowlists
 * Firebase Hosting and loopback itself.
 */
exports.mintStreamCallToken = onRequest(
  {
    secrets: [streamApiKey, streamApiSecret],
    cors: false,
    invoker: 'public',
    timeoutSeconds: 20,
    memory: '256MiB',
  },
  (req, res) =>
    handleMintStreamCallToken(req, res, {
      verifyIdToken: (token) => getAuth().verifyIdToken(token),
      apiKey: () => readBoundSecret(streamApiKey) || process.env.STREAM_API_KEY || '',
      apiSecret: () => readBoundSecret(streamApiSecret) || process.env.STREAM_API_SECRET || '',
      appId: () => process.env.STREAM_APP_ID || '',
      nowSeconds: () => Math.floor(Date.now() / 1000),
      store: new FirestoreInviteStore(getFirestore()),
      prepareGuestCall: (input) => prepareGuestOnCall({ ...input, fetchImpl: fetch }),
      randomInviteToken: () => crypto.randomBytes(32).toString('base64url'),
      randomGuestId: () => `g${crypto.randomBytes(16).toString('hex')}`,
    }),
);
