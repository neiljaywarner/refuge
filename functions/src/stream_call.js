'use strict';

const { mintStreamUserToken } = require('./stream_token');

const CALL_ID = /^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/;
const USER_ID = /^[A-Za-z0-9_-]{1,128}$/;

function normalizeCallId(value) {
  if (typeof value !== 'string') return '';
  const normalized = value.trim().toLowerCase().replace(/\s+/g, '-');
  if (normalized.includes('--')) return '';
  return CALL_ID.test(normalized) ? normalized : '';
}

function normalizeUserId(value) {
  if (typeof value !== 'string') return '';
  const trimmed = value.trim();
  return USER_ID.test(trimmed) ? trimmed : '';
}

// Firebase Hosting (the dev site and preview channels) and the local
// emulator may call this function. Any other origin is refused before the
// Firebase ID token is checked and before the Stream secret is read, so a
// random site cannot use a member's browser to mint a token.
function isAllowedOrigin(origin) {
  if (typeof origin !== 'string' || origin.length === 0 || origin.length > 200) return false;
  let url;
  try {
    url = new URL(origin);
  } catch (_) {
    return false;
  }
  if (url.username || url.password) return false;
  if (url.protocol === 'http:' && (url.hostname === 'localhost' || url.hostname === '127.0.0.1')) {
    return true;
  }
  if (url.protocol !== 'https:') return false;
  return url.hostname.endsWith('.web.app') || url.hostname.endsWith('.firebaseapp.com');
}

function applyCors(req, res) {
  const origin = req.headers.origin;
  if (!isAllowedOrigin(origin)) return false;
  res.set('Access-Control-Allow-Origin', origin);
  res.set('Vary', 'Origin');
  res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Max-Age', '600');
  return true;
}

// The Flutter SDK connects with the public API key. Some dashboards label
// that same value as an app id. The secret is never a stand-in for either.
function resolveApiKey(apiKey, appId) {
  const key = typeof apiKey === 'string' ? apiKey.trim() : '';
  if (key) return key;
  return typeof appId === 'string' ? appId.trim() : '';
}

/**
 * Mints a Stream user token for a signed-in Firebase member.
 * The handler never reads or writes direct messages, and the JSON body
 * never includes the API secret.
 */
async function handleMintStreamCallToken(req, res, deps) {
  const corsOk = applyCors(req, res);
  if (req.method === 'OPTIONS') {
    res.status(corsOk ? 204 : 403).send('');
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'POST only.' });
    return;
  }
  if (req.headers.origin && !corsOk) {
    res.status(403).json({ error: 'This preview cannot mint a call token.' });
    return;
  }

  const header = req.headers.authorization || '';
  const match = /^Bearer\s+(\S+)$/.exec(header);
  if (!match) {
    res.status(401).json({ error: 'Sign in is required.' });
    return;
  }

  let decoded;
  try {
    decoded = await deps.verifyIdToken(match[1]);
  } catch (_) {
    res.status(401).json({ error: 'Sign in is required.' });
    return;
  }
  const userId = normalizeUserId(decoded && decoded.uid);
  if (!userId) {
    res.status(401).json({ error: 'Sign in is required.' });
    return;
  }

  const body = req.body && typeof req.body === 'object' ? req.body : {};
  const callId = normalizeCallId(body.callId);
  if (!callId) {
    res.status(400).json({
      error: 'Choose a short call name using letters, numbers, and dashes.',
    });
    return;
  }

  // Auth, origin, and the call id are settled above. Only then is the secret
  // read, and only as the HMAC key. It is not copied into the JSON response.
  const apiKey = resolveApiKey(deps.apiKey(), deps.appId ? deps.appId() : '');
  const apiSecret = typeof deps.apiSecret() === 'string' ? deps.apiSecret().trim() : '';
  if (!apiKey || !apiSecret) {
    console.info(JSON.stringify({ event: 'mintStreamCallToken', ok: false, reason: 'not-configured' }));
    res.status(503).json({ error: 'Video calling is not configured on this preview.' });
    return;
  }

  const nowSeconds = deps.nowSeconds();
  const minted = mintStreamUserToken({ userId, secret: apiSecret, nowSeconds });
  console.info(JSON.stringify({ event: 'mintStreamCallToken', ok: true, callId }));
  res.status(200).json({
    apiKey,
    token: minted.token,
    userId,
    callId,
    expiresAt: minted.expiresAt,
  });
}

module.exports = {
  normalizeCallId,
  isAllowedOrigin,
  resolveApiKey,
  handleMintStreamCallToken,
};
