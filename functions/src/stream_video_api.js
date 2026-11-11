'use strict';

const { mintStreamServerToken } = require('./stream_token');
const { HOST_CALL_ROLE, CALL_TYPE } = require('./stream_guest');

const VIDEO_ORIGIN = 'https://video.stream-io-api.com';

/**
 * Role names Stream's video members API accepts.
 * A live check rejected `call-member` (HTTP 400) and accepted `call_member`.
 * `user` is an app-level user role, not a call membership role.
 */
const STREAM_CALL_MEMBER_ROLE = 'call_member';
const ACCEPTED_STREAM_CALL_ROLES = new Set(['user', 'moderator', 'host', 'admin', 'call_member']);

function acceptedStreamCallRole(role) {
  return ACCEPTED_STREAM_CALL_ROLES.has(role);
}

/**
 * True when [hostUserId] created this call or already has host or admin.
 * A missing owner fails closed so a member cannot take over someone else's room.
 * The returned role is the membership role already on the call, if any.
 */
function inviterCallAuthority(body, hostUserId) {
  if (!body || typeof body !== 'object') return { ok: false, role: '' };
  const call = body.call && typeof body.call === 'object' ? body.call : body;
  const createdBy = createdById(call.created_by);
  const role = membershipRole(body, hostUserId);
  if (createdBy === hostUserId || role === 'host' || role === 'admin') {
    return { ok: true, role };
  }
  return { ok: false, role: '' };
}

function createdById(created) {
  if (typeof created === 'string') return created;
  if (!created || typeof created !== 'object') return '';
  if (typeof created.id === 'string') return created.id;
  if (typeof created.user_id === 'string') return created.user_id;
  return '';
}

function membershipRole(body, userId) {
  const lists = [];
  if (Array.isArray(body.members)) lists.push(body.members);
  if (body.call && Array.isArray(body.call.members)) lists.push(body.call.members);
  for (const list of lists) {
    for (const member of list) {
      if (!member || typeof member !== 'object') continue;
      const id =
        member.user_id ||
        (member.user && typeof member.user === 'object' ? member.user.id : '');
      if (id !== userId) continue;
      return typeof member.role === 'string' ? member.role.toLowerCase() : '';
    }
  }
  return '';
}

/**
 * Members update that adds the guest and does not downgrade the inviter.
 * Host or admin stays as it is. A new room, or a creator with no membership
 * yet, is written as host.
 */
function guestMembershipUpdate({ hostUserId, guestUserId, existingRole }) {
  const update = [];
  if (existingRole !== 'host' && existingRole !== 'admin') {
    update.push({ user_id: hostUserId, role: HOST_CALL_ROLE });
  }
  update.push({ user_id: guestUserId, role: STREAM_CALL_MEMBER_ROLE });
  return update;
}

/**
 * Makes sure the inviting member may host, then adds the guest as a call member.
 * The guest is not the call owner and is not a host.
 * The inviter's app-level user role is not sent, so an admin is not rewritten
 * to `user`. Response bodies are not logged.
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
  const callUrl = `${VIDEO_ORIGIN}/api/v2/video/call/${CALL_TYPE}/${encodeURIComponent(callId)}?api_key=${key}`;
  const existing = await fetchFn(callUrl, { method: 'GET', headers });
  if (existing.status !== 404 && !existing.ok) {
    await readJson(existing);
    return { ok: false, status: existing.status };
  }

  let existingRole = '';
  let creating = existing.status === 404;
  if (creating) {
    await readJson(existing);
  } else {
    const body = await readJson(existing);
    const authority = inviterCallAuthority(body, hostUserId);
    if (!authority.ok) return { ok: false, status: 403 };
    existingRole = authority.role;
  }

  const usersUrl = `${VIDEO_ORIGIN}/api/v2/users?api_key=${key}`;
  const users = await fetchFn(usersUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      users: {
        // No role: creating a missing user defaults to `user`, and an
        // existing admin or custom role is left alone.
        [hostUserId]: { id: hostUserId },
        [guestUserId]: { id: guestUserId, name: displayName, role: 'user' },
      },
    }),
  });
  await readJson(users);
  if (!users.ok) return { ok: false, status: users.status };

  if (creating) {
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
    await readJson(created);
    if (!created.ok) return { ok: false, status: created.status };
  }

  if (!acceptedStreamCallRole(HOST_CALL_ROLE) || !acceptedStreamCallRole(STREAM_CALL_MEMBER_ROLE)) {
    return { ok: false, status: 400 };
  }
  const membersUrl = `${callUrl.split('?')[0]}/members?api_key=${key}`;
  const updated = await fetchFn(membersUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      update_members: guestMembershipUpdate({ hostUserId, guestUserId, existingRole }),
    }),
  });
  await readJson(updated);
  if (!updated.ok) return { ok: false, status: updated.status };
  return { ok: true };
}

async function readJson(response) {
  if (!response || typeof response.text !== 'function') return null;
  let text = '';
  try {
    text = await response.text();
  } catch (_) {
    return null;
  }
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch (_) {
    return null;
  }
}

module.exports = {
  prepareGuestOnCall,
  acceptedStreamCallRole,
  inviterCallAuthority,
  guestMembershipUpdate,
  STREAM_CALL_MEMBER_ROLE,
};
