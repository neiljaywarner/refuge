'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { verifyStreamUserToken } = require('../src/stream_token');
const { handleMintStreamCallToken } = require('../src/stream_call');
const {
  GUEST_CAP,
  GUEST_TOKEN_TTL_SECONDS,
  INVITE_TTL_SECONDS,
  JOIN_MAX_ATTEMPTS,
  actorMayModerate,
  sanitizeGuestDisplayName,
  guestCallCid,
} = require('../src/stream_guest');
const { MemoryInviteStore } = require('../src/stream_invite_store');
const {
  prepareGuestOnCall,
  acceptedStreamCallRole,
  STREAM_CALL_MEMBER_ROLE,
} = require('../src/stream_video_api');

const secret = 'unit-test-stream-secret';
const apiKey = 'unit-test-stream-key';
const origin = 'https://dev-belongonthespectrum.web.app';

function token(char) {
  return char.repeat(43);
}

function guestId(n) {
  return `g${n.toString(16).padStart(32, '0')}`;
}

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

function harness(overrides = {}) {
  const store = overrides.store || new MemoryInviteStore();
  const prepared = [];
  let guestCounter = 0;
  const state = { now: overrides.now || 1_700_000_000, secretReads: 0 };
  const deps = {
    verifyIdToken: overrides.verifyIdToken || (async () => ({ uid: 'member1' })),
    apiKey: () => apiKey,
    apiSecret: () => {
      state.secretReads += 1;
      return secret;
    },
    appId: () => '',
    nowSeconds: () => state.now,
    store,
    prepareGuestCall: overrides.prepareGuestCall || (async (input) => {
      prepared.push(input);
      return { ok: true };
    }),
    randomInviteToken: overrides.randomInviteToken || (() => token('a')),
    randomGuestId: () => {
      guestCounter += 1;
      return guestId(guestCounter);
    },
  };
  return { store, prepared, state, deps };
}

async function post(deps, body, headers = {}) {
  const res = mockResponse();
  await handleMintStreamCallToken(
    {
      method: 'POST',
      headers: { origin, ...headers },
      body,
    },
    res,
    deps,
  );
  return res;
}

async function createInvite(env, callId = 'monthly', invite = token('a')) {
  env.deps.randomInviteToken = () => invite;
  const res = await post(
    env.deps,
    { action: 'createInvite', callId },
    { authorization: 'Bearer firebase-id-token' },
  );
  assert.equal(res.statusCode, 200, JSON.stringify(res.body));
  return res.body;
}

test('guest display names are trimmed and obvious emails or links are refused', () => {
  assert.equal(sanitizeGuestDisplayName('  Alex   R  '), 'Alex R');
  assert.equal(sanitizeGuestDisplayName(''), null);
  assert.equal(sanitizeGuestDisplayName('   '), null);
  assert.equal(sanitizeGuestDisplayName('a'.repeat(41)), null);
  assert.equal(sanitizeGuestDisplayName('Alex\nR'), null);
  assert.equal(sanitizeGuestDisplayName('Alex\u0007'), null);
  assert.equal(sanitizeGuestDisplayName('member@belongonthespectrum.com'), null);
  assert.equal(sanitizeGuestDisplayName('see https://example.com'), null);
  assert.equal(sanitizeGuestDisplayName('www.example.com'), null);
  assert.equal(sanitizeGuestDisplayName('Alex'), 'Alex');
});

test('a guest cannot moderate even if the request claims host', () => {
  assert.equal(actorMayModerate({ actor: 'guest', createdByMe: true, roles: ['admin', 'host'] }), false);
  assert.equal(actorMayModerate({ actor: 'guest', createdByMe: false, roles: ['call-member'] }), false);
  assert.equal(actorMayModerate({ actor: 'member', createdByMe: true, roles: [] }), true);
  assert.equal(actorMayModerate({ actor: 'member', createdByMe: false, roles: ['host'] }), true);
  assert.equal(actorMayModerate({ actor: 'member', createdByMe: false, roles: ['Admin'] }), true);
  assert.equal(actorMayModerate({ actor: 'member', createdByMe: false, roles: ['user'] }), false);
  assert.equal(actorMayModerate({ actor: 'member', createdByMe: false, roles: ['moderator'] }), false);
  assert.equal(actorMayModerate({ actor: 'member', createdByMe: false, roles: ['call-member'] }), false);
  assert.equal(actorMayModerate({ actor: 'member', createdByMe: false, roles: ['call_member'] }), false);
});

test('creating an invite returns the token once and does not store it', async () => {
  const env = harness();
  const lines = [];
  const original = console.info;
  console.info = (line) => lines.push(String(line));
  try {
    const created = await createInvite(env);
    assert.equal(created.inviteToken, token('a'));
    assert.equal(created.callId, 'monthly');
    assert.equal(created.guestLimit, GUEST_CAP);
    assert.equal(created.expiresAt, env.state.now + INVITE_TTL_SECONDS);
    assert.equal(env.store.serialized().includes(token('a')), false);
    assert.equal(JSON.stringify(created).includes(secret), false);
    assert.equal(lines.join('\n').includes(token('a')), false);
    assert.equal(lines.join('\n').includes(secret), false);
  } finally {
    console.info = original;
  }
});

test('a guest join mints a call-scoped token and ignores a host claim', async () => {
  const env = harness();
  const created = await createInvite(env);
  const lines = [];
  const original = console.info;
  console.info = (line) => lines.push(String(line));
  let joined;
  try {
    joined = await post(env.deps, {
      action: 'joinGuest',
      inviteToken: created.inviteToken,
      displayName: '  Alex  ',
      callId: 'monthly',
      role: 'admin',
      createdByMe: true,
    });
  } finally {
    console.info = original;
  }
  assert.equal(joined.statusCode, 200, JSON.stringify(joined.body));
  assert.equal(joined.body.actor, 'guest');
  assert.equal(joined.body.callRole, 'call-member');
  assert.equal(joined.body.canModerate, false);
  assert.equal(joined.body.displayName, 'Alex');
  assert.equal(joined.body.userId, guestId(1));
  assert.equal(Object.hasOwn(joined.body, 'apiSecret'), false);
  assert.equal(JSON.stringify(joined.body).includes(secret), false);
  const payload = verifyStreamUserToken(joined.body.token, secret);
  assert.equal(payload.user_id, guestId(1));
  assert.equal(payload.role, 'call-member');
  assert.deepEqual(payload.call_cids, [guestCallCid('monthly')]);
  assert.equal(payload.exp, env.state.now + GUEST_TOKEN_TTL_SECONDS);
  assert.equal(joined.body.token.includes(secret), false);
  assert.equal(env.prepared.length, 1);
  assert.equal(env.prepared[0].hostUserId, 'member1');
  assert.equal(env.prepared[0].guestUserId, guestId(1));
  assert.equal(env.prepared[0].displayName, 'Alex');
  assert.equal(lines.join('\n').includes(created.inviteToken), false);
  assert.equal(lines.join('\n').includes(secret), false);
  assert.equal(lines.join('\n').includes('Alex'), false);
});

test('expired, revoked, and over-cap joins do not mint', async () => {
  const env = harness();
  const created = await createInvite(env);

  env.state.now += INVITE_TTL_SECONDS;
  const expired = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: created.inviteToken,
    displayName: 'Alex',
    callId: 'monthly',
  });
  assert.equal(expired.statusCode, 410);
  assert.equal(expired.body.code, 'expired');
  assert.equal(env.prepared.length, 0);
  assert.equal(JSON.stringify(expired.body).includes(secret), false);

  env.state.now = 1_700_000_000;
  const revokedRes = await post(
    env.deps,
    { action: 'revokeInvite', inviteToken: created.inviteToken },
    { authorization: 'Bearer firebase-id-token' },
  );
  assert.equal(revokedRes.statusCode, 200);
  const revoked = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: created.inviteToken,
    displayName: 'Alex',
    callId: 'monthly',
  });
  assert.equal(revoked.statusCode, 410);
  assert.equal(revoked.body.code, 'revoked');
  assert.equal(env.prepared.length, 0);
});

test('the guest cap is concurrent across invites and frees on release or expiry', async () => {
  const env = harness();
  const first = await createInvite(env, 'monthly', token('a'));
  env.deps.randomInviteToken = () => token('b');
  const second = await post(
    env.deps,
    { action: 'createInvite', callId: 'monthly' },
    { authorization: 'Bearer firebase-id-token' },
  );
  assert.equal(second.statusCode, 200);

  const ids = [];
  for (let i = 0; i < GUEST_CAP; i += 1) {
    const res = await post(env.deps, {
      action: 'joinGuest',
      inviteToken: first.inviteToken,
      displayName: `Guest ${i + 1}`,
      callId: 'monthly',
    });
    assert.equal(res.statusCode, 200, JSON.stringify(res.body));
    ids.push(res.body.userId);
  }

  const blocked = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: second.body.inviteToken,
    displayName: 'Late Guest',
    callId: 'monthly',
  });
  assert.equal(blocked.statusCode, 409);
  assert.equal(blocked.body.code, 'cap');
  assert.equal(blocked.body.token, undefined);

  const refreshed = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: first.inviteToken,
    displayName: 'Guest 1',
    callId: 'monthly',
    guestUserId: ids[0],
  });
  assert.equal(refreshed.statusCode, 200);
  assert.equal(refreshed.body.userId, ids[0]);

  const stillBlocked = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: second.body.inviteToken,
    displayName: 'Late Guest',
    callId: 'monthly',
  });
  assert.equal(stillBlocked.statusCode, 409);

  const released = await post(env.deps, {
    action: 'releaseGuest',
    inviteToken: first.inviteToken,
    guestUserId: ids[1],
  });
  assert.equal(released.statusCode, 200);
  assert.equal(released.body.released, true);

  const afterRelease = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: second.body.inviteToken,
    displayName: 'Late Guest',
    callId: 'monthly',
  });
  assert.equal(afterRelease.statusCode, 200);

  const replacement = afterRelease.body.userId;
  env.state.now += GUEST_TOKEN_TTL_SECONDS;
  const afterExpiry = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: first.inviteToken,
    displayName: 'After Expiry',
    callId: 'monthly',
  });
  assert.equal(afterExpiry.statusCode, 200);
  assert.notEqual(afterExpiry.body.userId, replacement);
});

test('bad names, the wrong call, and repeated attempts do not mint', async () => {
  const env = harness();
  const created = await createInvite(env);
  const names = [
    '',
    'member@belongonthespectrum.com',
    'https://example.com/join',
    'www.example.com',
    `line\nbreak`,
    'x'.repeat(41),
  ];
  for (const displayName of names) {
    const res = await post(env.deps, {
      action: 'joinGuest',
      inviteToken: created.inviteToken,
      displayName,
      callId: 'monthly',
    });
    assert.equal(res.statusCode, 400, displayName);
    assert.equal(res.body.code, 'name');
    assert.equal(JSON.stringify(res.body).includes(secret), false);
  }
  assert.equal(env.prepared.length, 0);

  const mismatch = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: created.inviteToken,
    displayName: 'Alex',
    callId: 'other-room',
  });
  assert.equal(mismatch.statusCode, 403);
  assert.equal(mismatch.body.code, 'mismatch');

  const unknown = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: token('z'),
    displayName: 'Alex',
    callId: 'monthly',
  });
  assert.equal(unknown.statusCode, 404);
  assert.equal(unknown.body.code, 'not-found');

  const inviteHash = require('node:crypto')
    .createHash('sha256')
    .update(created.inviteToken, 'utf8')
    .digest('hex');
  while ((await env.store.getInvite(inviteHash)).attemptCount < JOIN_MAX_ATTEMPTS) {
    const res = await post(env.deps, {
      action: 'joinGuest',
      inviteToken: created.inviteToken,
      displayName: 'nope@example.com',
      callId: 'monthly',
    });
    assert.equal(res.statusCode, 400);
  }
  const limited = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: created.inviteToken,
    displayName: 'Alex',
    callId: 'monthly',
  });
  assert.equal(limited.statusCode, 429);
  assert.equal(limited.body.code, 'rate');
  assert.equal(env.prepared.length, 0);
  assert.equal(JSON.stringify(limited.body).includes(created.inviteToken), false);
});

test('host actions and unsigned invite changes are refused before the secret is used', async () => {
  const env = harness();
  env.deps.apiSecret = () => {
    throw new Error('secret should stay unread');
  };
  const endCall = await post(
    env.deps,
    { action: 'endCall', callId: 'monthly', role: 'admin' },
    { authorization: 'Bearer firebase-id-token' },
  );
  assert.equal(endCall.statusCode, 403);
  assert.equal(endCall.body.code, 'forbidden');

  const remove = await post(env.deps, {
    action: 'removeParticipant',
    inviteToken: token('a'),
    userId: 'member1',
  });
  assert.equal(remove.statusCode, 403);
  assert.equal(remove.body.code, 'forbidden');
  assert.equal(JSON.stringify(endCall.body).includes(secret), false);

  env.deps.apiSecret = () => secret;
  const unsigned = await post(env.deps, { action: 'createInvite', callId: 'monthly' });
  assert.equal(unsigned.statusCode, 401);
  assert.equal(env.store.invites.size, 0);

  const created = await createInvite(env);
  env.deps.verifyIdToken = async (bearer) => {
    if (bearer === 'someone-else') return { uid: 'member2' };
    return { uid: 'member1' };
  };
  const notCreator = await post(
    env.deps,
    { action: 'revokeInvite', inviteToken: created.inviteToken },
    { authorization: 'Bearer someone-else' },
  );
  assert.equal(notCreator.statusCode, 403);
  assert.equal(notCreator.body.code, 'forbidden');
  const invite = await env.store.getInvite(
    require('node:crypto').createHash('sha256').update(created.inviteToken, 'utf8').digest('hex'),
  );
  assert.equal(invite.revokedAt, null);
});

test('a foreign origin cannot join or create an invite', async () => {
  const env = harness();
  env.deps.store = {
    getInvite() {
      throw new Error('store should not be read');
    },
    putInvite() {
      throw new Error('store should not be written');
    },
  };
  const res = await post(
    env.deps,
    { action: 'joinGuest', inviteToken: token('a'), displayName: 'Alex', callId: 'monthly' },
    { origin: 'https://evil.example' },
  );
  assert.equal(res.statusCode, 403);
  assert.equal(res.headers['access-control-allow-origin'], undefined);
  assert.equal(JSON.stringify(res.body).includes(token('a')), false);
});

test('preparing the room keeps the member as host and the guest as a call member', async () => {
  const calls = [];
  const fetchImpl = async (url, options) => {
    calls.push({ url, options });
    const path = new URL(url).pathname;
    if (options.method === 'GET') {
      return { ok: false, status: 404, text: async () => `{"secret":"${secret}"}` };
    }
    return { ok: true, status: 201, text: async () => '' };
  };
  const result = await prepareGuestOnCall({
    fetchImpl,
    apiKey,
    apiSecret: secret,
    callId: 'monthly',
    hostUserId: 'member1',
    guestUserId: guestId(1),
    displayName: 'Alex',
    nowSeconds: 1_700_000_000,
  });
  assert.equal(result.ok, true);
  const writes = calls.filter((call) => call.options.body);
  assert.equal(writes.length, 3);
  const bodies = writes.map((call) => JSON.parse(call.options.body));
  assert.equal(bodies[0].users.member1.role, 'user');
  assert.equal(bodies[0].users[guestId(1)].role, 'user');
  assert.equal(bodies[0].users[guestId(1)].name, 'Alex');
  assert.equal(bodies[1].data.created_by_id, 'member1');
  assert.deepEqual(bodies[1].data.members, [{ user_id: 'member1', role: 'host' }]);
  assert.equal(acceptedStreamCallRole('call_member'), true);
  assert.equal(acceptedStreamCallRole('user'), true);
  assert.equal(acceptedStreamCallRole('host'), true);
  assert.equal(acceptedStreamCallRole('call-member'), false);
  assert.equal(STREAM_CALL_MEMBER_ROLE, 'call_member');
  const guestMember = bodies[2].update_members.find((member) => member.user_id === guestId(1));
  assert.equal(guestMember.role, 'call_member');
  assert.equal(acceptedStreamCallRole(guestMember.role), true);
  assert.equal(JSON.stringify(bodies[2]).includes('call-member'), false);
  assert.deepEqual(bodies[2].update_members, [
    { user_id: 'member1', role: 'host' },
    { user_id: guestId(1), role: 'call_member' },
  ]);
  for (const call of calls) {
    assert.equal(call.url.includes(secret), false);
    assert.equal(JSON.stringify(call.options).includes(secret), false);
    const header = call.options.headers.Authorization;
    const payload = verifyStreamUserToken(header, secret);
    assert.equal(payload.server, true);
    assert.equal(payload.user_id, undefined);
    assert.equal(payload.role, undefined);
  }
  const joined = calls.map((call) => `${call.options.method} ${call.url}`).join('\n');
  assert.equal(joined.includes('/api/v2/users?'), true);
  assert.equal(joined.includes('/video/call/default/monthly'), true);
  assert.equal(joined.includes('/video/call/default/monthly/members'), true);
});

function seatCount(store, callId) {
  const byCall = store.sessions.get(callId);
  return byCall ? byCall.size : 0;
}

test('a thrown room setup releases the new seat and keeps a refreshed one', async () => {
  const held = harness();
  const created = await createInvite(held);
  const joined = await post(held.deps, {
    action: 'joinGuest',
    inviteToken: created.inviteToken,
    displayName: 'Alex',
    callId: 'monthly',
  });
  assert.equal(joined.statusCode, 200, JSON.stringify(joined.body));
  const userId = joined.body.userId;
  assert.equal(seatCount(held.store, 'monthly'), 1);

  const refresh = await post(
    {
      ...held.deps,
      prepareGuestCall: async () => {
        throw new Error('unit-test-stream-secret');
      },
    },
    {
      action: 'joinGuest',
      inviteToken: created.inviteToken,
      displayName: 'Alex',
      callId: 'monthly',
      guestUserId: userId,
    },
  );
  assert.equal(refresh.statusCode, 503);
  assert.equal(refresh.body.code, 'room');
  assert.equal(refresh.body.token, undefined);
  assert.equal(JSON.stringify(refresh.body).includes('unit-test-stream-secret'), false);
  assert.equal(seatCount(held.store, 'monthly'), 1);
  assert.equal(held.store.sessions.get('monthly').has(userId), true);

  const thrown = harness({
    prepareGuestCall: async () => {
      throw new Error('unit-test-stream-secret');
    },
  });
  let releases = 0;
  const originalRelease = thrown.store.releaseGuest.bind(thrown.store);
  thrown.store.releaseGuest = async (input) => {
    releases += 1;
    return originalRelease(input);
  };
  const invite = await createInvite(thrown);
  for (let i = 0; i < GUEST_CAP; i += 1) {
    const failed = await post(thrown.deps, {
      action: 'joinGuest',
      inviteToken: invite.inviteToken,
      displayName: 'Alex',
      callId: 'monthly',
    });
    assert.equal(failed.statusCode, 503);
    assert.equal(failed.body.code, 'room');
    assert.equal(failed.body.token, undefined);
    assert.equal(JSON.stringify(failed.body).includes('unit-test-stream-secret'), false);
  }
  assert.equal(releases, GUEST_CAP);
  assert.equal(seatCount(thrown.store, 'monthly'), 0);

  const recovered = await post(
    {
      ...thrown.deps,
      prepareGuestCall: async () => ({ ok: true }),
    },
    {
      action: 'joinGuest',
      inviteToken: invite.inviteToken,
      displayName: 'Alex',
      callId: 'monthly',
    },
  );
  assert.equal(recovered.statusCode, 200, JSON.stringify(recovered.body));
  assert.equal(seatCount(thrown.store, 'monthly'), 1);
});

test('a failed room setup does not hold a guest seat', async () => {
  const env = harness({
    prepareGuestCall: async () => ({ ok: false, status: 500 }),
  });
  const created = await createInvite(env);
  const failed = await post(env.deps, {
    action: 'joinGuest',
    inviteToken: created.inviteToken,
    displayName: 'Alex',
    callId: 'monthly',
  });
  assert.equal(failed.statusCode, 503);
  assert.equal(failed.body.code, 'room');
  assert.equal(failed.body.token, undefined);
  const retry = await post(
    {
      ...env.deps,
      prepareGuestCall: async () => ({ ok: true }),
    },
    {
      action: 'joinGuest',
      inviteToken: created.inviteToken,
      displayName: 'Alex',
      callId: 'monthly',
    },
  );
  assert.equal(retry.statusCode, 200);
});
