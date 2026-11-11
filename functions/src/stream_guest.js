'use strict';

const crypto = require('node:crypto');

const { mintStreamCallScopedToken, verifyStreamUserToken } = require('./stream_token');
const { decideMember } = require('./stream_member');

/** About one day. The link can be revoked sooner. */
const INVITE_TTL_SECONDS = 24 * 60 * 60;

/**
 * Half an hour. A guest who is still in the call refreshes this.
 * A guest who leaves, or whose link was revoked, stops holding a seat
 * once this runs out (or as soon as the app releases the seat).
 */
const GUEST_TOKEN_TTL_SECONDS = 30 * 60;

/** Concurrent guests in one call, not a lifetime total. */
const GUEST_CAP = 10;

const JOIN_WINDOW_SECONDS = 10 * 60;
const JOIN_MAX_ATTEMPTS = 20;

/**
 * A seat is only reserved for a minute until Stream accepts the guest.
 * If preparation is killed at the function deadline, the seat opens again
 * with this window instead of the full half-hour pass.
 */
const GUEST_PENDING_TTL_SECONDS = 60;

/** Leaves time inside the 20s function limit to release a seat. */
const PREPARE_TIMEOUT_MS = 12 * 1000;

/** Unknown invite tokens, before the per-link counter and the invite read. */
const REQUEST_WINDOW_SECONDS = 10 * 60;
const REQUEST_MAX_ATTEMPTS = 60;

/**
 * App-facing label on the guest token and the join response.
 * Stream's members API does not accept this hyphenated string.
 * The membership written to Stream is [STREAM_CALL_MEMBER_ROLE].
 * `guest` is not a built-in call role. Host, admin, and moderator are not
 * assigned to invite joiners.
 */
const GUEST_CALL_ROLE = 'call-member';
const HOST_CALL_ROLE = 'host';
const CALL_TYPE = 'default';

const INVITE_TOKEN = /^[A-Za-z0-9_-]{43}$/;
const GUEST_USER_ID = /^g[a-f0-9]{32}$/;
const HOST_ROLES = new Set(['host', 'admin']);

function hashInviteToken(token) {
  return crypto.createHash('sha256').update(token, 'utf8').digest('hex');
}

function inviteTokenLooksValid(token) {
  return typeof token === 'string' && INVITE_TOKEN.test(token);
}

function guestUserIdLooksValid(userId) {
  return typeof userId === 'string' && GUEST_USER_ID.test(userId);
}

/** 32 bytes of base64url, same shape as an invite token. Not a Stream secret. */
function seatKeyLooksValid(seatKey) {
  return typeof seatKey === 'string' && INVITE_TOKEN.test(seatKey);
}

function hashSeatKey(seatKey) {
  return crypto.createHash('sha256').update(seatKey, 'utf8').digest('hex');
}

function requestBucket(req) {
  const ip = req && typeof req.ip === 'string' ? req.ip.trim() : '';
  return crypto.createHash('sha256').update(ip || 'unknown', 'utf8').digest('hex');
}

function settleWithin(work, ms) {
  return new Promise((resolve) => {
    let settled = false;
    const timer = setTimeout(() => {
      if (settled) return;
      settled = true;
      resolve({ ok: false, timedOut: true });
    }, ms);
    Promise.resolve()
      .then(work)
      .then((value) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        resolve(value);
      })
      .catch(() => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        resolve(null);
      });
  });
}

function guestCallCid(callId) {
  return `${CALL_TYPE}:${callId}`;
}

/**
 * Trim, cap the length, and reject control characters, email addresses,
 * and obvious web links. Returns the cleaned name or null.
 */
function sanitizeGuestDisplayName(raw) {
  if (typeof raw !== 'string') return null;
  // Control characters are rejected, including newlines. Ordinary spaces
  // can still be trimmed. They are not control characters.
  if (/[\u0000-\u001F\u007F]/.test(raw)) return null;
  if (/[\u202A-\u202E\u2066-\u2069]/.test(raw)) return null;
  const trimmed = raw.trim().replace(/ +/g, ' ');
  if (!trimmed || trimmed.length > 40) return null;
  if (trimmed.includes('@')) return null;
  if (/[a-z][a-z0-9+.-]*:\/\//i.test(trimmed) || /www\./i.test(trimmed)) return null;
  return trimmed;
}

function advanceJoinAttempt(record, nowSeconds, limits) {
  const windowSeconds = limits.windowSeconds;
  const maxAttempts = limits.maxAttempts;
  const start = typeof record.attemptWindowStart === 'number' ? record.attemptWindowStart : 0;
  const previous = typeof record.attemptCount === 'number' ? record.attemptCount : 0;
  const fresh = start === 0 || nowSeconds - start >= windowSeconds;
  const attemptWindowStart = fresh ? nowSeconds : start;
  const attemptCount = fresh ? 1 : previous + 1;
  return {
    attemptWindowStart,
    attemptCount,
    limited: attemptCount > maxAttempts,
  };
}

/**
 * A seat counts only while its token is still inside the expiry window.
 * Refreshing the same guest on the same invite does not take a second seat.
 */
function decideGuestClaim(sessions, input) {
  const active = sessions.filter((session) => session.expiresAt > input.nowSeconds);
  const sameId = active.find((session) => session.guestUserId === input.guestUserId);
  if (sameId && sameId.inviteHash !== input.inviteHash) {
    return { ok: false, reason: 'conflict' };
  }
  const mine = Boolean(sameId);
  if (!mine && active.length >= input.limit) {
    return { ok: false, reason: 'cap' };
  }
  return {
    ok: true,
    renewed: mine,
    guestUserId: input.guestUserId,
    expiresAt: input.nowSeconds + input.ttlSeconds,
  };
}

/**
 * Guests cannot moderate, even if the request claims they created the room
 * or names a host role. A signed-in member can when they created the room
 * or Stream gave them host or admin. Moderator is not enough.
 */
function actorMayModerate({ actor, createdByMe, roles }) {
  if (actor !== 'member') return false;
  if (createdByMe === true) return true;
  const list = Array.isArray(roles) ? roles : [];
  return list.some((role) => typeof role === 'string' && HOST_ROLES.has(role.toLowerCase()));
}

function jsonError(res, status, code, error) {
  res.status(status).json({ error, code });
}

function readSecrets(deps) {
  const apiKey = typeof deps.apiKey() === 'string' ? deps.apiKey().trim() : '';
  const fallback = deps.appId ? deps.appId() : '';
  const key = apiKey || (typeof fallback === 'string' ? fallback.trim() : '');
  const apiSecret = typeof deps.apiSecret() === 'string' ? deps.apiSecret().trim() : '';
  return { apiKey: key, apiSecret };
}

async function requireMember(req, res, deps) {
  const decision = await decideMember(req, deps);
  if (!decision.ok) {
    jsonError(res, decision.status, decision.code, decision.error);
    return null;
  }
  return decision.userId;
}

function logGuest(event, fields) {
  console.info(JSON.stringify({ event, ...fields }));
}

async function handleStreamGuestAction({ req, res, deps, action, body }) {
  if (action === 'createInvite') {
    await createInvite(req, res, deps, body);
    return;
  }
  if (action === 'revokeInvite') {
    await revokeInvite(req, res, deps, body);
    return;
  }
  if (action === 'revokeMyInvites') {
    await revokeMyInvites(req, res, deps, body);
    return;
  }
  if (action === 'joinGuest') {
    await joinGuest(req, res, deps, body);
    return;
  }
  if (action === 'releaseGuest') {
    await releaseGuest(req, res, deps, body);
    return;
  }
  jsonError(res, 400, 'forbidden', 'That call action is not available.');
}

async function createInvite(req, res, deps, body) {
  const userId = await requireMember(req, res, deps);
  if (!userId) return;
  const { normalizeCallId } = require('./stream_call');
  const callId = normalizeCallId(body.callId);
  if (!callId) {
    jsonError(res, 400, 'call', 'Choose a short call name using letters, numbers, and dashes.');
    return;
  }
  const secrets = readSecrets(deps);
  if (!secrets.apiKey || !secrets.apiSecret) {
    logGuest('createStreamGuestInvite', { ok: false, reason: 'not-configured', callId });
    jsonError(res, 503, 'unconfigured', 'Video calling is not configured on this preview.');
    return;
  }
  const store = deps.store;
  if (!store || typeof deps.randomInviteToken !== 'function') {
    jsonError(res, 503, 'unconfigured', 'Video calling is not configured on this preview.');
    return;
  }
  const now = deps.nowSeconds();
  const inviteToken = deps.randomInviteToken();
  if (!inviteTokenLooksValid(inviteToken)) {
    jsonError(res, 503, 'unconfigured', 'Video calling is not configured on this preview.');
    return;
  }
  const tokenHash = hashInviteToken(inviteToken);
  await store.putInvite({
    tokenHash,
    callId,
    createdBy: userId,
    createdAt: now,
    expiresAt: now + INVITE_TTL_SECONDS,
    revokedAt: null,
    attemptWindowStart: 0,
    attemptCount: 0,
  });
  logGuest('createStreamGuestInvite', { ok: true, callId });
  res.set('Cache-Control', 'no-store');
  res.status(200).json({
    inviteToken,
    callId,
    expiresAt: now + INVITE_TTL_SECONDS,
    guestLimit: GUEST_CAP,
  });
}

async function revokeInvite(req, res, deps, body) {
  const userId = await requireMember(req, res, deps);
  if (!userId) return;
  const inviteToken = body.inviteToken;
  if (!inviteTokenLooksValid(inviteToken) || !deps.store) {
    jsonError(res, 404, 'not-found', 'This invite link is not valid.');
    return;
  }
  const tokenHash = hashInviteToken(inviteToken);
  const invite = await deps.store.getInvite(tokenHash);
  if (!invite) {
    jsonError(res, 404, 'not-found', 'This invite link is not valid.');
    return;
  }
  if (invite.createdBy !== userId) {
    logGuest('revokeStreamGuestInvite', { ok: false, reason: 'not-creator' });
    jsonError(res, 403, 'forbidden', 'Only the member who created this link can revoke it.');
    return;
  }
  await deps.store.revokeInvite(tokenHash, deps.nowSeconds());
  logGuest('revokeStreamGuestInvite', { ok: true, callId: invite.callId });
  res.status(200).json({ revoked: true, callId: invite.callId });
}

async function revokeMyInvites(req, res, deps, body) {
  const userId = await requireMember(req, res, deps);
  if (!userId) return;
  const { normalizeCallId } = require('./stream_call');
  const callId = normalizeCallId(body.callId);
  if (!callId || !deps.store || typeof deps.store.revokeInvitesByCreator !== 'function') {
    jsonError(res, 400, 'call', 'Choose a short call name using letters, numbers, and dashes.');
    return;
  }
  const revoked = await deps.store.revokeInvitesByCreator({
    createdBy: userId,
    callId,
    revokedAt: deps.nowSeconds(),
  });
  logGuest('revokeStreamGuestInvites', { ok: true, callId, revoked });
  res.status(200).json({ revoked, callId });
}

async function noteGuestRequest(req, res, deps) {
  if (!deps.store || typeof deps.store.noteRequestAttempt !== 'function') {
    jsonError(res, 503, 'unconfigured', 'Video calling is not configured on this preview.');
    return false;
  }
  const attempt = await deps.store.noteRequestAttempt(requestBucket(req), deps.nowSeconds(), {
    windowSeconds: REQUEST_WINDOW_SECONDS,
    maxAttempts: REQUEST_MAX_ATTEMPTS,
  });
  if (attempt.limited) {
    logGuest('streamGuestRequest', { ok: false, reason: 'rate' });
    jsonError(res, 429, 'rate', 'Too many join attempts. Wait a few minutes and try the link again.');
    return false;
  }
  return true;
}

function seatMatches(existing, tokenHash, seatKey) {
  if (!existing || existing.inviteHash !== tokenHash) return false;
  if (!seatKeyLooksValid(seatKey) || typeof existing.sessionHash !== 'string') return false;
  const actual = Buffer.from(hashSeatKey(seatKey), 'hex');
  const wanted = Buffer.from(existing.sessionHash, 'hex');
  if (actual.length !== wanted.length) return false;
  return crypto.timingSafeEqual(actual, wanted);
}

async function joinGuest(req, res, deps, body) {
  if (!(await noteGuestRequest(req, res, deps))) return;
  const inviteToken = body.inviteToken;
  if (!inviteTokenLooksValid(inviteToken)) {
    jsonError(res, 404, 'not-found', 'This invite link is not valid.');
    return;
  }
  const tokenHash = hashInviteToken(inviteToken);
  const invite = await deps.store.getInvite(tokenHash);
  if (!invite || typeof invite.callId !== 'string') {
    jsonError(res, 404, 'not-found', 'This invite link is not valid.');
    return;
  }

  const now = deps.nowSeconds();
  const requestedCallId = typeof body.callId === 'string' ? body.callId.trim().toLowerCase() : '';
  const displayName = sanitizeGuestDisplayName(body.displayName);
  const live = !isRevoked(invite) && now < invite.expiresAt;
  const callOk = !requestedCallId || requestedCallId === invite.callId;
  const suppliedGuestId = body.guestUserId;
  const suppliedSeatKey = body.seatKey;
  const existing =
    live && callOk && displayName && guestUserIdLooksValid(suppliedGuestId)
      ? await deps.store.findSession({ callId: invite.callId, guestUserId: suppliedGuestId })
      : null;
  const reclaiming = seatMatches(existing, tokenHash, suppliedSeatKey);
  const activeSeat = Boolean(reclaiming && existing.expiresAt > now);

  if (!activeSeat) {
    const attempt = await deps.store.noteJoinAttempt(tokenHash, now, {
      windowSeconds: JOIN_WINDOW_SECONDS,
      maxAttempts: JOIN_MAX_ATTEMPTS,
    });
    if (attempt.limited) {
      logGuest('joinStreamGuest', { ok: false, reason: 'rate', callId: invite.callId });
      jsonError(res, 429, 'rate', 'Too many join attempts. Wait a few minutes and try the link again.');
      return;
    }
  }

  if (isRevoked(invite)) {
    logGuest('joinStreamGuest', { ok: false, reason: 'revoked', callId: invite.callId });
    jsonError(res, 410, 'revoked', 'This invite link has expired or was revoked.');
    return;
  }
  if (now >= invite.expiresAt) {
    logGuest('joinStreamGuest', { ok: false, reason: 'expired', callId: invite.callId });
    jsonError(res, 410, 'expired', 'This invite link has expired or was revoked.');
    return;
  }
  if (!callOk) {
    logGuest('joinStreamGuest', { ok: false, reason: 'mismatch', callId: invite.callId });
    jsonError(res, 403, 'mismatch', 'This invite link is for a different call.');
    return;
  }
  if (!displayName) {
    logGuest('joinStreamGuest', { ok: false, reason: 'name', callId: invite.callId });
    jsonError(res, 400, 'name', 'Use a short name. Leave out email addresses and web links.');
    return;
  }
  // The invite link is shared. It is not enough to refresh or replace a seat.
  if (guestUserIdLooksValid(suppliedGuestId) && !reclaiming) {
    logGuest('joinStreamGuest', { ok: false, reason: 'seat', callId: invite.callId });
    jsonError(res, 403, 'seat', 'This invite link is not valid for that seat. Open the link again.');
    return;
  }

  // A client may ask to join as a host. The request is ignored.
  const secrets = readSecrets(deps);
  if (!secrets.apiKey || !secrets.apiSecret || typeof deps.prepareGuestCall !== 'function') {
    logGuest('joinStreamGuest', { ok: false, reason: 'not-configured', callId: invite.callId });
    jsonError(res, 503, 'unconfigured', 'Video calling is not configured on this preview.');
    return;
  }
  if (typeof deps.randomGuestId !== 'function' || typeof deps.randomSeatKey !== 'function') {
    jsonError(res, 503, 'unconfigured', 'Video calling is not configured on this preview.');
    return;
  }

  let seatKey = null;
  let sessionHash = null;
  if (reclaiming) {
    sessionHash = existing.sessionHash;
  } else {
    seatKey = deps.randomSeatKey();
    if (!seatKeyLooksValid(seatKey)) {
      jsonError(res, 503, 'unconfigured', 'Video calling is not configured on this preview.');
      return;
    }
    sessionHash = hashSeatKey(seatKey);
  }

  const guestUserId = reclaiming ? suppliedGuestId : deps.randomGuestId();
  if (!guestUserIdLooksValid(guestUserId)) {
    jsonError(res, 503, 'unconfigured', 'Video calling is not configured on this preview.');
    return;
  }

  const claim = await deps.store.claimGuest({
    callId: invite.callId,
    guestUserId,
    inviteHash: tokenHash,
    sessionHash,
    nowSeconds: now,
    ttlSeconds: activeSeat ? GUEST_TOKEN_TTL_SECONDS : GUEST_PENDING_TTL_SECONDS,
    limit: GUEST_CAP,
  });
  if (!claim.ok) {
    logGuest('joinStreamGuest', { ok: false, reason: 'cap', callId: invite.callId });
    jsonError(res, 409, 'cap', 'This call already has 10 guests. Try again after someone leaves.');
    return;
  }

  const releaseClaim = () =>
    deps.store.releaseGuest({
      callId: invite.callId,
      guestUserId,
      inviteHash: tokenHash,
      sessionHash,
    });

  // A throw or a stall is the same as { ok: false }. A new seat is released.
  // An active refresh keeps the seat the guest already holds. The error text
  // is not returned: a Stream failure can echo a credential.
  const timeoutMs =
    typeof deps.prepareTimeoutMs === 'number' ? deps.prepareTimeoutMs : PREPARE_TIMEOUT_MS;
  const prepared = await settleWithin(
    () =>
      deps.prepareGuestCall({
        apiKey: secrets.apiKey,
        apiSecret: secrets.apiSecret,
        callId: invite.callId,
        hostUserId: invite.createdBy,
        guestUserId,
        displayName,
        nowSeconds: now,
      }),
    timeoutMs,
  );
  if (!prepared || prepared.ok !== true) {
    if (!activeSeat) await releaseClaim();
    logGuest('joinStreamGuest', { ok: false, reason: 'room', callId: invite.callId });
    jsonError(res, 503, 'room', 'The call could not be prepared. Try again in a moment.');
    return;
  }
  if (!activeSeat) {
    await deps.store.claimGuest({
      callId: invite.callId,
      guestUserId,
      inviteHash: tokenHash,
      sessionHash,
      nowSeconds: now,
      ttlSeconds: GUEST_TOKEN_TTL_SECONDS,
      limit: GUEST_CAP,
    });
  }

  const minted = mintStreamCallScopedToken({
    userId: guestUserId,
    secret: secrets.apiSecret,
    nowSeconds: now,
    ttlSeconds: GUEST_TOKEN_TTL_SECONDS,
    callCids: [guestCallCid(invite.callId)],
    role: GUEST_CALL_ROLE,
  });
  const payload = verifyStreamUserToken(minted.token, secrets.apiSecret);
  const scopedToThisCall =
    payload &&
    Array.isArray(payload.call_cids) &&
    payload.call_cids.length === 1 &&
    payload.call_cids[0] === guestCallCid(invite.callId);
  if (
    !payload ||
    payload.role !== GUEST_CALL_ROLE ||
    payload.server === true ||
    !scopedToThisCall ||
    actorMayModerate({
      actor: 'guest',
      createdByMe: true,
      roles: ['admin', 'host', payload.role],
    })
  ) {
    if (!activeSeat) await releaseClaim();
    jsonError(res, 503, 'room', 'The call could not be prepared. Try again in a moment.');
    return;
  }

  logGuest('joinStreamGuest', { ok: true, callId: invite.callId, renewed: claim.renewed === true });
  res.set('Cache-Control', 'no-store');
  const response = {
    apiKey: secrets.apiKey,
    token: minted.token,
    userId: guestUserId,
    callId: invite.callId,
    expiresAt: minted.expiresAt,
    displayName,
    actor: 'guest',
    callRole: GUEST_CALL_ROLE,
    canModerate: false,
  };
  if (seatKey) response.seatKey = seatKey;
  res.status(200).json(response);
}

async function releaseGuest(req, res, deps, body) {
  if (!(await noteGuestRequest(req, res, deps))) return;
  const inviteToken = body.inviteToken;
  if (!inviteTokenLooksValid(inviteToken)) {
    jsonError(res, 404, 'not-found', 'This invite link is not valid.');
    return;
  }
  const invite = await deps.store.getInvite(hashInviteToken(inviteToken));
  if (!invite) {
    jsonError(res, 404, 'not-found', 'This invite link is not valid.');
    return;
  }
  const guestUserId = body.guestUserId;
  const seatKey = body.seatKey;
  if (!guestUserIdLooksValid(guestUserId) || !seatKeyLooksValid(seatKey)) {
    res.status(200).json({ released: false });
    return;
  }
  const released = await deps.store.releaseGuest({
    callId: invite.callId,
    guestUserId,
    inviteHash: hashInviteToken(inviteToken),
    sessionHash: hashSeatKey(seatKey),
  });
  logGuest('releaseStreamGuest', { ok: true, callId: invite.callId, released: released === true });
  res.status(200).json({ released: released === true });
}

function isRevoked(invite) {
  return typeof invite.revokedAt === 'number';
}

module.exports = {
  INVITE_TTL_SECONDS,
  GUEST_TOKEN_TTL_SECONDS,
  GUEST_PENDING_TTL_SECONDS,
  GUEST_CAP,
  JOIN_WINDOW_SECONDS,
  JOIN_MAX_ATTEMPTS,
  REQUEST_WINDOW_SECONDS,
  REQUEST_MAX_ATTEMPTS,
  GUEST_CALL_ROLE,
  HOST_CALL_ROLE,
  CALL_TYPE,
  hashInviteToken,
  inviteTokenLooksValid,
  sanitizeGuestDisplayName,
  advanceJoinAttempt,
  decideGuestClaim,
  guestCallCid,
  actorMayModerate,
  handleStreamGuestAction,
};
