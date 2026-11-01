'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  handleDirectMessageMirror,
  messageFromFirestoreDocument,
  mirrorCreateBody,
  mirrorTable,
} = require('../src/handle');

const member = { sub: 'member-a', user_id: 'member-a' };
const bodyText = 'Quiet hello from the fellowship.';

function storedDocument() {
  return {
    fields: {
      threadId: { stringValue: 'member-a_member-b' },
      senderId: { stringValue: 'member-a' },
      senderName: { stringValue: 'Fellow Member' },
      recipientIds: { arrayValue: { values: [{ stringValue: 'member-b' }] } },
      recipientNames: { arrayValue: { values: [{ stringValue: 'Community Member' }] } },
      participantIds: {
        arrayValue: { values: [{ stringValue: 'member-a' }, { stringValue: 'member-b' }] },
      },
      subject: { stringValue: 'Hello' },
      content: { stringValue: bodyText },
      sentAt: { stringValue: '2026-11-01T18:00:00.000Z' },
    },
  };
}

function deps(overrides) {
  const written = [];
  return {
    written,
    verifyIdToken: async () => member,
    readMessage: async () => messageFromFirestoreDocument(storedDocument()),
    canWrite: true,
    writeMirror: async (messageId, row) => {
      written.push({ messageId, row });
    },
    ...overrides,
  };
}

test('the mirror copies the stored fields and ignores text from the caller', async () => {
  const gate = deps();
  const result = await handleDirectMessageMirror(
    {
      action: 'copy',
      idToken: 'token',
      messageId: 'dm-1',
      content: 'this text must be ignored',
      subject: 'also ignored',
    },
    gate,
  );
  assert.equal(result.status, 200);
  assert.equal(result.body.mirrored, true);
  assert.equal(gate.written.length, 1);
  assert.deepEqual(gate.written[0].row, {
    threadId: 'member-a_member-b',
    senderId: 'member-a',
    senderName: 'Fellow Member',
    recipientIds: ['member-b'],
    recipientNames: ['Community Member'],
    participantIds: ['member-a', 'member-b'],
    subject: 'Hello',
    content: bodyText,
    sentAt: '2026-11-01T18:00:00.000Z',
  });
  assert.equal(gate.written[0].row.content.includes('must be ignored'), false);
});

test('the create body keeps permissions empty and uses the direct message table', () => {
  const body = mirrorCreateBody('dm-1', { content: bodyText });
  assert.deepEqual(body.permissions, []);
  assert.equal(body.rowId, 'dm-1');
  assert.equal(mirrorTable.tableId, 'direct_messages');
  assert.equal(mirrorTable.databaseId, 'belong_community_db');
});

test('someone who did not write the message cannot copy it', async () => {
  const gate = deps({
    readMessage: async () =>
      messageFromFirestoreDocument({
        fields: {
          ...storedDocument().fields,
          senderId: { stringValue: 'someone-else' },
        },
      }),
  });
  const result = await handleDirectMessageMirror(
    { action: 'copy', idToken: 'token', messageId: 'dm-1' },
    gate,
  );
  assert.equal(result.status, 403);
  assert.equal(gate.written.length, 0);
});

test('a missing document and a local thread are not copied', async () => {
  const missing = await handleDirectMessageMirror(
    { action: 'copy', idToken: 'token', messageId: 'dm-1' },
    deps({ readMessage: async () => null }),
  );
  assert.equal(missing.body.mirrored, false);
  assert.equal(missing.body.reason, 'message not readable');

  const local = await handleDirectMessageMirror(
    { action: 'copy', idToken: 'token', messageId: 'dm-local' },
    deps({
      readMessage: async () => ({
        threadId: 'thread-local-1',
        senderId: 'local-sender',
        senderName: 'Fellow Member',
        recipientIds: ['sample-Ada'],
        recipientNames: ['Ada'],
        participantIds: ['local-sender', 'sample-Ada'],
        subject: '',
        content: bodyText,
        sentAt: '2026-11-01T18:00:00.000Z',
      }),
    }),
  );
  assert.equal(local.body.reason, 'not a stored thread');
  assert.equal(local.body.mirrored, false);
});

test('without an API key the function does not pretend it copied', async () => {
  const gate = deps({ canWrite: false });
  const result = await handleDirectMessageMirror(
    { action: 'copy', idToken: 'token', messageId: 'dm-1' },
    gate,
  );
  assert.equal(result.body.mirrored, false);
  assert.equal(result.body.reason, 'mirror credential is not configured');
  assert.equal(gate.written.length, 0);
});

test('a failed write is reported and does not echo the message', async () => {
  const gate = deps({
    writeMirror: async () => {
      throw new Error('could not store mirror (503)');
    },
  });
  const result = await handleDirectMessageMirror(
    { action: 'copy', idToken: 'token', messageId: 'dm-1' },
    gate,
  );
  assert.equal(result.status, 502);
  assert.equal(result.body.mirrored, false);
  assert.equal(result.body.reason, 'mirror write failed');
  assert.equal(JSON.stringify(result.body).includes(bodyText), false);
});

test('a bad token is unauthorized', async () => {
  const gate = deps({
    verifyIdToken: async () => {
      throw new Error('bad token signature');
    },
  });
  const result = await handleDirectMessageMirror(
    { action: 'copy', idToken: 'nope', messageId: 'dm-1' },
    gate,
  );
  assert.equal(result.status, 401);
  assert.equal(gate.written.length, 0);
});
