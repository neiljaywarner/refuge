'use strict';

/**
 * Appwrite entry for direct-message notifications.
 *
 * Runtime: node-22. Entrypoint: src/main.js. Function id: dm-push.
 * Execute permission is `any` because the caller has a Firebase session,
 * not an Appwrite user session. This file checks that Firebase ID token.
 *
 * Environment, set by Appwrite unless noted:
 * - APPWRITE_FUNCTION_API_ENDPOINT
 * - APPWRITE_FUNCTION_PROJECT_ID
 * - APPWRITE_FUNCTION_API_KEY (dynamic key; scopes rows.read and rows.write)
 * - FCM_SERVICE_ACCOUNT_JSON (secret; the Firebase Admin SDK JSON).
 *   Absent or unreadable means the function reports that push is not
 *   configured and does not pretend a notification was sent.
 * Never commit that JSON. Never log the private key.
 */

const crypto = require('crypto');
const {
  handleDirectMessagePush,
  messageFromFirestoreDocument,
  firebaseProjectId,
  pushTable,
} = require('./handle');
const { directMessageAndroidConfig } = require('./decide');

const certUrl =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

let cachedCerts = null;
let cachedAccessToken = null;

async function verifyIdToken(idToken) {
  if (typeof idToken !== 'string' || idToken.split('.').length !== 3) {
    throw new Error('missing id token');
  }
  const [headerPart, payloadPart, signaturePart] = idToken.split('.');
  const header = JSON.parse(Buffer.from(headerPart, 'base64url').toString());
  const payload = JSON.parse(Buffer.from(payloadPart, 'base64url').toString());
  const now = Math.floor(Date.now() / 1000);
  if (payload.aud !== firebaseProjectId) throw new Error('wrong audience');
  if (payload.iss !== `https://securetoken.google.com/${firebaseProjectId}`) {
    throw new Error('wrong issuer');
  }
  if (typeof payload.exp !== 'number' || payload.exp < now) throw new Error('expired');
  if (!cachedCerts) {
    const response = await fetch(certUrl);
    if (!response.ok) throw new Error('could not load token certificates');
    cachedCerts = await response.json();
  }
  const certificate = cachedCerts[header.kid];
  if (!certificate) throw new Error('unknown token key');
  const verifier = crypto.createVerify('RSA-SHA256');
  verifier.update(`${headerPart}.${payloadPart}`);
  const valid = verifier.verify(certificate, Buffer.from(signaturePart, 'base64url'));
  if (!valid) throw new Error('bad token signature');
  return payload;
}

async function readMessage(messageId, idToken) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${firebaseProjectId}` +
    `/databases/(default)/documents/direct_messages/${encodeURIComponent(messageId)}`;
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  if (!response.ok) return null;
  return messageFromFirestoreDocument(await response.json());
}

function appwriteHeaders() {
  return {
    'Content-Type': 'application/json',
    'X-Appwrite-Project': process.env.APPWRITE_FUNCTION_PROJECT_ID,
    'X-Appwrite-Key':
      process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY,
  };
}

function deviceUrl(uid) {
  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  return (
    `${endpoint}/tablesdb/${pushTable.databaseId}/tables/${pushTable.tableId}` +
    `/rows/${encodeURIComponent(uid)}`
  );
}

async function readDevice(uid) {
  const response = await fetch(deviceUrl(uid), { headers: appwriteHeaders() });
  if (!response.ok) return null;
  const row = await response.json();
  return row.data || row;
}

async function writeDevice(uid, data) {
  const headers = appwriteHeaders();
  const created = await fetch(deviceUrl(uid).replace(/\/rows\/[^/]+$/, '/rows'), {
    method: 'POST',
    headers,
    body: JSON.stringify({ rowId: uid, data, permissions: [] }),
  });
  if (created.ok || created.status === 409) {
    if (created.ok) return;
    const updated = await fetch(deviceUrl(uid), {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ data }),
    });
    if (!updated.ok) throw new Error(`could not update push device (${updated.status})`);
    return;
  }
  throw new Error(`could not store push device (${created.status})`);
}

function serviceAccount() {
  const raw = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    if (!parsed.client_email || !parsed.private_key) return null;
    return parsed;
  } catch (_) {
    return null;
  }
}

async function accessToken(account) {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.exp > now + 60) return cachedAccessToken.token;
  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const claim = Buffer.from(
    JSON.stringify({
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  ).toString('base64url');
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(`${header}.${claim}`);
  const assertion = `${header}.${claim}.${signer.sign(account.private_key).toString('base64url')}`;
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) throw new Error('could not authorize push send');
  const json = await response.json();
  cachedAccessToken = { token: json.access_token, exp: now + (json.expires_in || 3600) };
  return json.access_token;
}

async function sendPush(account, payload) {
  const token = await accessToken(account);
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: payload.token,
          notification: { title: 'Belong', body: payload.body },
          data: {
            type: 'direct_message',
            category: 'direct_message',
            title: 'Belong',
            body: payload.body,
            quiet: payload.quiet ? 'true' : 'false',
          },
          android: payload.android || directMessageAndroidConfig('twiceDaily'),
        },
      }),
    },
  );
  if (!response.ok) throw new Error(`push was refused (${response.status})`);
}

module.exports = async ({ req, res, error }) => {
  try {
    const body = JSON.parse((req && req.body) || '{}');
    const account = serviceAccount();
    const result = await handleDirectMessagePush(body, {
      verifyIdToken,
      readMessage,
      readDevice,
      writeDevice,
      canSend: account != null,
      sendPush: (payload) => sendPush(account, payload),
    });
    return res.json(result.body, result.status);
  } catch (caught) {
    error(caught instanceof Error ? caught.message : 'push failed');
    return res.json({ error: 'push failed' }, 500);
  }
};
