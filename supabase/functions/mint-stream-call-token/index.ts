// mint-stream-call-token: signed-in member mint (call membership + user token) + #905 guest actions.
// STREAM_API_KEY / STREAM_API_SECRET are read from Supabase function secrets only.
// 0d5a0a3 seatKey port: first-time joinGuest returns a seat key; only its hash is stored.
import postgres from "npm:postgres@3.4.5";
import {
  type Deps,
  handle,
  prepareGuestOnCall,
  prepareMemberOnCall,
  randomGuestId,
  randomInviteToken,
  verifyFirebaseIdToken,
} from "./handler.ts";
import { PgInviteStore } from "./pg_store.ts";

const dbUrl = Deno.env.get("SUPABASE_DB_URL") ?? "";
const sql = dbUrl ? postgres(dbUrl, { prepare: false, max: 2, idle_timeout: 20 }) : null;

const deps: Deps = {
  apiKey: () => Deno.env.get("STREAM_API_KEY") ?? "",
  apiSecret: () => Deno.env.get("STREAM_API_SECRET") ?? "",
  nowSeconds: () => Math.floor(Date.now() / 1000),
  verifyIdToken: verifyFirebaseIdToken,
  store: sql ? new PgInviteStore(sql) : null,
  randomInviteToken,
  randomGuestId,
  randomSeatKey: randomInviteToken,
  prepareGuestCall: (input) => prepareGuestOnCall(input),
  prepareMemberCall: (input) => prepareMemberOnCall(input),
};

Deno.serve(async (req: Request) => {
  try {
    return await handle(req, deps);
  } catch (_) {
    console.info(JSON.stringify({ event: "mintStreamCallToken", ok: false, reason: "internal" }));
    const origin = req.headers.get("Origin");
    const { corsHeaders } = await import("./handler.ts");
    return new Response(JSON.stringify({ error: "The call could not start. Try again in a moment." }), {
      status: 500,
      headers: corsHeaders(origin),
    });
  }
});
