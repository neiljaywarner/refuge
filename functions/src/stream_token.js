'use strict';

const crypto = require('node:crypto');

/** Three hours. A one-hour call can start late without a 40-minute cutoff. */
const STREAM_TOKEN_TTL_SECONDS = 3 * 60 * 60;

function base64Url(value) {
  return Buffer.from(value).toString('base64url');
}

/**
 * Stream user token. HS256 JWT with `user_id`, `iat`, and `exp`.
 * The API secret is the HMAC key and is not placed in the payload.
 */
function mintStreamUserToken({ userId, secret, nowSeconds, ttlSeconds = STREAM_TOKEN_TTL_SECONDS }) {
  const header = base64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const exp = nowSeconds + ttlSeconds;
  const payload = base64Url(
    JSON.stringify({
      user_id: userId,
      iat: nowSeconds,
      exp,
    }),
  );
  const unsigned = `${header}.${payload}`;
  const signature = crypto.createHmac('sha256', secret).update(unsigned).digest('base64url');
  return { token: `${unsigned}.${signature}`, expiresAt: exp };
}

function verifyStreamUserToken(token, secret) {
  const parts = typeof token === 'string' ? token.split('.') : [];
  if (parts.length !== 3) return null;
  const unsigned = `${parts[0]}.${parts[1]}`;
  const expected = crypto.createHmac('sha256', secret).update(unsigned).digest('base64url');
  const actual = Buffer.from(parts[2]);
  const wanted = Buffer.from(expected);
  if (actual.length !== wanted.length || !crypto.timingSafeEqual(actual, wanted)) return null;
  try {
    return JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
  } catch (_) {
    return null;
  }
}

module.exports = {
  STREAM_TOKEN_TTL_SECONDS,
  mintStreamUserToken,
  verifyStreamUserToken,
};
