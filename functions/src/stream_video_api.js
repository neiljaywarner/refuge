'use strict';

const { mintStreamServerToken } = require('./stream_token');
const { GUEST_CALL_ROLE, HOST_CALL_ROLE, CALL_TYPE } = require('./stream_guest');

const VIDEO_ORIGIN = 'https://video.stream-io-api.com';

/**
 * Makes sure the inviting member owns the call, then adds the guest as a
 * call member. The guest is not the call owner and is not a host.
 * Response bodies are discarded so a Stream error cannot be logged.
 */
async function prepareGuestOnCall({
  fetchImpl,
  apiKey,
  apiSecret,
  callId,
  hostUserId,
  guestUserId,
  displayName,
  nowSeconds,
}) {
  const fetchFn = fetchImpl || fetch;
  const server = mintStreamServerToken({ secret: apiSecret, nowSeconds });
  const headers = {
    Authorization: server.token,
    'stream-auth-type': 'jwt',
    'Content-Type': 'application/json',
  };
  const key = encodeURIComponent(apiKey);
  const usersUrl = `${VIDEO_ORIGIN}/api/v2/users?api_key=${key}`;
  const users = await fetchFn(usersUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      users: {
        [hostUserId]: { id: hostUserId, role: 'user' },
        [guestUserId]: { id: guestUserId, name: displayName, role: 'user' },
      },
    }),
  });
  await discard(users);
  if (!users.ok) return { ok: false, status: users.status };

  const callUrl = `${VIDEO_ORIGIN}/api/v2/video/call/${CALL_TYPE}/${encodeURIComponent(callId)}?api_key=${key}`;
  const existing = await fetchFn(callUrl, { method: 'GET', headers });
  await discard(existing);
  if (existing.status === 404) {
    const created = await fetchFn(callUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        data: {
          created_by_id: hostUserId,
          members: [{ user_id: hostUserId, role: HOST_CALL_ROLE }],
        },
      }),
    });
    await discard(created);
    if (!created.ok) return { ok: false, status: created.status };
  } else if (!existing.ok) {
    return { ok: false, status: existing.status };
  }

  const membersUrl = `${callUrl.split('?')[0]}/members?api_key=${key}`;
  const updated = await fetchFn(membersUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      update_members: [
        { user_id: hostUserId, role: HOST_CALL_ROLE },
        { user_id: guestUserId, role: GUEST_CALL_ROLE },
      ],
    }),
  });
  await discard(updated);
  if (!updated.ok) return { ok: false, status: updated.status };
  return { ok: true };
}

async function discard(response) {
  if (response && typeof response.text === 'function') {
    try {
      await response.text();
    } catch (_) {
      // The status is enough. The body is not logged.
    }
  }
}

module.exports = {
  prepareGuestOnCall,
};
