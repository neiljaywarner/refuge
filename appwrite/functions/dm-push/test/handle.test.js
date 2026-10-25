'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { handleDirectMessagePush, messageFromFirestoreDocument } = require('../src/handle');

const member = { sub: 'member-a', user_id: 'member-a' };

function deps(overrides) {
  const devices = new Map();
  const sent = [];
  return {
    sent,
    devices,
    verifyIdToken: async () => member,
    readMessage: async () => ({
      senderId: 'member-a',
      senderName: 'Fellow Member',
      content: 'Quiet hello from the fellowship.',
      recipientIds: ['member-b'],
    }),
    readDevice: async (uid) => devices.get(uid) || null,
    writeDevice: async (uid, row) => {
      devices.set(uid, row);
    },
    canSend: true,
    sendPush: async (payload) => {
      sent.push(payload);
    },
    ...overrides,
  };
}

test('register keeps a real token and drops a placeholder', async () => {
  const gate = deps();
  const saved = await handleDirectMessagePush(
    {
      action: 'register',
      idToken: 'token',
      enabled: true,
      schedule: 'twiceDaily',
      fcmToken: 'real-device-token',
    },
    gate,
  );
  assert.equal(saved.body.registered, true);

  const placeholder = await handleDirectMessagePush(
    {
      action: 'register',
      idToken: 'token',
      enabled: true,
      schedule: 'twiceDaily',
      fcmToken: 'fcm_token_calm_digest_alpha_preview',
    },
    gate,
  );
  assert.equal(placeholder.body.registered, false);
  assert.equal(gate.devices.get('member-a').fcmToken, '');
});

test('send uses the stored message, not a body supplied by the caller', async () => {
  const gate = deps();
  gate.devices.set('member-b', {
    enabled: true,
    schedule: 'twiceDaily',
    fcmToken: 'real-device-token',
  });
  const result = await handleDirectMessagePush(
    {
      action: 'send',
      idToken: 'token',
      messageId: 'dm-1',
      content: 'this text must be ignored',
    },
    gate,
  );
  assert.equal(result.body.sent, 1);
  assert.equal(
    gate.sent[0].body,
    'Fellow Member sent you a direct message: "Quiet hello from the fellowship."',
  );
  assert.equal(gate.sent[0].android.notification.channel_id, 'direct_messages');
  assert.equal(gate.sent[0].android.priority, 'HIGH');
});

test('an opted-out recipient is skipped', async () => {
  const gate = deps();
  gate.devices.set('member-b', {
    enabled: false,
    schedule: 'twiceDaily',
    fcmToken: 'real-device-token',
  });
  const result = await handleDirectMessagePush(
    { action: 'send', idToken: 'token', messageId: 'dm-1' },
    gate,
  );
  assert.equal(result.body.sent, 0);
  assert.equal(result.body.skipped, 1);
  assert.equal(gate.sent.length, 0);
});

test('someone who did not write the message cannot send', async () => {
  const gate = deps({
    readMessage: async () => ({
      senderId: 'someone-else',
      senderName: 'Fellow Member',
      content: 'Quiet hello from the fellowship.',
      recipientIds: ['member-b'],
    }),
  });
  const result = await handleDirectMessagePush(
    { action: 'send', idToken: 'token', messageId: 'dm-1' },
    gate,
  );
  assert.equal(result.status, 403);
});

test('without a push credential the function does not pretend it sent', async () => {
  const gate = deps({ canSend: false });
  gate.devices.set('member-b', {
    enabled: true,
    schedule: 'twiceDaily',
    fcmToken: 'real-device-token',
  });
  const result = await handleDirectMessagePush(
    { action: 'send', idToken: 'token', messageId: 'dm-1' },
    gate,
  );
  assert.equal(result.body.sent, 0);
  assert.equal(result.body.reason, 'push credential is not configured');
});

test('a Firestore document becomes the message the card quotes', () => {
  const message = messageFromFirestoreDocument({
    fields: {
      senderId: { stringValue: 'member-a' },
      senderName: { stringValue: 'Fellow Member' },
      content: { stringValue: 'Quiet hello from the fellowship.' },
      recipientIds: { arrayValue: { values: [{ stringValue: 'member-b' }] } },
    },
  });
  assert.deepEqual(message.recipientIds, ['member-b']);
  assert.equal(message.content, 'Quiet hello from the fellowship.');
});
