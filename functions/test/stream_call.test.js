'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { mintStreamUserToken, verifyStreamUserToken } = require('../src/stream_token');
const {
  normalizeCallId,
  isAllowedOrigin,
  resolveApiKey,
  handleMintStreamCallToken,
} = require('../src/stream_call');

const secret = 'unit-test-stream-secret';
const apiKey = 'unit-test-stream-key';

test('user token is HS256 and does not contain the secret', () => {
  const minted = mintStreamUserToken({
    userId: 'member1',
    secret,
    nowSeconds: 1_700_000_000,
  });
  assert.equal(minted.token.includes(secret), false);
  const payload = verifyStreamUserToken(minted.token, secret);
  assert.equal(payload.user_id, 'member1');
  assert.equal(payload.iat, 1_700_000_000);
  assert.equal(payload.exp, minted.expiresAt);
  assert.equal(verifyStreamUserToken(minted.token, 'other-secret'), null);
});

test('call names stay short and origin checks stay on hosting', () => {
  assert.equal(normalizeCallId(' Monthly '), 'monthly');
  assert.equal(normalizeCallId('fellowship hour'), 'fellowship-hour');
  assert.equal(normalizeCallId('a'), '');
  assert.equal(normalizeCallId('bad--name'), '');
  assert.equal(normalizeCallId('../admin'), '');
  assert.equal(isAllowedOrigin('https://dev-belongonthespectrum.web.app'), true);
  assert.equal(isAllowedOrigin('https://belongonthespectrum--stream-video-abc.web.app'), true);
  assert.equal(isAllowedOrigin('http://127.0.0.1:5001'), true);
  assert.equal(isAllowedOrigin('http://example.com'), false);
  assert.equal(isAllowedOrigin('https://evil.example'), false);
  assert.equal(resolveApiKey('', 'dashboard-app'), 'dashboard-app');
  assert.equal(resolveApiKey('public-key', 'dashboard-app'), 'public-key');
});

function mockResponse() {
  return {
    statusCode: 0,
    body: undefined,
    headers: {},
    set(name, value) {
      this.headers[name.toLowerCase()] = value;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
    },
    send() {},
  };
}

test('a signed-in member receives a token and not the secret', async () => {
  const res = mockResponse();
  await handleMintStreamCallToken(
    {
      method: 'POST',
      headers: {
        authorization: 'Bearer firebase-id-token',
        origin: 'https://dev-belongonthespectrum.web.app',
      },
      body: { callId: 'monthly' },
    },
    res,
    {
      verifyIdToken: async () => ({ uid: 'member1' }),
      apiKey: () => apiKey,
      apiSecret: () => secret,
      appId: () => '',
      nowSeconds: () => 1_700_000_000,
    },
  );
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.apiKey, apiKey);
  assert.equal(res.body.userId, 'member1');
  assert.equal(res.body.callId, 'monthly');
  assert.equal(Object.hasOwn(res.body, 'apiSecret'), false);
  assert.equal(JSON.stringify(res.body).includes(secret), false);
  assert.equal(verifyStreamUserToken(res.body.token, secret).user_id, 'member1');
  assert.equal(res.headers['access-control-allow-origin'], 'https://dev-belongonthespectrum.web.app');
});

test('missing auth, a bad call name, and missing credentials do not mint', async () => {
  const denied = mockResponse();
  await handleMintStreamCallToken(
    { method: 'POST', headers: {}, body: { callId: 'monthly' } },
    denied,
    {
      verifyIdToken: async () => {
        throw new Error('should not run');
      },
      apiKey: () => apiKey,
      apiSecret: () => secret,
      nowSeconds: () => 1,
    },
  );
  assert.equal(denied.statusCode, 401);

  const badName = mockResponse();
  await handleMintStreamCallToken(
    {
      method: 'POST',
      headers: { authorization: 'Bearer firebase-id-token' },
      body: { callId: 'no' },
    },
    badName,
    {
      verifyIdToken: async () => ({ uid: 'member1' }),
      apiKey: () => apiKey,
      apiSecret: () => secret,
      nowSeconds: () => 1,
    },
  );
  assert.equal(badName.statusCode, 400);

  const unconfigured = mockResponse();
  await handleMintStreamCallToken(
    {
      method: 'POST',
      headers: { authorization: 'Bearer firebase-id-token' },
      body: { callId: 'monthly' },
    },
    unconfigured,
    {
      verifyIdToken: async () => ({ uid: 'member1' }),
      apiKey: () => '',
      apiSecret: () => '',
      nowSeconds: () => 1,
    },
  );
  assert.equal(unconfigured.statusCode, 503);
  assert.equal(JSON.stringify(unconfigured.body).includes(secret), false);
});
