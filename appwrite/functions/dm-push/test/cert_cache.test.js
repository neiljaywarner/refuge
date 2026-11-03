'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createCertCache, maxAgeSeconds, defaultMaxAgeMs } = require('../src/cert_cache');

function fakeResponse(certs, cacheControl) {
  return {
    ok: true,
    headers: { get: (name) => (name === 'cache-control' ? cacheControl : null) },
    json: async () => certs,
  };
}

function harness(responses) {
  let clock = 1_000_000;
  let calls = 0;
  const cache = createCertCache({
    now: () => clock,
    fetchImpl: async () => responses[Math.min(calls++, responses.length - 1)],
  });
  return {
    cache,
    calls: () => calls,
    advance: (ms) => {
      clock += ms;
    },
  };
}

test('maxAgeSeconds reads max-age and ignores junk', () => {
  assert.equal(maxAgeSeconds('public, max-age=19876, must-revalidate'), 19876);
  assert.equal(maxAgeSeconds('max-age=0'), null);
  assert.equal(maxAgeSeconds('no-cache'), null);
  assert.equal(maxAgeSeconds(undefined), null);
});

test('reuses cached certs until max-age passes', async () => {
  const h = harness([
    fakeResponse({ k1: 'pem-1' }, 'max-age=100'),
    fakeResponse({ k1: 'pem-1b' }, 'max-age=100'),
  ]);
  assert.equal(await h.cache.certificateFor('k1'), 'pem-1');
  h.advance(99_000);
  assert.equal(await h.cache.certificateFor('k1'), 'pem-1');
  assert.equal(h.calls(), 1);
  h.advance(2_000);
  assert.equal(await h.cache.certificateFor('k1'), 'pem-1b');
  assert.equal(h.calls(), 2);
});

test('refetches once when a rotated kid is missing', async () => {
  const h = harness([
    fakeResponse({ old: 'pem-old' }, 'max-age=20000'),
    fakeResponse({ old: 'pem-old', rotated: 'pem-new' }, 'max-age=20000'),
  ]);
  assert.equal(await h.cache.certificateFor('old'), 'pem-old');
  assert.equal(await h.cache.certificateFor('rotated'), 'pem-new');
  assert.equal(h.calls(), 2);
});

test('still unknown after one refresh throws and does not loop', async () => {
  const h = harness([fakeResponse({ a: 'pem-a' }, 'max-age=20000')]);
  await assert.rejects(h.cache.certificateFor('nope'), /unknown token key/);
  assert.equal(h.calls(), 2);
});

test('missing max-age falls back to the default lifetime', async () => {
  const h = harness([
    fakeResponse({ k: 'pem-1' }, null),
    fakeResponse({ k: 'pem-2' }, null),
  ]);
  assert.equal(await h.cache.certificateFor('k'), 'pem-1');
  h.advance(defaultMaxAgeMs - 1);
  assert.equal(await h.cache.certificateFor('k'), 'pem-1');
  h.advance(2);
  assert.equal(await h.cache.certificateFor('k'), 'pem-2');
});

test('a failed certificate download is reported', async () => {
  const cache = createCertCache({ fetchImpl: async () => ({ ok: false }) });
  await assert.rejects(cache.certificateFor('k'), /could not load token certificates/);
});
