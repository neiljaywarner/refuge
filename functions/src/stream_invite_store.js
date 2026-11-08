'use strict';

const { advanceJoinAttempt, decideGuestClaim } = require('./stream_guest');

/**
 * In-memory invite book. Tests use this. Production uses
 * [FirestoreInviteStore], which keeps the same methods.
 * The raw invite token is never stored. Callers pass its hash.
 */
class MemoryInviteStore {
  constructor() {
    this.invites = new Map();
    this.sessions = new Map();
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
    });
    return decision;
  }

  async releaseGuest({ callId, guestUserId, inviteHash }) {
    const byCall = this.sessions.get(callId);
    if (!byCall) return false;
    const row = byCall.get(guestUserId);
    if (!row || row.inviteHash !== inviteHash) return false;
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
      });
      return decision;
    });
  }

  async releaseGuest({ callId, guestUserId, inviteHash }) {
    const ref = this.sessions(callId).doc(guestUserId);
    const snap = await ref.get();
    if (!snap.exists) return false;
    if (snap.data().inviteHash !== inviteHash) return false;
    await ref.delete();
    return true;
  }
}

module.exports = {
  MemoryInviteStore,
  FirestoreInviteStore,
};
