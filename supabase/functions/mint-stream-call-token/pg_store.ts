// Postgres-backed invite store (mirrors FirestoreInviteStore in #905).
// Tables live in the private `belong_guest` schema, which is not exposed to
// the Data API. Only the hash of an invite token or seat key is ever written.
import postgres from "npm:postgres@3.4.5";
import type { ClaimInput, ClaimResult, InviteRecord, InviteStore, SessionRecord } from "./handler.ts";

type Sql = ReturnType<typeof postgres>;

export class PgInviteStore implements InviteStore {
  constructor(private sql: Sql) {}

  async putInvite(r: InviteRecord) {
    await this.sql`
      insert into belong_guest.stream_call_invites
        (token_hash, call_id, created_by, created_at, expires_at, revoked_at, attempt_window_start, attempt_count)
      values (${r.tokenHash}, ${r.callId}, ${r.createdBy}, ${r.createdAt}, ${r.expiresAt},
              ${r.revokedAt}, ${r.attemptWindowStart}, ${r.attemptCount})
      on conflict (token_hash) do update set
        call_id = excluded.call_id, created_by = excluded.created_by, created_at = excluded.created_at,
        expires_at = excluded.expires_at, revoked_at = excluded.revoked_at,
        attempt_window_start = excluded.attempt_window_start, attempt_count = excluded.attempt_count`;
  }

  async getInvite(tokenHash: string): Promise<InviteRecord | null> {
    const rows = await this.sql`
      select token_hash, call_id, created_by, created_at, expires_at, revoked_at,
             attempt_window_start, attempt_count
        from belong_guest.stream_call_invites where token_hash = ${tokenHash}`;
    if (rows.length === 0) return null;
    const r = rows[0];
    return {
      tokenHash: r.token_hash,
      callId: r.call_id,
      createdBy: r.created_by,
      createdAt: Number(r.created_at),
      expiresAt: Number(r.expires_at),
      revokedAt: r.revoked_at === null ? null : Number(r.revoked_at),
      attemptWindowStart: Number(r.attempt_window_start),
      attemptCount: Number(r.attempt_count),
    };
  }

  async revokeInvite(tokenHash: string, revokedAt: number) {
    const rows = await this.sql`
      update belong_guest.stream_call_invites set revoked_at = ${revokedAt}
       where token_hash = ${tokenHash} returning token_hash`;
    return rows.length > 0;
  }

  async noteJoinAttempt(tokenHash: string, now: number, limits: { windowSeconds: number; maxAttempts: number }) {
    const rows = await this.sql`
      select is_found, is_limited from belong_guest.note_join_attempt(
        ${tokenHash}, ${now}, ${limits.windowSeconds}, ${limits.maxAttempts})`;
    const r = rows[0];
    return { found: r?.is_found === true, limited: r?.is_limited === true };
  }

  async findSession({ callId, guestUserId }: { callId: string; guestUserId: string }): Promise<SessionRecord | null> {
    const rows = await this.sql`
      select invite_hash, expires_at, session_hash from belong_guest.stream_call_guest_sessions
       where call_id = ${callId} and guest_user_id = ${guestUserId}`;
    if (rows.length === 0) return null;
    return {
      guestUserId,
      inviteHash: rows[0].invite_hash,
      expiresAt: Number(rows[0].expires_at),
      sessionHash: rows[0].session_hash == null ? undefined : String(rows[0].session_hash),
    };
  }

  async claimGuest(i: ClaimInput): Promise<ClaimResult> {
    const rows = await this.sql`
      select belong_guest.claim_guest(${i.callId}, ${i.guestUserId}, ${i.inviteHash}, ${i.sessionHash},
                                      ${i.nowSeconds}, ${i.ttlSeconds}, ${i.limit}) as result`;
    const r = rows[0]?.result as ClaimResult | undefined;
    if (!r) return { ok: false, reason: "cap" };
    return { ...r, expiresAt: r.expiresAt === undefined ? undefined : Number(r.expiresAt) };
  }

  async releaseGuest(
    { callId, guestUserId, inviteHash, sessionHash }: {
      callId: string; guestUserId: string; inviteHash: string; sessionHash: string;
    },
  ) {
    const rows = await this.sql`
      delete from belong_guest.stream_call_guest_sessions
       where call_id = ${callId} and guest_user_id = ${guestUserId}
         and invite_hash = ${inviteHash} and session_hash = ${sessionHash}
       returning guest_user_id`;
    return rows.length > 0;
  }
}
