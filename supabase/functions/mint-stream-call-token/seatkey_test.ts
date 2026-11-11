import {
  handle,
  MemoryInviteStore,
  randomGuestId,
  randomInviteToken,
  sha256Hex,
  type Deps,
} from "./handler.ts";

const secret = "test-secret-not-used-outside-this-file";
const apiKey = "testapikey";
const now = 1_700_000_000;
const store = new MemoryInviteStore();

const deps: Deps = {
  apiKey: () => apiKey,
  apiSecret: () => secret,
  nowSeconds: () => now,
  verifyIdToken: async (token) => token === "member-token" ? "member_abc" : "",
  store,
  randomInviteToken,
  randomGuestId,
  randomSeatKey: randomInviteToken,
  prepareTimeoutMs: 200,
  prepareGuestCall: async () => ({ ok: true }),
};

async function post(body: unknown, headers: Record<string, string> = {}) {
  return await handle(
    new Request("http://localhost/mint", {
      method: "POST",
      headers: { "Content-Type": "application/json", ...headers },
      body: JSON.stringify(body),
    }),
    deps,
  );
}

function assert(cond: unknown, msg: string) {
  if (!cond) throw new Error(msg);
}

const created = await post(
  { action: "createInvite", callId: "preview-room" },
  { Authorization: "Bearer member-token" },
);
assert(created.status === 200, `createInvite ${created.status}`);
const invite = await created.json();
assert(typeof invite.inviteToken === "string", "invite token");

const joined = await post({
  action: "joinGuest",
  inviteToken: invite.inviteToken,
  displayName: "Ada",
  callId: "preview-room",
});
assert(joined.status === 200, `joinGuest ${joined.status} ${await joined.clone().text()}`);
const first = await joined.json();
assert(first.actor === "guest", "actor");
assert(first.callRole === "call-member", "role");
assert(first.canModerate === false, "moderate");
assert(typeof first.seatKey === "string" && first.seatKey.length === 43, "seatKey present");
assert(typeof first.userId === "string" && first.userId.startsWith("g"), "guest id");
assert(!store.serialized().includes(first.seatKey), "raw seat key must not be stored");
const seatHash = await sha256Hex(first.seatKey);
assert(store.serialized().includes(seatHash), "hash is stored");

const refreshed = await post({
  action: "joinGuest",
  inviteToken: invite.inviteToken,
  displayName: "Ada",
  callId: "preview-room",
  guestUserId: first.userId,
  seatKey: first.seatKey,
});
assert(refreshed.status === 200, `refresh ${refreshed.status}`);
const second = await refreshed.json();
assert(second.userId === first.userId, "same seat");
assert(second.seatKey === undefined, "refresh does not reissue seatKey");

const badSeat = await post({
  action: "joinGuest",
  inviteToken: invite.inviteToken,
  displayName: "Ada",
  callId: "preview-room",
  guestUserId: first.userId,
  seatKey: "z".repeat(43),
});
assert(badSeat.status === 403, `wrong seat ${badSeat.status}`);
const badBody = await badSeat.json();
assert(badBody.code === "seat", "seat code");

const released = await post({
  action: "releaseGuest",
  inviteToken: invite.inviteToken,
  guestUserId: first.userId,
  seatKey: first.seatKey,
});
assert(released.status === 200, "release");
const rel = await released.json();
assert(rel.released === true, "released true");

console.log("PASS seatKey join/refresh/release");
