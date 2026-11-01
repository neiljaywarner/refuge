'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  shouldSendDirectMessageEmail,
  directMessageEmailSubject,
  directMessageEmailText,
  isStoredDirectMessage,
  isSampleRecipient,
} = require('../src/decide');

const address = 'member@belongonthespectrum.com';
const body = 'Quiet hello from the fellowship.';

test('off and muted do not send', () => {
  assert.equal(
    shouldSendDirectMessageEmail({ enabled: false, schedule: 'twiceDaily' }, address),
    false,
  );
  assert.equal(shouldSendDirectMessageEmail({ enabled: true, schedule: 'muted' }, address), false);
  assert.equal(shouldSendDirectMessageEmail(null, address), false);
});

test('an opted-in member with an address does send', () => {
  assert.equal(
    shouldSendDirectMessageEmail({ enabled: true, schedule: 'twiceDaily' }, address),
    true,
  );
  assert.equal(
    shouldSendDirectMessageEmail({ enabled: true, schedule: 'immediateGentle' }, address),
    true,
  );
});

test('a missing address does not send', () => {
  assert.equal(shouldSendDirectMessageEmail({ enabled: true, schedule: 'twiceDaily' }, ''), false);
  assert.equal(
    shouldSendDirectMessageEmail({ enabled: true, schedule: 'twiceDaily' }, 'not-an-address'),
    false,
  );
});

test('the subject names the sender and leaves out the body and the address', () => {
  const subject = directMessageEmailSubject('Fellow Member', body);
  assert.equal(subject, 'Fellow Member — a message is waiting');
  assert.equal(subject.includes(body), false);
  assert.equal(subject.includes('@'), false);
  assert.equal(subject.includes(address), false);
});

test('an address-shaped name and a name that repeats the message stay generic', () => {
  assert.equal(
    directMessageEmailSubject(address, body),
    'Fellow Member — a message is waiting',
  );
  assert.equal(
    directMessageEmailSubject(body, body),
    'Fellow Member — a message is waiting',
  );
  assert.equal(directMessageEmailSubject('', ''), 'Fellow Member — a message is waiting');
});

test('the text names the sender and does not quote the message', () => {
  const text = directMessageEmailText('Fellow Member', body);
  assert.equal(text, 'Fellow Member sent you a message in Belong. Open the app when you are ready.');
  assert.equal(text.includes(body), false);
  assert.equal(text.includes('@'), false);
});

test('sample and local threads are not stored documents', () => {
  assert.equal(
    isStoredDirectMessage({
      senderId: 'member-a',
      threadId: 'member-a_member-b',
      recipientIds: ['member-b'],
    }),
    true,
  );
  assert.equal(
    isStoredDirectMessage({
      senderId: 'local-sender',
      threadId: 'thread-local-1',
      recipientIds: ['sample-Ada'],
    }),
    false,
  );
  assert.equal(
    isStoredDirectMessage({
      senderId: 'member-a',
      threadId: 'thread-local-1',
      recipientIds: ['member-b'],
    }),
    false,
  );
  assert.equal(isSampleRecipient('sample-Ada'), true);
  assert.equal(isSampleRecipient('member-b'), false);
});
