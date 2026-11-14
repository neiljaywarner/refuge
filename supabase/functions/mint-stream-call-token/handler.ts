// Port of #905 functions/src/{stream_call,stream_guest,stream_token,stream_video_api}.js
// to a Supabase edge function. Secrets come only from Deno.env via deps.
// 0d5a0a3 seatKey port: joinGuest returns a seat key on first claim; only its hash is stored.

export const FIREBASE_PROJECT_ID = "belongonthespectrum";
const CALL_ID = /^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/;
const USER_ID = /^[A-Za-z0-9_-]{1,128}$/;
/** Signed-in member token: three hours (same as the live v1 function). */
export const STREAM_TOKEN_TTL_SECONDS = 3 * 60 * 60;
export const INVITE_TTL_SECONDS = 24 * 60 * 60;
export const GUEST_TOKEN_TTL_SECONDS = 30 * 60;
/** A seat is only reserved for a minute until Stream accepts the guest. */
export const GUEST_PENDING_TTL_SECONDS = 60;
/** Leaves time inside the function limit to release a seat. */
export const PREPARE_TIMEOUT_MS = 12 * 1000;
export const GUEST_CAP = 10;
export const JOIN_WINDOW_SECONDS = 10 * 60;
export const JOIN_MAX_ATTEMPTS = 20;
/** App-facing label. Stream's members API takes STREAM_CALL_MEMBER_ROLE instead. */
export const GUEST_CALL_ROLE = "call-member";
export const STREAM_CALL_MEMBER_ROLE = "call_member";
export const HOST_CALL_ROLE = "host";
export const CALL_TYPE = "default";
const ACCEPTED_STREAM_CALL_ROLES = new Set(["user", "moderator", "host", "admin", "call_member"]);
const INVITE_TOKEN = /^[A-Za-z0-9_-]{43}$/;
const GUEST_USER_ID = /^g[a-f0-9]{32}$/;
const HOST_ROLES = new Set(["host", "admin"]);
const VIDEO_ORIGIN = "https://video.stream-io-api.com";

export interface InviteRecord {
  tokenHash: string;
  callId: string;
  createdBy: string;
  createdAt: number;
  expiresAt: number;
  revokedAt: number | null;
  attemptWindowStart: number;
  attemptCount: number;
}
export interface SessionRecord {
  guestUserId: string;
  inviteHash: string;
  expiresAt: number;
  sessionHash?: string;
}
export interface ClaimInput {
  callId: string; guestUserId: string; inviteHash: string; sessionHash: string;
  nowSeconds: number; ttlSeconds: number; limit: number;
}
export interface ClaimResult { ok: boolean; reason?: string; renewed?: boolean; guestUserId?: string; expiresAt?: number }
export interface InviteStore {
  putInvite(r: InviteRecord): Promise<void>;
  getInvite(tokenHash: string): Promise<InviteRecord | null>;
  revokeInvite(tokenHash: string, revokedAt: number): Promise<boolean>;
  noteJoinAttempt(tokenHash: string, now: number, limits: { windowSeconds: number; maxAttempts: number }):
    Promise<{ limited: boolean; found: boolean }>;
  findSession(q: { callId: string; guestUserId: string }): Promise<SessionRecord | null>;
  claimGuest(input: ClaimInput): Promise<ClaimResult>;
  releaseGuest(q: { callId: string; guestUserId: string; inviteHash: string; sessionHash: string }): Promise<boolean>;
}
export interface PrepareInput {
  apiKey: string; apiSecret: string; callId: string; hostUserId: string;
  guestUserId: string; displayName: string; nowSeconds: number;
}
export interface MemberPrepareInput {
  apiKey: string;
  apiSecret: string;
  callId: string;
  userId: string;
  nowSeconds: number;
}
export interface MemberPrepareResult {
  ok: boolean;
  status?: number;
  role?: string;
}
export interface Deps {
  apiKey(): string;
  apiSecret(): string;
  nowSeconds(): number;
  verifyIdToken(token: string): Promise<string>; // returns uid or ""
  store: InviteStore | null;
  randomInviteToken(): string;
  randomGuestId(): string;
  randomSeatKey(): string;
  prepareTimeoutMs?: number;
  prepareGuestCall(input: PrepareInput): Promise<{ ok: boolean; status?: number }>;
  /** Defaults to prepareMemberOnCall when omitted. */
  prepareMemberCall?(input: MemberPrepareInput): Promise<MemberPrepareResult>;
}

// ---------- pure helpers ----------
export function normalizeCallId(value: unknown): string {
  if (typeof value !== "string") return "";
  const normalized = value.trim().toLowerCase().replace(/\s+/g, "-");
  if (normalized.includes("--")) return "";
  return CALL_ID.test(normalized) ? normalized : "";
}

export function isAllowedOrigin(origin: string | null): boolean {
  if (!origin) return true; // non-browser callers (same as live v1)
  if (origin.length > 200) return false;
  try {
    const url = new URL(origin);
    if (url.username || url.password) return false;
    if (url.protocol === "http:" && (url.hostname === "localhost" || url.hostname === "127.0.0.1")) return true;
    if (url.protocol !== "https:") return false;
    return url.hostname.endsWith(".web.app") || url.hostname.endsWith(".firebaseapp.com");
  } catch {
    return false;
  }
}

export function corsHeaders(origin: string | null): Record<string, string> {
  const headers: Record<string, string> = { "Content-Type": "application/json", "Cache-Control": "no-store" };
  if (origin && isAllowedOrigin(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
    headers["Vary"] = "Origin";
    headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, apikey";
    headers["Access-Control-Allow-Methods"] = "POST, OPTIONS";
    headers["Access-Control-Max-Age"] = "600";
  }
  return headers;
}

export function inviteTokenLooksValid(t: unknown): t is string {
  return typeof t === "string" && INVITE_TOKEN.test(t);
}
export function seatKeyLooksValid(t: unknown): t is string {
  return inviteTokenLooksValid(t);
}
export function guestUserIdLooksValid(t: unknown): t is string {
  return typeof t === "string" && GUEST_USER_ID.test(t);
}
export function guestCallCid(callId: string): string {
  return `${CALL_TYPE}:${callId}`;
}

export function sanitizeGuestDisplayName(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  // deno-lint-ignore no-control-regex
  if (/[\u0000-\u001F\u007F]/.test(raw)) return null;
  if (/[\u202A-\u202E\u2066-\u2069]/.test(raw)) return null;
  const trimmed = raw.trim().replace(/ +/g, " ");
  if (!trimmed || trimmed.length > 40) return null;
  if (trimmed.includes("@")) return null;
  if (/[a-z][a-z0-9+.-]*:\/\//i.test(trimmed) || /www\./i.test(trimmed)) return null;
  return trimmed;
}

export function advanceJoinAttempt(
  record: { attemptWindowStart?: number; attemptCount?: number },
  nowSeconds: number,
  limits: { windowSeconds: number; maxAttempts: number },
) {
  const start = typeof record.attemptWindowStart === "number" ? record.attemptWindowStart : 0;
  const previous = typeof record.attemptCount === "number" ? record.attemptCount : 0;
  const fresh = start === 0 || nowSeconds - start >= limits.windowSeconds;
  const attemptWindowStart = fresh ? nowSeconds : start;
  const attemptCount = fresh ? 1 : previous + 1;
  return { attemptWindowStart, attemptCount, limited: attemptCount > limits.maxAttempts };
}

export function decideGuestClaim(sessions: SessionRecord[], input: ClaimInput): ClaimResult {
  const active = sessions.filter((s) => s.expiresAt > input.nowSeconds);
  const sameId = active.find((s) => s.guestUserId === input.guestUserId);
  if (sameId && sameId.inviteHash !== input.inviteHash) return { ok: false, reason: "conflict" };
  const mine = Boolean(sameId);
  if (!mine && active.length >= input.limit) return { ok: false, reason: "cap" };
  return { ok: true, renewed: mine, guestUserId: input.guestUserId, expiresAt: input.nowSeconds + input.ttlSeconds };
}

export function actorMayModerate(
  { actor, createdByMe, roles }: { actor: string; createdByMe?: boolean; roles?: unknown[] },
): boolean {
  if (actor !== "member") return false;
  if (createdByMe === true) return true;
  const list = Array.isArray(roles) ? roles : [];
  return list.some((r) => typeof r === "string" && HOST_ROLES.has(r.toLowerCase()));
}

export function timingSafeEqualHex(left: string, right: string): boolean {
  if (typeof left !== "string" || typeof right !== "string" || left.length !== right.length || left.length === 0) {
    return false;
  }
  const a = new TextEncoder().encode(left);
  const b = new TextEncoder().encode(right);
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i += 1) diff |= a[i] ^ b[i];
  return diff === 0;
}

export async function settleWithin<T>(
  work: () => Promise<T>,
  ms: number,
): Promise<T | { ok: false; timedOut: true } | null> {
  return await new Promise((resolve) => {
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

// ---------- crypto ----------
const enc = new TextEncoder();
function b64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}
function b64urlString(s: string): string {
  return b64url(enc.encode(s));
}
export function decodeB64urlBytes(part: string): Uint8Array<ArrayBuffer> {
  const pad = "=".repeat((4 - (part.length % 4)) % 4);
  const bin = atob(part.replaceAll("-", "+").replaceAll("_", "/") + pad);
  const bytes = new Uint8Array(new ArrayBuffer(bin.length));
  for (let i = 0; i < bin.length; i += 1) bytes[i] = bin.charCodeAt(i);
  return bytes;
}
export function decodeB64urlJson(part: string): Record<string, unknown> {
  return JSON.parse(new TextDecoder().decode(decodeB64urlBytes(part)));
}

export async function sha256Hex(value: string): Promise<string> {
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", enc.encode(value)));
  return [...digest].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function hmacKey(secret: string) {
  return await crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, [
    "sign",
    "verify",
  ]);
}

export async function signStreamToken(claims: Record<string, unknown> & { exp: number }, secret: string) {
  const header = b64urlString(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const payload = b64urlString(JSON.stringify(claims));
  const unsigned = `${header}.${payload}`;
  const sig = new Uint8Array(await crypto.subtle.sign("HMAC", await hmacKey(secret), enc.encode(unsigned)));
  return { token: `${unsigned}.${b64url(sig)}`, expiresAt: claims.exp };
}

export function mintStreamUserToken(userId: string, secret: string, nowSeconds: number, ttl = STREAM_TOKEN_TTL_SECONDS) {
  return signStreamToken({ user_id: userId, iat: nowSeconds, exp: nowSeconds + ttl }, secret);
}

export function mintStreamCallScopedToken(
  { userId, secret, nowSeconds, ttlSeconds, callCids, role }: {
    userId: string; secret: string; nowSeconds: number; ttlSeconds: number; callCids: string[]; role: string;
  },
) {
  return signStreamToken(
    { user_id: userId, role, call_cids: callCids, iat: nowSeconds, exp: nowSeconds + ttlSeconds },
    secret,
  );
}

export function mintStreamServerToken(secret: string, nowSeconds: number, ttl = 5 * 60) {
  return signStreamToken({ server: true, iat: nowSeconds, exp: nowSeconds + ttl }, secret);
}

export async function verifyStreamUserToken(token: string, secret: string): Promise<Record<string, unknown> | null> {
  const parts = typeof token === "string" ? token.split(".") : [];
  if (parts.length !== 3) return null;
  try {
    const ok = await crypto.subtle.verify(
      "HMAC",
      await hmacKey(secret),
      decodeB64urlBytes(parts[2]),
      enc.encode(`${parts[0]}.${parts[1]}`),
    );
    if (!ok) return null;
    return decodeB64urlJson(parts[1]);
  } catch {
    return null;
  }
}

export function randomInviteToken(): string {
  return b64url(crypto.getRandomValues(new Uint8Array(32))); // 43 chars
}
export function randomGuestId(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  return "g" + [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
}
export function randomSeatKey(): string {
  return randomInviteToken();
}

async function seatMatches(
  existing: SessionRecord | null,
  tokenHash: string,
  seatKey: unknown,
): Promise<boolean> {
  if (!existing || existing.inviteHash !== tokenHash) return false;
  if (!seatKeyLooksValid(seatKey) || typeof existing.sessionHash !== "string") return false;
  const actual = await sha256Hex(seatKey);
  return timingSafeEqualHex(actual, existing.sessionHash);
}

// ---------- Firebase ID token ----------
export async function verifyFirebaseIdToken(token: string): Promise<string> {
  const parts = token.split(".");
  if (parts.length !== 3) return "";
  try {
    const header = decodeB64urlJson(parts[0]);
    if (header.alg !== "RS256") return "";
    const certRes = await fetch(
      "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
    );
    if (!certRes.ok) return "";
    const jwks = await certRes.json() as { keys?: Array<JsonWebKey & { kid?: string }> };
    const jwk = (jwks.keys ?? []).find((k) => k.kid === header.kid);
    if (!jwk) return "";
    const key = await crypto.subtle.importKey("jwk", jwk, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, [
      "verify",
    ]);
    const ok = await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      key,
      decodeB64urlBytes(parts[2]),
      enc.encode(`${parts[0]}.${parts[1]}`),
    );
    if (!ok) return "";
    const payload = decodeB64urlJson(parts[1]);
    const now = Math.floor(Date.now() / 1000);
    if (typeof payload.exp !== "number" || payload.exp < now) return "";
    if (payload.aud !== FIREBASE_PROJECT_ID) return "";
    if (payload.iss !== `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`) return "";
    const uid = String(payload.user_id ?? payload.sub ?? "").trim();
    return USER_ID.test(uid) ? uid : "";
  } catch {
    return "";
  }
}

// ---------- Stream video API (port of stream_video_api.js) ----------
export async function prepareGuestOnCall(
  input: PrepareInput,
  fetchFn: typeof fetch = fetch,
): Promise<{ ok: boolean; status?: number }> {
  const { apiKey, apiSecret, callId, hostUserId, guestUserId, displayName, nowSeconds } = input;
  const server = await mintStreamServerToken(apiSecret, nowSeconds);
  const headers = { Authorization: server.token, "stream-auth-type": "jwt", "Content-Type": "application/json" };
  const key = encodeURIComponent(apiKey);
  const users = await fetchFn(`${VIDEO_ORIGIN}/api/v2/users?api_key=${key}`, {
    method: "POST",
    headers,
    body: JSON.stringify({
      users: {
        [hostUserId]: { id: hostUserId, role: "user" },
        [guestUserId]: { id: guestUserId, name: displayName, role: "user" },
      },
    }),
  });
  await discard(users);
  if (!users.ok) return { ok: false, status: users.status };

  const callPath = `${VIDEO_ORIGIN}/api/v2/video/call/${CALL_TYPE}/${encodeURIComponent(callId)}`;
  const callUrl = `${callPath}?api_key=${key}`;
  const existing = await fetchFn(callUrl, { method: "GET", headers });
  await discard(existing);
  if (existing.status === 404) {
    const created = await fetchFn(callUrl, {
      method: "POST",
      headers,
      body: JSON.stringify({
        data: { created_by_id: hostUserId, members: [{ user_id: hostUserId, role: HOST_CALL_ROLE }] },
      }),
    });
    await discard(created);
    if (!created.ok) return { ok: false, status: created.status };
  } else if (!existing.ok) {
    return { ok: false, status: existing.status };
  }
  if (!ACCEPTED_STREAM_CALL_ROLES.has(HOST_CALL_ROLE) || !ACCEPTED_STREAM_CALL_ROLES.has(STREAM_CALL_MEMBER_ROLE)) {
    return { ok: false, status: 400 };
  }
  const updated = await fetchFn(`${callPath}/members?api_key=${key}`, {
    method: "POST",
    headers,
    body: JSON.stringify({
      update_members: [
        { user_id: hostUserId, role: HOST_CALL_ROLE },
        { user_id: guestUserId, role: STREAM_CALL_MEMBER_ROLE },
      ],
    }),
  });
  await discard(updated);
  if (!updated.ok) return { ok: false, status: updated.status };
  return { ok: true };
}

async function discard(r: Response) {
  try {
    await r.text();
  } catch {
    // status is enough; body is never logged
  }
}

async function readJson(response: Response): Promise<Record<string, unknown> | null> {
  let text = "";
  try {
    text = await response.text();
  } catch {
    return null;
  }
  if (!text) return null;
  try {
    const parsed = JSON.parse(text);
    return parsed && typeof parsed === "object" && !Array.isArray(parsed)
      ? parsed as Record<string, unknown>
      : null;
  } catch {
    return null;
  }
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function createdByIdOf(created: unknown): string {
  if (typeof created === "string") return created;
  const obj = asRecord(created);
  if (!obj) return "";
  if (typeof obj.id === "string") return obj.id;
  if (typeof obj.user_id === "string") return obj.user_id;
  return "";
}

function callOwnerId(body: Record<string, unknown> | null): string {
  if (!body) return "";
  const call = asRecord(body.call) ?? body;
  return createdByIdOf(call.created_by);
}

function memberUserId(member: Record<string, unknown>): string {
  if (typeof member.user_id === "string") return member.user_id;
  const user = asRecord(member.user);
  return user && typeof user.id === "string" ? user.id : "";
}

function membershipRole(body: Record<string, unknown>, userId: string): string {
  const lists: unknown[] = [];
  if (Array.isArray(body.members)) lists.push(body.members);
  const call = asRecord(body.call);
  if (call && Array.isArray(call.members)) lists.push(call.members);
  for (const list of lists) {
    if (!Array.isArray(list)) continue;
    for (const item of list) {
      const member = asRecord(item);
      if (!member || memberUserId(member) !== userId) continue;
      return typeof member.role === "string" ? member.role.toLowerCase() : "";
    }
  }
  return "";
}

/**
 * Call role for a signed-in member.
 * Host when they created the call or are already host.
 * Admin stays admin so a dashboard admin is not demoted.
 * Everyone else is call_member, which can share a screen on the default call type.
 */
export function memberCallRole(
  { userId, createdById, existingRole }: { userId: string; createdById: string; existingRole: string },
): string {
  const role = existingRole.trim().toLowerCase();
  if (role === "admin") return "admin";
  if (createdById !== "" && createdById === userId) return HOST_CALL_ROLE;
  if (role === HOST_CALL_ROLE) return HOST_CALL_ROLE;
  return STREAM_CALL_MEMBER_ROLE;
}

function requestCreatedCall(status: number, body: Record<string, unknown> | null, userId: string): boolean {
  if (body && body.created === false) return false;
  const owner = callOwnerId(body);
  if (owner !== "" && owner !== userId) return false;
  if (body && body.created === true) return true;
  if (owner === userId) return true;
  return status === 201;
}

/**
 * Ensures the call exists (Stream get-or-create, call type `default`) and
 * upserts the signed-in member. GET first so an existing call does not get a
 * new owner. The user record has an id only: no role, name, or email.
 * Response bodies are read and never logged.
 */
export async function prepareMemberOnCall(
  input: MemberPrepareInput,
  fetchFn: typeof fetch = fetch,
): Promise<MemberPrepareResult> {
  const { apiKey, apiSecret, callId, userId, nowSeconds } = input;
  if (!ACCEPTED_STREAM_CALL_ROLES.has(HOST_CALL_ROLE) || !ACCEPTED_STREAM_CALL_ROLES.has(STREAM_CALL_MEMBER_ROLE)) {
    return { ok: false, status: 400 };
  }
  const server = await mintStreamServerToken(apiSecret, nowSeconds);
  const headers = { Authorization: server.token, "stream-auth-type": "jwt", "Content-Type": "application/json" };
  const key = encodeURIComponent(apiKey);
  const users = await fetchFn(`${VIDEO_ORIGIN}/api/v2/users?api_key=${key}`, {
    method: "POST",
    headers,
    body: JSON.stringify({ users: { [userId]: { id: userId } } }),
  });
  await readJson(users);
  if (!users.ok) return { ok: false, status: users.status };

  const callPath = `${VIDEO_ORIGIN}/api/v2/video/call/${CALL_TYPE}/${encodeURIComponent(callId)}`;
  const callUrl = `${callPath}?api_key=${key}`;
  const existing = await fetchFn(`${callUrl}&members_limit=100`, { method: "GET", headers });
  const existingBody = await readJson(existing);

  let createdById = "";
  let existingRole = "";
  if (existing.status === 404) {
    const created = await fetchFn(callUrl, {
      method: "POST",
      headers,
      body: JSON.stringify({
        data: {
          created_by_id: userId,
          members: [{ user_id: userId, role: HOST_CALL_ROLE }],
        },
      }),
    });
    const createdBody = await readJson(created);
    if (!created.ok) return { ok: false, status: created.status };
    const owner = callOwnerId(createdBody);
    const echoed = createdBody ? membershipRole(createdBody, userId) : "";
    if (requestCreatedCall(created.status, createdBody, userId)) {
      createdById = owner || userId;
      existingRole = echoed || HOST_CALL_ROLE;
    } else {
      createdById = owner;
      // The create body asked for host. A lost race must not keep that echo.
      existingRole = echoed === HOST_CALL_ROLE ? "" : echoed;
    }
  } else if (!existing.ok) {
    return { ok: false, status: existing.status };
  } else if (!existingBody) {
    return { ok: false, status: 502 };
  } else {
    createdById = callOwnerId(existingBody);
    existingRole = membershipRole(existingBody, userId);
  }

  const role = memberCallRole({ userId, createdById, existingRole });
  if (!ACCEPTED_STREAM_CALL_ROLES.has(role)) return { ok: false, status: 400 };
  const updated = await fetchFn(`${callPath}/members?api_key=${key}`, {
    method: "POST",
    headers,
    body: JSON.stringify({ update_members: [{ user_id: userId, role }] }),
  });
  await readJson(updated);
  if (!updated.ok) return { ok: false, status: updated.status };
  return { ok: true, role };
}

// ---------- handler (port of stream_call.js + stream_guest.js) ----------
type Body = Record<string, unknown>;

function log(event: string, fields: Record<string, unknown>) {
  console.info(JSON.stringify({ event, ...fields }));
}

function readSecrets(deps: Deps) {
  const apiKey = (deps.apiKey() ?? "").trim();
  const apiSecret = (deps.apiSecret() ?? "").trim();
  return { apiKey, apiSecret };
}

async function requireMember(req: Request, deps: Deps): Promise<string> {
  const match = /^Bearer\s+(\S+)$/.exec(req.headers.get("Authorization") ?? "");
  if (!match) return "";
  try {
    const uid = await deps.verifyIdToken(match[1]);
    return USER_ID.test(uid) ? uid : "";
  } catch {
    return "";
  }
}

export async function handle(req: Request, deps: Deps): Promise<Response> {
  const origin = req.headers.get("Origin");
  const json = (status: number, body: Record<string, unknown>) =>
    new Response(JSON.stringify(body), { status, headers: corsHeaders(origin) });
  const err = (status: number, code: string, error: string) => json(status, { error, code });

  if (req.method === "OPTIONS") {
    return new Response(null, { status: isAllowedOrigin(origin) ? 204 : 403, headers: corsHeaders(origin) });
  }
  if (req.method !== "POST") return json(405, { error: "POST only." });
  if (origin && !isAllowedOrigin(origin)) return json(403, { error: "This preview cannot mint a call token." });

  let body: Body = {};
  try {
    const parsed = await req.json();
    body = parsed && typeof parsed === "object" ? parsed as Body : {};
  } catch {
    body = {};
  }
  const action = typeof body.action === "string" ? body.action : "";
  // Guest actions are routed BEFORE the member sign-in gate (as in #905).
  if (action === "endCall" || action === "removeParticipant") {
    return err(403, "forbidden", "Only a signed-in host can do that.");
  }
  if (action === "createInvite") return await createInvite(req, deps, body, err, json);
  if (action === "revokeInvite") return await revokeInvite(req, deps, body, err, json);
  if (action === "joinGuest") return await joinGuest(deps, body, err, json);
  if (action === "releaseGuest") return await releaseGuest(deps, body, err, json);
  if (action) return err(400, "forbidden", "That call action is not available.");

  // No action: signed-in member mint. A user token alone leaves the caller as
  // Stream's guest role, which cannot share a screen. The call id is already
  // on this request. Ensure the call exists and upsert this member first.
  const userId = await requireMember(req, deps);
  if (!userId) return json(401, { error: "Sign in is required." });
  const callId = normalizeCallId(body.callId);
  if (!callId) return json(400, { error: "Choose a short call name using letters, numbers, and dashes." });
  const { apiKey, apiSecret } = readSecrets(deps);
  if (!apiKey || !apiSecret) {
    log("mintStreamCallToken", { ok: false, reason: "not-configured" });
    return json(503, { error: "Video calling is not configured on this preview." });
  }
  const nowSeconds = deps.nowSeconds();
  const timeoutMs = typeof deps.prepareTimeoutMs === "number" ? deps.prepareTimeoutMs : PREPARE_TIMEOUT_MS;
  const prepare = deps.prepareMemberCall ?? prepareMemberOnCall;
  const prepared = await settleWithin(
    () => prepare({ apiKey, apiSecret, callId, userId, nowSeconds }),
    timeoutMs,
  );
  if (!prepared || prepared.ok !== true) {
    log("mintStreamCallToken", { ok: false, reason: "room", callId });
    const denied = Boolean(prepared && "status" in prepared && prepared.status === 403);
    return json(denied ? 403 : 502, {
      error: denied
        ? "This account cannot join a call."
        : "The call could not start. Try again in a moment.",
    });
  }
  const minted = await mintStreamUserToken(userId, apiSecret, nowSeconds);
  const role = typeof prepared.role === "string" && ACCEPTED_STREAM_CALL_ROLES.has(prepared.role)
    ? prepared.role
    : "";
  log("mintStreamCallToken", role ? { ok: true, callId, role } : { ok: true, callId });
  return json(200, { apiKey, token: minted.token, userId, callId, expiresAt: minted.expiresAt });
}

type ErrFn = (status: number, code: string, error: string) => Response;
type JsonFn = (status: number, body: Record<string, unknown>) => Response;
const UNCONFIGURED = "Video calling is not configured on this preview.";
const NOT_VALID = "This invite link is not valid.";

async function createInvite(req: Request, deps: Deps, body: Body, err: ErrFn, json: JsonFn) {
  const userId = await requireMember(req, deps);
  if (!userId) return err(401, "auth", "Sign in is required.");
  const callId = normalizeCallId(body.callId);
  if (!callId) return err(400, "call", "Choose a short call name using letters, numbers, and dashes.");
  const secrets = readSecrets(deps);
  if (!secrets.apiKey || !secrets.apiSecret) {
    log("createStreamGuestInvite", { ok: false, reason: "not-configured", callId });
    return err(503, "unconfigured", UNCONFIGURED);
  }
  if (!deps.store) return err(503, "unconfigured", UNCONFIGURED);
  const now = deps.nowSeconds();
  const inviteToken = deps.randomInviteToken();
  if (!inviteTokenLooksValid(inviteToken)) return err(503, "unconfigured", UNCONFIGURED);
  await deps.store.putInvite({
    tokenHash: await sha256Hex(inviteToken),
    callId,
    createdBy: userId,
    createdAt: now,
    expiresAt: now + INVITE_TTL_SECONDS,
    revokedAt: null,
    attemptWindowStart: 0,
    attemptCount: 0,
  });
  log("createStreamGuestInvite", { ok: true, callId });
  return json(200, { inviteToken, callId, expiresAt: now + INVITE_TTL_SECONDS, guestLimit: GUEST_CAP });
}

async function revokeInvite(req: Request, deps: Deps, body: Body, err: ErrFn, json: JsonFn) {
  const userId = await requireMember(req, deps);
  if (!userId) return err(401, "auth", "Sign in is required.");
  const inviteToken = body.inviteToken;
  if (!inviteTokenLooksValid(inviteToken) || !deps.store) return err(404, "not-found", NOT_VALID);
  const tokenHash = await sha256Hex(inviteToken);
  const invite = await deps.store.getInvite(tokenHash);
  if (!invite) return err(404, "not-found", NOT_VALID);
  if (invite.createdBy !== userId) {
    log("revokeStreamGuestInvite", { ok: false, reason: "not-creator" });
    return err(403, "forbidden", "Only the member who created this link can revoke it.");
  }
  await deps.store.revokeInvite(tokenHash, deps.nowSeconds());
  log("revokeStreamGuestInvite", { ok: true, callId: invite.callId });
  return json(200, { revoked: true, callId: invite.callId });
}

function isRevoked(invite: InviteRecord) {
  return typeof invite.revokedAt === "number";
}

async function joinGuest(deps: Deps, body: Body, err: ErrFn, json: JsonFn) {
  const inviteToken = body.inviteToken;
  if (!inviteTokenLooksValid(inviteToken) || !deps.store) return err(404, "not-found", NOT_VALID);
  const store = deps.store;
  const tokenHash = await sha256Hex(inviteToken);
  const invite = await store.getInvite(tokenHash);
  if (!invite || typeof invite.callId !== "string") return err(404, "not-found", NOT_VALID);

  const now = deps.nowSeconds();
  const requestedCallId = typeof body.callId === "string" ? body.callId.trim().toLowerCase() : "";
  const displayName = sanitizeGuestDisplayName(body.displayName);
  const live = !isRevoked(invite) && now < invite.expiresAt;
  const callOk = !requestedCallId || requestedCallId === invite.callId;
  const suppliedGuestId = body.guestUserId;
  const suppliedSeatKey = body.seatKey;
  const existing = live && callOk && displayName && guestUserIdLooksValid(suppliedGuestId)
    ? await store.findSession({ callId: invite.callId, guestUserId: suppliedGuestId })
    : null;
  const reclaiming = await seatMatches(existing, tokenHash, suppliedSeatKey);
  const activeSeat = Boolean(reclaiming && existing && existing.expiresAt > now);

  if (!activeSeat) {
    const attempt = await store.noteJoinAttempt(tokenHash, now, {
      windowSeconds: JOIN_WINDOW_SECONDS,
      maxAttempts: JOIN_MAX_ATTEMPTS,
    });
    if (attempt.limited) {
      log("joinStreamGuest", { ok: false, reason: "rate", callId: invite.callId });
      return err(429, "rate", "Too many join attempts. Wait a few minutes and try the link again.");
    }
  }
  if (isRevoked(invite)) {
    log("joinStreamGuest", { ok: false, reason: "revoked", callId: invite.callId });
    return err(410, "revoked", "This invite link has expired or was revoked.");
  }
  if (now >= invite.expiresAt) {
    log("joinStreamGuest", { ok: false, reason: "expired", callId: invite.callId });
    return err(410, "expired", "This invite link has expired or was revoked.");
  }
  if (!callOk) {
    log("joinStreamGuest", { ok: false, reason: "mismatch", callId: invite.callId });
    return err(403, "mismatch", "This invite link is for a different call.");
  }
  if (!displayName) {
    log("joinStreamGuest", { ok: false, reason: "name", callId: invite.callId });
    return err(400, "name", "Use a short name. Leave out email addresses and web links.");
  }
  // The invite link is shared. It is not enough to refresh or replace a seat.
  if (guestUserIdLooksValid(suppliedGuestId) && !reclaiming) {
    log("joinStreamGuest", { ok: false, reason: "seat", callId: invite.callId });
    return err(403, "seat", "This invite link is not valid for that seat. Open the link again.");
  }
  const secrets = readSecrets(deps);
  if (!secrets.apiKey || !secrets.apiSecret) {
    log("joinStreamGuest", { ok: false, reason: "not-configured", callId: invite.callId });
    return err(503, "unconfigured", UNCONFIGURED);
  }
  if (typeof deps.randomGuestId !== "function" || typeof deps.randomSeatKey !== "function") {
    return err(503, "unconfigured", UNCONFIGURED);
  }

  let seatKey: string | null = null;
  let sessionHash: string | null = null;
  if (reclaiming) {
    sessionHash = existing!.sessionHash ?? null;
  } else {
    seatKey = deps.randomSeatKey();
    if (!seatKeyLooksValid(seatKey)) return err(503, "unconfigured", UNCONFIGURED);
    sessionHash = await sha256Hex(seatKey);
  }
  if (!sessionHash) return err(503, "unconfigured", UNCONFIGURED);

  const guestUserId = reclaiming ? suppliedGuestId as string : deps.randomGuestId();
  if (!guestUserIdLooksValid(guestUserId)) return err(503, "unconfigured", UNCONFIGURED);

  const claim = await store.claimGuest({
    callId: invite.callId,
    guestUserId,
    inviteHash: tokenHash,
    sessionHash,
    nowSeconds: now,
    ttlSeconds: activeSeat ? GUEST_TOKEN_TTL_SECONDS : GUEST_PENDING_TTL_SECONDS,
    limit: GUEST_CAP,
  });
  if (!claim.ok) {
    log("joinStreamGuest", { ok: false, reason: "cap", callId: invite.callId });
    return err(409, "cap", "This call already has 10 guests. Try again after someone leaves.");
  }

  const releaseClaim = () =>
    store.releaseGuest({ callId: invite.callId, guestUserId, inviteHash: tokenHash, sessionHash: sessionHash! });

  const timeoutMs = typeof deps.prepareTimeoutMs === "number" ? deps.prepareTimeoutMs : PREPARE_TIMEOUT_MS;
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
    log("joinStreamGuest", { ok: false, reason: "room", callId: invite.callId });
    return err(503, "room", "The call could not be prepared. Try again in a moment.");
  }
  if (!activeSeat) {
    await store.claimGuest({
      callId: invite.callId,
      guestUserId,
      inviteHash: tokenHash,
      sessionHash,
      nowSeconds: now,
      ttlSeconds: GUEST_TOKEN_TTL_SECONDS,
      limit: GUEST_CAP,
    });
  }

  const cid = guestCallCid(invite.callId);
  const minted = await mintStreamCallScopedToken({
    userId: guestUserId,
    secret: secrets.apiSecret,
    nowSeconds: now,
    ttlSeconds: GUEST_TOKEN_TTL_SECONDS,
    callCids: [cid],
    role: GUEST_CALL_ROLE,
  });
  const payload = await verifyStreamUserToken(minted.token, secrets.apiSecret);
  const cids = payload?.call_cids;
  const scoped = Array.isArray(cids) && cids.length === 1 && cids[0] === cid;
  if (
    !payload || payload.role !== GUEST_CALL_ROLE || payload.server === true || !scoped ||
    actorMayModerate({ actor: "guest", createdByMe: true, roles: ["admin", "host", payload.role] })
  ) {
    if (!activeSeat) await releaseClaim();
    return err(503, "room", "The call could not be prepared. Try again in a moment.");
  }
  log("joinStreamGuest", { ok: true, callId: invite.callId, renewed: claim.renewed === true });
  const response: Record<string, unknown> = {
    apiKey: secrets.apiKey,
    token: minted.token,
    userId: guestUserId,
    callId: invite.callId,
    expiresAt: minted.expiresAt,
    displayName,
    actor: "guest",
    callRole: GUEST_CALL_ROLE,
    canModerate: false,
  };
  if (seatKey) response.seatKey = seatKey;
  return json(200, response);
}

async function releaseGuest(deps: Deps, body: Body, err: ErrFn, json: JsonFn) {
  const inviteToken = body.inviteToken;
  if (!inviteTokenLooksValid(inviteToken) || !deps.store) return err(404, "not-found", NOT_VALID);
  const tokenHash = await sha256Hex(inviteToken);
  const invite = await deps.store.getInvite(tokenHash);
  if (!invite) return err(404, "not-found", NOT_VALID);
  const guestUserId = body.guestUserId;
  const seatKey = body.seatKey;
  if (!guestUserIdLooksValid(guestUserId) || !seatKeyLooksValid(seatKey)) {
    return json(200, { released: false });
  }
  const released = await deps.store.releaseGuest({
    callId: invite.callId,
    guestUserId,
    inviteHash: tokenHash,
    sessionHash: await sha256Hex(seatKey),
  });
  log("releaseStreamGuest", { ok: true, callId: invite.callId, released: released === true });
  return json(200, { released: released === true });
}

// ---------- in-memory store (tests only) ----------
export class MemoryInviteStore implements InviteStore {
  invites = new Map<string, InviteRecord>();
  sessions = new Map<string, Map<string, { inviteHash: string; expiresAt: number; sessionHash?: string }>>();
  async putInvite(r: InviteRecord) {
    this.invites.set(r.tokenHash, { ...r, revokedAt: r.revokedAt ?? null });
  }
  async getInvite(h: string) {
    const r = this.invites.get(h);
    return r ? { ...r } : null;
  }
  async revokeInvite(h: string, at: number) {
    const r = this.invites.get(h);
    if (!r) return false;
    r.revokedAt = at;
    return true;
  }
  async noteJoinAttempt(h: string, now: number, limits: { windowSeconds: number; maxAttempts: number }) {
    const r = this.invites.get(h);
    if (!r) return { limited: false, found: false };
    const n = advanceJoinAttempt(r, now, limits);
    r.attemptWindowStart = n.attemptWindowStart;
    r.attemptCount = n.attemptCount;
    return { limited: n.limited, found: true };
  }
  async findSession({ callId, guestUserId }: { callId: string; guestUserId: string }) {
    const row = this.sessions.get(callId)?.get(guestUserId);
    return row ? { guestUserId, ...row } : null;
  }
  async claimGuest(input: ClaimInput) {
    const byCall = this.sessions.get(input.callId) ?? new Map();
    this.sessions.set(input.callId, byCall);
    const list = [...byCall.entries()].map(([guestUserId, r]) => ({ guestUserId, ...r }));
    const d = decideGuestClaim(list, input);
    if (!d.ok) return d;
    byCall.set(input.guestUserId, {
      inviteHash: input.inviteHash,
      expiresAt: d.expiresAt!,
      sessionHash: input.sessionHash,
    });
    return d;
  }
  async releaseGuest(
    { callId, guestUserId, inviteHash, sessionHash }: {
      callId: string; guestUserId: string; inviteHash: string; sessionHash: string;
    },
  ) {
    const byCall = this.sessions.get(callId);
    const row = byCall?.get(guestUserId);
    if (!row || !timingSafeEqualHex(row.inviteHash, inviteHash) || typeof row.sessionHash !== "string" ||
      !timingSafeEqualHex(row.sessionHash, sessionHash)) {
      return false;
    }
    byCall!.delete(guestUserId);
    return true;
  }
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
