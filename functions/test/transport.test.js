'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { parseEmailTransport } = require('../src/transport');

test('a complete https transport is accepted', () => {
  const parsed = parseEmailTransport(
    JSON.stringify({
      endpoint: 'https://api.resend.com/emails',
      apiKey: 'provider-key',
      from: 'Belong <notifications@belongonthespectrum.com>',
    }),
  );
  assert.equal(parsed.endpoint, 'https://api.resend.com/emails');
  assert.equal(parsed.from, 'Belong <notifications@belongonthespectrum.com>');
});

test('missing, http, and broken secrets do not send', () => {
  assert.equal(parseEmailTransport(''), null);
  assert.equal(parseEmailTransport('not-json'), null);
  assert.equal(
    parseEmailTransport(
      JSON.stringify({
        endpoint: 'http://api.example.com/emails',
        apiKey: 'provider-key',
        from: 'Belong <notifications@belongonthespectrum.com>',
      }),
    ),
    null,
  );
  assert.equal(
    parseEmailTransport(
      JSON.stringify({
        endpoint: 'https://api.resend.com/emails',
        apiKey: '',
        from: 'Belong <notifications@belongonthespectrum.com>',
      }),
    ),
    null,
  );
});
