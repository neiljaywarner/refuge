'use strict';

const crypto = require('node:crypto');

const { advanceJoinAttempt, decideGuestClaim } = require('./stream_guest');

function sameHash(left, right) {
  if (typeof left !== 'string' || typeof right !== 'string' || left.length !== right.length) {
    return false;
  }
  if (left.length === 0) return false;
  return crypto.timingSafeEqual(Buffer.from(left), Buffer.from(right));
}

/**
 * In-memory invite book. Tests use this. Production uses
 * [FirestoreInviteStore], which keeps the same methods.
 * The raw invite token is never stored. Callers pass its hash.
 */
class MemoryInviteStore {
  constructor() {
    this.invites = new Map();
    this.sessions = new Map();
    this.requests = new Map();
  }

  async putInvite(record) {
    this.invites.set(record.tokenHash, { ...record, revokedAt: record.revokedAt ?? null });
  }

  async getInvite(tokenHash) {
    const row = this.invites.get(tokenHash);
    return row ? { ...row } : null;
  }

  async revokeInvite(tokenHash, revokedAt) {
    const row = this.invites.get(tokenHash);
    if (!row) return false;
    row.revokedAt = revokedAt;
    return true;
  }

  async revokeInvitesByCreator({ createdBy, callId, revokedAt }) {
    let count = 0;
    for (const row of this.invites.values()) {
      if (row.createdBy !== createdBy || row.callId !== callId) continue;
      if (typeof row.revokedAt === 'number') continue;
      row.revokedAt = revokedAt;
      count += 1;
    }
    return count;
  }

  async noteRequestAttempt(key, nowSeconds, limits) {
    const row = this.requests.get(key) || { attemptWindowStart: 0, attemptCount: 0 };
    const next = advanceJoinAttempt(row, nowSeconds, limits);
    this.requests.set(key, {
      attemptWindowStart: next.attemptWindowStart,
      attemptCount: next.attemptCount,
    });
    return { limited: next.limited };
  }

  async noteJoinAttempt(tokenHash, nowSeconds, limits) {
    const row = this.invites.get(tokenHash);
    if (!row) return { limited: false, found: false };
    const next = advanceJoinAttempt(row, nowSeconds, limits);
    row.attemptWindowStart = next.attemptWindowStart;
    row.attemptCount = next.attemptCount;
    return { limited: next.limited, found: true };
  }

  async findSession({ callId, guestUserId }) {
    const byCall = this.sessions.get(callId);
    if (!byCall) return null;
    const row = byCall.get(guestUserId);
    return row ? { guestUserId, ...row } : null;
  }

  async claimGuest(input) {
    const byCall = this.sessions.get(input.callId) || new Map();
    this.sessions.set(input.callId, byCall);
    const sessions = [...byCall.entries()].map(([guestUserId, row]) => ({
      guestUserId,
      ...row,
    }));
    const decision = decideGuestClaim(sessions, input);
    if (!decision.ok) return decision;
    byCall.set(decision.guestUserId, {
      inviteHash: input.inviteHash,
      expiresAt: decision.expiresAt,
      sessionHash: input.sessionHash,
    });
    return decision;
  }

  async releaseGuest({ callId, guestUserId, inviteHash, sessionHash }) {
    const byCall = this.sessions.get(callId);
    if (!byCall) return false;
    const row = byCall.get(guestUserId);
    if (!row || !sameHash(row.inviteHash, inviteHash) || !sameHash(row.sessionHash, sessionHash)) {
      return false;
    }
    byCall.delete(guestUserId);
    return true;
  }

  /** Test helper. Confirms the raw token was not written down. */
  serialized() {
    return JSON.stringify({
      invites: [...this.invites.values()],
      sessions: [...this.sessions.entries()].map(([callId, people]) => ({
        callId,
        people: [...people.entries()],
      })),
    });
  }
}

/**
 * Admin-SDK store. Clients cannot read these collections; see firestore.rules.
 * Documents are keyed by the token hash, not the token.
 */
class FirestoreInviteStore {
  constructor(db) {
    this.db = db;
  }

  invites() {
    return this.db.collection('stream_call_invites');
  }

  sessions(callId) {
    return this.db.collection('stream_call_guests').doc(callId).collection('sessions');
  }

  async putInvite(record) {
    const { tokenHash, ...data } = record;
    await this.invites().doc(tokenHash).set({ ...data, revokedAt: data.revokedAt ?? null });
  }

  async getInvite(tokenHash) {
    const snap = await this.invites().doc(tokenHash).get();
    if (!snap.exists) return null;
    return { tokenHash, ...snap.data() };
  }

  async revokeInvite(tokenHash, revokedAt) {
    const ref = this.invites().doc(tokenHash);
    const snap = await ref.get();
    if (!snap.exists) return false;
    await ref.update({ revokedAt });
    return true;
  }

  async revokeInvitesByCreator({ createdBy, callId, revokedAt }) {
    const snap = await this.invites()
      .where('createdBy', '==', createdBy)
      .where('callId', '==', callId)
      .get();
    const pending = snap.docs.filter((doc) => typeof doc.data().revokedAt !== 'number');
    let count = 0;
    for (let i = 0; i < pending.length; i += 400) {
      const batch = this.db.batch();
      const slice = pending.slice(i, i + 400);
      for (const doc of slice) {
        batch.update(doc.ref, { revokedAt });
        count += 1;
      }
      if (slice.length > 0) await batch.commit();
    }
    return count;
  }

  async noteRequestAttempt(key, nowSeconds, limits) {
    const ref = this.db.collection('stream_guest_request_limits').doc(key);
    return this.db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const next = advanceJoinAttempt(snap.exists ? snap.data() || {} : {}, nowSeconds, limits);
      tx.set(
        ref,
        {
          attemptWindowStart: next.attemptWindowStart,
          attemptCount: next.attemptCount,
        },
        { merge: true },
      );
      return { limited: next.limited };
    });
  }

  async noteJoinAttempt(tokenHash, nowSeconds, limits) {
    const ref = this.invites().doc(tokenHash);
    return this.db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return { limited: false, found: false };
      const next = advanceJoinAttempt(snap.data() || {}, nowSeconds, limits);
      tx.update(ref, {
        attemptWindowStart: next.attemptWindowStart,
        attemptCount: next.attemptCount,
      });
      return { limited: next.limited, found: true };
    });
  }

  async findSession({ callId, guestUserId }) {
    const snap = await this.sessions(callId).doc(guestUserId).get();
    if (!snap.exists) return null;
    return { guestUserId, ...snap.data() };
  }

  async claimGuest(input) {
    const col = this.sessions(input.callId);
    return this.db.runTransaction(async (tx) => {
      const snap = await tx.get(col.where('expiresAt', '>', input.nowSeconds));
      const sessions = snap.docs.map((doc) => ({ guestUserId: doc.id, ...doc.data() }));
      const decision = decideGuestClaim(sessions, input);
      if (!decision.ok) return decision;
      tx.set(col.doc(decision.guestUserId), {
        inviteHash: input.inviteHash,
        expiresAt: decision.expiresAt,
        sessionHash: input.sessionHash,
      });
      return decision;
    });
  }

  async releaseGuest({ callId, guestUserId, inviteHash, sessionHash }) {
    const ref = this.sessions(callId).doc(guestUserId);
    const snap = await ref.get();
    if (!snap.exists) return false;
    const data = snap.data() || {};
    if (!sameHash(data.inviteHash, inviteHash) || !sameHash(data.sessionHash, sessionHash)) {
      return false;
    }
    await ref.delete();
    return true;
  }
}

module.exports = {
  MemoryInviteStore,
  FirestoreInviteStore,
};
