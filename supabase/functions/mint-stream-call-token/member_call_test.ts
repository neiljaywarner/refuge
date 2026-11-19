import {
  handle,
  memberCallRole,
  MemoryInviteStore,
  prepareGuestOnCall,
  prepareMemberOnCall,
  randomGuestId,
  randomInviteToken,
  verifyStreamUserToken,
  type Deps,
} from "./handler.ts";

const secret = "test-secret-not-used-outside-this-file";
const apiKey = "testapikey";
const now = 1_700_000_000;
const caller = "member_abc";
const owner = "owner_two";
const plantedEmail = "member@belongonthespectrum.com";

function assert(cond: unknown, msg: string) {
  if (!cond) throw new Error(msg);
}

Deno.test("signed-in members are call_member, including the creator and an existing host", () => {
  assert(memberCallRole("") === "call_member", "creator with no membership yet");
  assert(memberCallRole("call_member") === "call_member", "stays call_member");
  assert(memberCallRole("host") === "call_member", "host is downgraded");
  assert(memberCallRole("Host") === "call_member", "host casing");
  assert(memberCallRole("guest") === "call_member", "guest becomes call_member");
  assert(memberCallRole("user") === "call_member", "user becomes call_member");
  assert(memberCallRole("admin") === "admin", "admin stays");
  assert(memberCallRole("Admin") === "admin", "admin casing");
});

interface Seen {
  url: string;
  method: string;
  body: string;
  authorization: string;
}

function seenFrom(input: RequestInfo | URL, init?: RequestInit): Seen {
  const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
  const headers = init?.headers;
  let authorization = "";
  if (headers && typeof headers === "object" && !Array.isArray(headers) && !(headers instanceof Headers)) {
    authorization = String((headers as Record<string, string>).Authorization ?? "");
  }
  return {
    url,
    method: init?.method ?? "GET",
    body: typeof init?.body === "string" ? init.body : "",
    authorization,
  };
}

function scripted(routes: (seen: Seen) => Response): { fetchFn: typeof fetch; calls: Seen[] } {
  const calls: Seen[] = [];
  const fetchFn: typeof fetch = (input, init) => {
    const seen = seenFrom(input, init);
    calls.push(seen);
    return Promise.resolve(routes(seen));
  };
  return { fetchFn, calls };
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(body == null ? "" : JSON.stringify(body), { status });
}

async function assertServerJwt(calls: Seen[]) {
  for (const call of calls) {
    assert(!call.url.includes(secret), "secret stays out of the url");
    assert(!call.body.includes(secret), "secret stays out of the body");
    assert(!call.body.includes(plantedEmail), "email is not copied outbound");
    assert(!call.url.includes(plantedEmail), "email is not copied into the url");
    const payload = await verifyStreamUserToken(call.authorization, secret);
    assert(payload?.server === true, "server token");
    assert(payload?.user_id === undefined, "server token has no user");
  }
}

function memberRole(calls: Seen[], userId: string): string {
  const update = calls.find((call) => call.url.includes("/members"));
  assert(update, "members upsert");
  const body = JSON.parse(update!.body);
  const row = body.update_members.find((member: { user_id: string }) => member.user_id === userId);
  return row.role as string;
}

Deno.test("a new call is created on default and the caller is call_member", async () => {
  const { fetchFn, calls } = scripted((seen) => {
    if (seen.url.includes("/users")) return jsonResponse(201, {});
    if (seen.method === "GET") return jsonResponse(404, { message: "missing" });
    if (seen.url.includes("/members")) return jsonResponse(201, {});
    return jsonResponse(201, { created: true, call: { created_by: { id: caller } } });
  });
  const result = await prepareMemberOnCall({
    apiKey,
    apiSecret: secret,
    callId: "monthly",
    userId: caller,
    nowSeconds: now,
  }, fetchFn);
  assert(result.ok === true && result.role === "call_member", `created ${JSON.stringify(result)}`);
  assert(calls.some((call) => call.url.includes("/video/call/default/monthly")), "default call type");
  assert(!calls.some((call) => call.url.includes("/video/call/guest/")), "not the guest type");
  const create = calls.find((call) => call.method === "POST" && call.url.includes("/monthly?") &&
    !call.url.includes("/members"));
  assert(create, "getOrCreate");
  const created = JSON.parse(create!.body);
  assert(created.data.created_by_id === caller, "owner stays the creator for createdByMe");
  assert(
    JSON.stringify(created.data.members) === JSON.stringify([{ user_id: caller, role: "call_member" }]),
    "call member",
  );
  const users = calls.find((call) => call.url.includes("/users"));
  const userBody = JSON.parse(users!.body);
  assert(JSON.stringify(userBody.users[caller]) === JSON.stringify({ id: caller }), "id only");
  assert(!Object.hasOwn(userBody.users[caller], "role"), "app role is not rewritten");
  assert(memberRole(calls, caller) === "call_member", "upsert call_member");
  assert(!calls.some((call) => call.body.includes('"role":"host"')), "never assigns host");
  await assertServerJwt(calls);
});

Deno.test("joining an existing call uses call_member, and an existing host is downgraded", async () => {
  const cases: { name: string; body: unknown; role: string }[] = [
    {
      name: "someone else's room",
      body: {
        call: { created_by: { id: owner } },
        members: [{ user_id: owner, role: "host" }],
        users: [{ email: plantedEmail }],
      },
      role: "call_member",
    },
    {
      name: "already host",
      body: {
        call: { created_by: { id: owner } },
        members: [{ user: { id: caller }, role: "host" }],
      },
      role: "call_member",
    },
    {
      name: "creator",
      body: { call: { created_by: { id: caller } }, members: [] },
      role: "call_member",
    },
    {
      name: "admin",
      body: {
        call: { created_by: { id: owner } },
        members: [{ user_id: caller, role: "admin" }],
      },
      role: "admin",
    },
  ];
  for (const item of cases) {
    const { fetchFn, calls } = scripted((seen) => {
      if (seen.url.includes("/users")) return jsonResponse(200, {});
      if (seen.method === "GET") return jsonResponse(200, item.body);
      if (seen.url.includes("/members")) return jsonResponse(200, {});
      return jsonResponse(500, { message: "create should not run" });
    });
    const logs: string[] = [];
    const original = console.info;
    console.info = (...args: unknown[]) => logs.push(args.map(String).join(" "));
    try {
      const result = await prepareMemberOnCall({
        apiKey,
        apiSecret: secret,
        callId: "monthly",
        userId: caller,
        nowSeconds: now,
      }, fetchFn);
      assert(result.ok === true && result.role === item.role, `${item.name} ${JSON.stringify(result)}`);
      assert(!calls.some((call) => call.method === "POST" && !call.url.includes("/users") &&
        !call.url.includes("/members")), `${item.name} does not recreate`);
      assert(memberRole(calls, caller) === item.role, item.name);
      assert(!calls.some((call) => call.body.includes('"role":"host"')), `${item.name} does not assign host`);
      const logged = logs.join("\n");
      assert(!logged.includes(secret), "no secret in logs");
      assert(!logged.includes(plantedEmail), "no email in logs");
      await assertServerJwt(calls);
    } finally {
      console.info = original;
    }
  }
});

Deno.test("a create response that echoes host is still saved as call_member", async () => {
  const { fetchFn, calls } = scripted((seen) => {
    if (seen.url.includes("/users")) return jsonResponse(201, {});
    if (seen.method === "GET") return jsonResponse(404, {});
    if (seen.url.includes("/members")) return jsonResponse(201, {});
    return jsonResponse(200, {
      created: false,
      call: { created_by: { id: owner } },
      members: [{ user_id: caller, role: "host" }],
    });
  });
  const result = await prepareMemberOnCall({
    apiKey,
    apiSecret: secret,
    callId: "monthly",
    userId: caller,
    nowSeconds: now,
  }, fetchFn);
  assert(result.ok === true && result.role === "call_member", JSON.stringify(result));
  assert(memberRole(calls, caller) === "call_member", "corrected role");
  assert(!calls.some((call) => call.body.includes('"role":"host"')), "request does not assign host");
});

Deno.test("a guest invite does not upgrade the inviting member to host", async () => {
  const created = scripted((seen) => {
    if (seen.url.includes("/users")) return jsonResponse(201, {});
    if (seen.method === "GET") return jsonResponse(404, {});
    return jsonResponse(201, { created: true });
  });
  const made = await prepareGuestOnCall({
    apiKey,
    apiSecret: secret,
    callId: "monthly",
    hostUserId: caller,
    guestUserId: "g" + "ab".repeat(16),
    displayName: "Ada",
    nowSeconds: now,
  }, created.fetchFn);
  assert(made.ok === true, "guest room");
  const create = created.calls.find((call) =>
    call.method === "POST" && call.url.includes("/monthly?") && !call.url.includes("/members")
  );
  const createBody = JSON.parse(create!.body);
  assert(createBody.data.created_by_id === caller, "owner");
  assert(createBody.data.members[0].role === "call_member", "create role");
  const update = JSON.parse(created.calls.find((call) => call.url.includes("/members"))!.body);
  assert(update.update_members.every((member: { role: string }) => member.role === "call_member"), "both call_member");
  assert(!created.calls.some((call) => call.body.includes('"role":"host"')), "no host");

  const admin = scripted((seen) => {
    if (seen.url.includes("/users")) return jsonResponse(200, {});
    if (seen.method === "GET") {
      return jsonResponse(200, {
        call: { created_by: { id: caller } },
        members: [{ user_id: caller, role: "admin" }],
      });
    }
    return jsonResponse(200, {});
  });
  const kept = await prepareGuestOnCall({
    apiKey,
    apiSecret: secret,
    callId: "monthly",
    hostUserId: caller,
    guestUserId: "g" + "cd".repeat(16),
    displayName: "Ada",
    nowSeconds: now,
  }, admin.fetchFn);
  assert(kept.ok === true, "admin inviter");
  const members = JSON.parse(admin.calls.find((call) => call.url.includes("/members"))!.body).update_members;
  assert(members.find((member: { user_id: string }) => member.user_id === caller).role === "admin", "admin stays");
  assert(!admin.calls.some((call) => call.method === "POST" && !call.url.includes("/users") &&
    !call.url.includes("/members")), "existing call is not recreated");
});

Deno.test("a Stream failure does not report success", async () => {
  const usersDown = scripted(() => jsonResponse(500, { email: plantedEmail }));
  const usersResult = await prepareMemberOnCall({
    apiKey, apiSecret: secret, callId: "monthly", userId: caller, nowSeconds: now,
  }, usersDown.fetchFn);
  assert(usersResult.ok === false && usersResult.status === 500, "users");
  assert(usersDown.calls.length === 1, "stops after users");

  const callDown = scripted((seen) => {
    if (seen.url.includes("/users")) return jsonResponse(200, {});
    return jsonResponse(503, {});
  });
  const callResult = await prepareMemberOnCall({
    apiKey, apiSecret: secret, callId: "monthly", userId: caller, nowSeconds: now,
  }, callDown.fetchFn);
  assert(callResult.ok === false && callResult.status === 503, "get");
  assert(!callDown.calls.some((call) => call.url.includes("/members")), "no upsert after get failure");

  const memberDown = scripted((seen) => {
    if (seen.method === "GET") {
      return jsonResponse(200, { call: { created_by: { id: owner } }, members: [] });
    }
    if (seen.url.includes("/members")) return jsonResponse(400, {});
    return jsonResponse(200, {});
  });
  const memberResult = await prepareMemberOnCall({
    apiKey, apiSecret: secret, callId: "monthly", userId: caller, nowSeconds: now,
  }, memberDown.fetchFn);
  assert(memberResult.ok === false && memberResult.status === 400, "members");
});

function memberDeps(prepare: Deps["prepareMemberCall"]): Deps {
  return {
    apiKey: () => apiKey,
    apiSecret: () => secret,
    nowSeconds: () => now,
    verifyIdToken: async (token) => token === "member-token" ? caller : "",
    store: new MemoryInviteStore(),
    randomInviteToken,
    randomGuestId,
    randomSeatKey: randomInviteToken,
    prepareTimeoutMs: 50,
    prepareGuestCall: async () => ({ ok: true }),
    prepareMemberCall: prepare,
  };
}

async function mint(deps: Deps, body: unknown, headers: Record<string, string> = {}) {
  return await handle(
    new Request("http://localhost/mint", {
      method: "POST",
      headers: { "Content-Type": "application/json", ...headers },
      body: JSON.stringify(body),
    }),
    deps,
  );
}

Deno.test("signed-in mint prepares the call before it returns a user token", async () => {
  let seen: { callId?: string; userId?: string } = {};
  const logs: string[] = [];
  const original = console.info;
  console.info = (...args: unknown[]) => logs.push(args.map(String).join(" "));
  try {
    const res = await mint(
      memberDeps(async (input) => {
        seen = { callId: input.callId, userId: input.userId };
        assert(input.apiSecret === secret, "secret stays on the server call");
        return { ok: true, role: "call_member" };
      }),
      { callId: "monthly" },
      { Authorization: "Bearer member-token" },
    );
    assert(res.status === 200, `status ${res.status}`);
    const body = await res.json();
    assert(body.callId === "monthly" && body.userId === caller, "echo");
    assert(body.apiSecret === undefined && !JSON.stringify(body).includes(secret), "no secret");
    assert(seen.callId === "monthly" && seen.userId === caller, "prepare args");
    const payload = await verifyStreamUserToken(body.token, secret);
    assert(payload?.user_id === caller, "user token");
    assert(payload?.server !== true && payload?.role === undefined, "not a call-scoped token");
    const logged = logs.join("\n");
    assert(logged.includes('"role":"call_member"'), "role is logged");
    assert(logged.includes('"callId":"monthly"'), "call is logged");
    assert(!logged.includes(secret) && !logged.includes(body.token), "token and secret stay out of logs");
    assert(!logged.includes(plantedEmail), "email stays out of logs");
  } finally {
    console.info = original;
  }
});

Deno.test("mint does not return a token when the call cannot be prepared", async () => {
  const failed = await mint(
    memberDeps(async () => ({ ok: false, status: 500 })),
    { callId: "monthly" },
    { Authorization: "Bearer member-token" },
  );
  assert(failed.status === 502, `room ${failed.status}`);
  const failedBody = await failed.json();
  assert(failedBody.token === undefined, "no token");
  assert(!JSON.stringify(failedBody).includes(secret), "no secret");

  const denied = await mint(
    memberDeps(async () => ({ ok: false, status: 403 })),
    { callId: "monthly" },
    { Authorization: "Bearer member-token" },
  );
  assert(denied.status === 403, `denied ${denied.status}`);

  let prepared = false;
  const missing = await mint(
    memberDeps(async () => {
      prepared = true;
      return { ok: true, role: "host" };
    }),
    { callId: "monthly" },
  );
  assert(missing.status === 401 && prepared === false, "auth before prepare");

  const unnamed = await mint(
    {
      ...memberDeps(async () => {
        prepared = true;
        return { ok: true };
      }),
      apiKey: () => "",
    },
    { callId: "monthly" },
    { Authorization: "Bearer member-token" },
  );
  assert(unnamed.status === 503 && prepared === false, "secrets before prepare");
});
