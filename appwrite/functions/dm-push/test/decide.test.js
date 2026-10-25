'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  shouldSendDirectMessagePush,
  directMessagePushBody,
  directMessageAndroidConfig,
} = require('../src/decide');

test('off and muted do not send', () => {
  assert.equal(shouldSendDirectMessagePush({ enabled: false, schedule: 'twiceDaily', fcmToken: 'abc' }), false);
  assert.equal(shouldSendDirectMessagePush({ enabled: true, schedule: 'muted', fcmToken: 'abc' }), false);
  assert.equal(shouldSendDirectMessagePush(null), false);
});

test('placeholder tokens do not send', () => {
  assert.equal(
    shouldSendDirectMessagePush({
      enabled: true,
      schedule: 'immediateGentle',
      fcmToken: 'fcm_token_calm_digest_alpha_preview',
    }),
    false,
  );
});

test('opted-in real token sends', () => {
  assert.equal(
    shouldSendDirectMessagePush({
      enabled: true,
      schedule: 'twiceDaily',
      fcmToken: 'real-device-token',
    }),
    true,
  );
});

test('body names the sender and keeps a short snippet', () => {
  assert.equal(
    directMessagePushBody('Fellow Member', 'Quiet hello from the fellowship.'),
    'Fellow Member sent you a direct message: "Quiet hello from the fellowship."',
  );
  assert.equal(directMessagePushBody('', ''), 'Fellow Member sent you a direct message');
});

test('an ordinary opt-in uses the Direct messages channel with sound', () => {
  const android = directMessageAndroidConfig('twiceDaily');
  assert.equal(android.priority, 'HIGH');
  assert.equal(android.notification.channel_id, 'direct_messages');
  assert.equal(android.notification.default_sound, undefined);
});

test('Immediate Gentle Cards stays on the quiet channel', () => {
  const android = directMessageAndroidConfig('immediateGentle');
  assert.equal(android.notification.channel_id, 'calm_digest_channel_v2');
  assert.equal(android.notification.default_sound, false);
});
