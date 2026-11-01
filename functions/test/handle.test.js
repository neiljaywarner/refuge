'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { handleDirectMessageCreated } = require('../src/handle');

const address = 'member@belongonthespectrum.com';
const body = 'Quiet hello from the fellowship.';

function storedMessage(overrides) {
  return {
    threadId: 'member-a_member-b',
    senderId: 'member-a',
    senderName: 'Fellow Member',
    recipientIds: ['member-b'],
    content: body,
    subject: 'Hello',
    email: address,
    ...overrides,
  };
}

function deps(overrides) {
  const sent = [];
  const lookups = [];
  return {
    sent,
    lookups,
    readPreferences: async () => ({ enabled: true, schedule: 'twiceDaily' }),
    readEmail: async (uid) => {
      lookups.push(uid);
      return address;
    },
    canSend: true,
    sendEmail: async (payload) => {
      sent.push(payload);
    },
    ...overrides,
  };
}

test('an opted-in recipient gets a calm subject and no message body', async () => {
  const gate = deps();
  const result = await handleDirectMessageCreated('dm-1', storedMessage(), gate);
  assert.equal(result.sent, 1);
  assert.equal(result.failed, 0);
  assert.equal(gate.sent[0].to, address);
  assert.equal(gate.sent[0].subject, 'Fellow Member — a message is waiting');
  assert.equal(gate.sent[0].subject.includes(body), false);
  assert.equal(gate.sent[0].subject.includes('@'), false);
  assert.equal(gate.sent[0].text.includes(body), false);
  assert.equal(gate.sent[0].text.includes(address), false);
});

test('a document field named email is not the subject or the recipient', async () => {
  const gate = deps();
  await handleDirectMessageCreated(
    'dm-1',
    storedMessage({ email: 'someone@example.com', content: body }),
    gate,
  );
  assert.equal(gate.sent[0].to, address);
  assert.equal(gate.sent[0].subject.includes('someone@example.com'), false);
  assert.equal(gate.sent[0].subject.includes(body), false);
});

test('an opted-out recipient is skipped and their address is not looked up', async () => {
  const gate = deps({
    readPreferences: async () => ({ enabled: false, schedule: 'twiceDaily' }),
  });
  const result = await handleDirectMessageCreated('dm-1', storedMessage(), gate);
  assert.equal(result.sent, 0);
  assert.equal(result.skipped, 1);
  assert.equal(gate.lookups.length, 0);
  assert.equal(gate.sent.length, 0);
});

test('a muted schedule sends nothing', async () => {
  const gate = deps({
    readPreferences: async () => ({ enabled: true, schedule: 'muted' }),
  });
  const result = await handleDirectMessageCreated('dm-1', storedMessage(), gate);
  assert.equal(result.sent, 0);
  assert.equal(gate.lookups.length, 0);
});

test('a missing preference document does not send', async () => {
  const gate = deps({ readPreferences: async () => null });
  const result = await handleDirectMessageCreated('dm-1', storedMessage(), gate);
  assert.equal(result.sent, 0);
  assert.equal(result.skipped, 1);
  assert.equal(gate.lookups.length, 0);
});

test('sample and local threads send nothing', async () => {
  const gate = deps();
  const sample = await handleDirectMessageCreated(
    'dm-local',
    storedMessage({
      senderId: 'local-sender',
      threadId: 'thread-local-1',
      recipientIds: ['sample-Ada'],
    }),
    gate,
  );
  assert.equal(sample.reason, 'not a stored thread');
  assert.equal(gate.sent.length, 0);

  const mixed = await handleDirectMessageCreated(
    'dm-2',
    storedMessage({ recipientIds: ['sample-Ada', 'member-b'] }),
    gate,
  );
  assert.equal(mixed.sent, 1);
  assert.equal(mixed.skipped, 1);
});

test('without a mail secret the function does not pretend it sent', async () => {
  const gate = deps({ canSend: false });
  const result = await handleDirectMessageCreated('dm-1', storedMessage(), gate);
  assert.equal(result.sent, 0);
  assert.equal(result.reason, 'email credential is not configured');
  assert.equal(gate.sent.length, 0);
});

test('a refused send is counted and does not throw', async () => {
  const gate = deps({
    sendEmail: async () => {
      throw new Error('email was refused (503)');
    },
  });
  const result = await handleDirectMessageCreated('dm-1', storedMessage(), gate);
  assert.equal(result.sent, 0);
  assert.equal(result.failed, 1);
});

test('one opted-in recipient sends and one opted-out recipient does not', async () => {
  const gate = deps({
    readPreferences: async (uid) =>
      uid === 'member-b'
        ? { enabled: true, schedule: 'morningOnly' }
        : { enabled: false, schedule: 'twiceDaily' },
    readEmail: async () => 'tester@example.com',
  });
  const result = await handleDirectMessageCreated(
    'dm-3',
    storedMessage({ recipientIds: ['member-b', 'member-c'] }),
    gate,
  );
  assert.equal(result.sent, 1);
  assert.equal(result.skipped, 1);
  assert.equal(gate.sent[0].to, 'tester@example.com');
  assert.equal(gate.sent[0].subject.includes('tester@example.com'), false);
});
