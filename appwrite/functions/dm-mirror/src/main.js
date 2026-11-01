'use strict';

/**
 * Appwrite entry for the one-way direct-message mirror.
 *
 * Runtime: node-22. Entrypoint: src/main.js. Function id: dm-mirror.
 * Execute permission is `any` because the caller has a Firebase session,
 * not an Appwrite user session. This file checks that Firebase ID token.
 *
 * The API key is APPWRITE_FUNCTION_API_KEY, or the secret APPWRITE_API_KEY
 * when the dynamic key is empty. The phone never receives that key.
 * Reflection tables are not written and are not re-enabled here.
 *
 * Environment, set by Appwrite unless noted:
 * - APPWRITE_FUNCTION_API_ENDPOINT
 * - APPWRITE_FUNCTION_PROJECT_ID
 * - APPWRITE_FUNCTION_API_KEY (dynamic key; scopes rows.read and rows.write)
 * - APPWRITE_API_KEY (optional secret fallback, same scopes)
 * Never commit either key. Never log it.
 */

const crypto = require('crypto');
const {
  handleDirectMessageMirror,
  messageFromFirestoreDocument,
  mirrorCreateBody,
  mirrorTable,
} = require('./handle');

const firebaseProjectId = 'belongonthespectrum';
const certUrl =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

let cachedCerts = null;

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

function mirrorApiKey() {
  return process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY || '';
}

function appwriteHeaders(apiKey) {
  return {
    'Content-Type': 'application/json',
    'X-Appwrite-Project': process.env.APPWRITE_FUNCTION_PROJECT_ID,
    'X-Appwrite-Key': apiKey,
  };
}

function rowsCollectionUrl() {
  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  return (
    `${endpoint}/tablesdb/${mirrorTable.databaseId}/tables/${mirrorTable.tableId}/rows`
  );
}

async function writeMirror(apiKey, messageId, row) {
  const headers = appwriteHeaders(apiKey);
  const created = await fetch(rowsCollectionUrl(), {
    method: 'POST',
    headers,
    body: JSON.stringify(mirrorCreateBody(messageId, row)),
  });
  if (created.ok) return;
  if (created.status === 409) {
    const updated = await fetch(`${rowsCollectionUrl()}/${encodeURIComponent(messageId)}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ data: row }),
    });
    if (!updated.ok) throw new Error(`could not update mirror (${updated.status})`);
    return;
  }
  throw new Error(`could not store mirror (${created.status})`);
}

module.exports = async ({ req, res, error }) => {
  try {
    const body = JSON.parse((req && req.body) || '{}');
    const apiKey = mirrorApiKey();
    const result = await handleDirectMessageMirror(body, {
      verifyIdToken,
      readMessage,
      canWrite: apiKey.length > 0,
      writeMirror: (messageId, row) => writeMirror(apiKey, messageId, row),
    });
    return res.json(result.body, result.status);
  } catch (caught) {
    error(caught instanceof Error ? caught.message : 'mirror failed');
    return res.json({ error: 'mirror failed' }, 500);
  }
};
