'use strict';

/**
 * Appwrite entry that files a stored member_feedback note on GitHub.
 *
 * Runtime: node-22. Entrypoint: src/main.js. Function id: feedback-forward.
 * Execute permission is `any` because the caller has a Firebase session,
 * not an Appwrite user session. This file checks that Firebase ID token.
 *
 * Environment:
 * - FEEDBACK_GITHUB_PAT (secret). Fine-grained PAT that can create issues
 *   on neiljaywarner/belong_feedback. Never commit it. Never log it.
 *   Never pass it with --dart-define.
 * - FIREBASE_SERVICE_ACCOUNT_JSON (secret), or FCM_SERVICE_ACCOUNT_JSON
 *   when that account can read and update Firestore. Used only to patch
 *   githubIssueCreated / githubIssueNumber / githubIssueUrl. Client updates
 *   are denied by firestore.rules. Never commit the JSON. Never log the key.
 *
 * Absent PAT: the function does not create an issue.
 * Absent service account: an issue may still be created, and the response
 * says persisted: false. A later call can file a second issue.
 */

const crypto = require('crypto');
const {
  handleFeedbackForward,
  feedbackFromFirestoreDocument,
  firebaseProjectId,
  feedbackCollection,
} = require('./handle');
const { repository } = require('./format');

const certUrl =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

let cachedCerts = null;
let cachedAccessToken = null;

async function verifyIdToken(idToken) {
  if (typeof idToken !== 'string' || idToken.split('.').length !== 3) {
    throw new Error('missing id token');
  }
  const [headerPart, payloadPart, signaturePart] = idToken.split('.');
  let header;
  let payload;
  try {
    header = JSON.parse(Buffer.from(headerPart, 'base64url').toString());
    payload = JSON.parse(Buffer.from(payloadPart, 'base64url').toString());
  } catch (_) {
    throw new Error('missing id token');
  }
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

function feedbackUrl(feedbackId) {
  return (
    `https://firestore.googleapis.com/v1/projects/${firebaseProjectId}` +
    `/databases/(default)/documents/${feedbackCollection}/${encodeURIComponent(feedbackId)}`
  );
}

function serviceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON || process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    if (!parsed.client_email || !parsed.private_key) return null;
    return parsed;
  } catch (_) {
    return null;
  }
}

async function firestoreToken() {
  const account = serviceAccount();
  if (!account) return null;
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.exp > now + 60) return cachedAccessToken.token;
  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const claim = Buffer.from(
    JSON.stringify({
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/datastore',
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
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) throw new Error('could not authorize firestore update');
  const json = await response.json();
  cachedAccessToken = { token: json.access_token, exp: now + (json.expires_in || 3600) };
  return json.access_token;
}

async function readFeedback(feedbackId, idToken) {
  const admin = await firestoreToken();
  const bearer = admin || idToken;
  if (!bearer) return null;
  const response = await fetch(feedbackUrl(feedbackId), {
    headers: { Authorization: `Bearer ${bearer}` },
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) return null;
  return feedbackFromFirestoreDocument(await response.json());
}

async function updateFeedback(feedbackId, fields) {
  const admin = await firestoreToken();
  if (!admin) throw new Error('firestore credential is not configured');
  const url =
    `${feedbackUrl(feedbackId)}` +
    '?updateMask.fieldPaths=githubIssueCreated' +
    '&updateMask.fieldPaths=githubIssueNumber' +
    '&updateMask.fieldPaths=githubIssueUrl';
  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${admin}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      fields: {
        githubIssueCreated: { booleanValue: true },
        githubIssueNumber: { integerValue: String(fields.githubIssueNumber) },
        githubIssueUrl: { stringValue: fields.githubIssueUrl },
      },
    }),
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) throw new Error(`could not update feedback (${response.status})`);
}

function githubHeaders() {
  return {
    Authorization: `Bearer ${(process.env.FEEDBACK_GITHUB_PAT || '').trim()}`,
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'Content-Type': 'application/json',
    'User-Agent': 'belong-feedback-forward',
  };
}

async function ensureLabel(spec) {
  const response = await fetch(`https://api.github.com/repos/${repository}/labels`, {
    method: 'POST',
    headers: githubHeaders(),
    body: JSON.stringify(spec),
    signal: AbortSignal.timeout(8000),
  });
  if (response.ok || response.status === 422) return;
  throw new Error(`could not ensure label (${response.status})`);
}

async function createIssue(payload) {
  const response = await fetch(`https://api.github.com/repos/${repository}/issues`, {
    method: 'POST',
    headers: githubHeaders(),
    body: JSON.stringify({
      title: payload.title,
      body: payload.body,
      labels: payload.labels,
    }),
    signal: AbortSignal.timeout(8000),
  });
  if (response.status !== 201) throw new Error(`could not create issue (${response.status})`);
  const json = await response.json();
  return { number: json.number, htmlUrl: json.html_url };
}

function requestBody(req) {
  const raw = req && req.body;
  if (!raw) return {};
  if (typeof raw === 'object') return raw;
  return JSON.parse(raw);
}

module.exports = async ({ req, res, error }) => {
  try {
    const body = requestBody(req);
    const token = (process.env.FEEDBACK_GITHUB_PAT || '').trim();
    const result = await handleFeedbackForward(body, {
      verifyIdToken,
      readFeedback: (feedbackId) => readFeedback(feedbackId, body.idToken),
      canCreateIssue: token.length > 0,
      ensureLabel,
      createIssue,
      updateFeedback,
    });
    return res.json(result.body, result.status);
  } catch (caught) {
    const message = caught instanceof Error ? caught.message : 'feedback forward failed';
    error(message);
    return res.json({ error: 'feedback forward failed' }, 500);
  }
};
