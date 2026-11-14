# Preview Stream mint (`mint-stream-call-token`)

This page is the operator guide for the preview token function. It is not the
production website. Deploying this function does not publish
`belongonthespectrum.web.app`.

Related pages: [root README](../../../README.md),
[preview group video call](../../../docs/wiki/Stream-Video-Preview.md),
[testing guide](../../../docs/automated_testing.md).

## TL;DR

A preview build never holds the Stream API secret. When someone joins a
call, the app asks this Supabase Edge Function for a short-lived Stream user
token.

- A **signed-in member** sends a Firebase ID token and a call name such as
  `monthly`. The function checks the sign-in, makes sure that call exists,
  adds the member to it, and returns a user token.
- A **guest** has no Belong account. A signed-in member creates a one-day
  link. The guest opens it, types a short name, and this function returns a
  token scoped to that call.

The app uses the public Stream API key from the response. The secret stays
in the function environment.

## How it works

Every request is `POST` JSON. `OPTIONS` is the browser preflight. Any other
method is refused. Guest actions are handled before the sign-in check,
because a guest has no Firebase token. A body with no `action` is the
signed-in member mint.

Browsers are accepted only from `*.web.app`, `*.firebaseapp.com`, and
loopback (`localhost` or `127.0.0.1`). A request with no `Origin` header
(a non-browser caller) is allowed. Any other origin is refused before the
ID token or the secret is read.

`verify_jwt` stays off. Supabase would otherwise require its own JWT, and
guests do not have one. This function checks the Firebase ID token, or the
invite token, itself.

### Signed-in member mint

Who calls it: the lobby (`mint` with the room id) and the in-call refresh
(the same mint with the call id already on the screen). The client already
sends `{ "callId": "<name>" }`.

What the function does, in order:

1. Require `Authorization: Bearer` with a Firebase ID token for the Belong
   project. The token is checked against Google's public keys. The uid must
   match a short id pattern. An email address is not a valid uid here.
2. Normalize the call name: trim, lowercase, turn spaces into single dashes.
   The name must be 3 to 40 characters, letters, numbers, and single dashes.
3. Read `STREAM_API_KEY` and `STREAM_API_SECRET`. If either is missing, stop.
   The secret is the HMAC key for the user token. It is not copied into the
   response or the logs.
4. Upsert a Stream user with that id only. No name, no email, no app role,
   so an existing admin is not rewritten.
5. Get or create the call on call type `default`. A missing call is created
   with `created_by_id` set to this member. An existing call keeps its owner.
6. Upsert this person as a call member (see roles below).
7. Return a three-hour user token. The response shape is unchanged from the
   first preview mint: public key, token, user id, call id, expiry.

If Stream cannot prepare the call, the function does not return a token.

### Guest invite actions

| `action` | Who | What |
| --- | --- | --- |
| `createInvite` | Signed-in member | Stores only the SHA-256 of a new link. Returns the raw token once. The link lasts 24 hours. |
| `revokeInvite` | The member who created that link | Marks the link revoked. Someone else gets a refusal. |
| `joinGuest` | Person with the link | Checks the link, the name, the seat, and the 10-guest cap, then returns a 30-minute call token. |
| `releaseGuest` | The guest's app, on leave | Drops that seat when the seat key matches. A bad key returns `released: false` and does not error. |
| `endCall`, `removeParticipant` | Nobody, on this function | Refused. Ending or removing someone is a client control for a signed-in creator, not a mint action. |
| anything else | | Refused as an unknown action. |

A first `joinGuest` returns a seat key. Only the SHA-256 of that key is
stored. Refresh and release must send the same key. The raw key is not
logged.

The guest token's `role` claim is the app label `call-member` (hyphen).
Stream's members API rejects that spelling. The membership row uses
`call_member` (underscore).

Join attempts on one link are limited to 20 tries in 10 minutes. A seat is
held for about a minute while Stream accepts the guest, then for the
30-minute token. Ten guests is the cap.

### Call member upsert and roles

Stream decides screen share from the **call membership role** and the grants
on call type `default`, not from Belong's on-screen host label.

This function writes:

- `call_member` for a signed-in member, including the person who created the
  call, and for a guest.
- `admin` left as `admin` when that membership is already there.
- `host` is not assigned. If the membership list already says `host`, the
  upsert rewrites it to `call_member`.

`created_by_id` is still the member who created the call. Belong's **End
call** and **Remove someone** controls use that owner flag (`createdByMe`),
not the Stream role named `host`. A signed-in creator keeps those controls
with an empty Stream role list. A guest does not.

Earlier on 14 Nov 2026, `default` had **no grants at all** for `host`. A
signed-in creator could see Belong's host controls and no share button,
because Stream treated them as `host`. That is why this function stopped
assigning `host`.

Later the same day, Stream `default` **gained `host` grants, including
screenshare**. This function still does not assign `host`. A signed-in
member's share button follows the `call_member` grant, or `admin` if they
already have that role. If the button is missing, check the dashboard. This
repo cannot read those grants.

## Configuration

Names only. Do not commit values, tokens, or a Supabase project ref.

| Name | Where | Used for |
| --- | --- | --- |
| `STREAM_API_KEY` | Function secret | Public key returned to the app. |
| `STREAM_API_SECRET` | Function secret | HMAC for Stream tokens. Never returned. |
| `SUPABASE_DB_URL` | Function environment | Invite and seat rows. Guest actions need it. |

The Flutter preview build names the endpoint. It does not receive the secret.

| Name | Where |
| --- | --- |
| `STREAM_VIDEO_PREVIEW` | Dart define. Hides the join button when unset. |
| `STREAM_TOKEN_ENDPOINT` | Dart define. `https` URL of this function. Loopback `http` is the local exception. |

How the app is built and which site it talks to is in
[preview group video call](../../../docs/wiki/Stream-Video-Preview.md).

## Deploy and verify

This page does not deploy anything. When an operator chooses to publish the
function, the command is the function name only:

```bash
supabase functions deploy mint-stream-call-token
```

Set `STREAM_API_KEY` and `STREAM_API_SECRET` as function secrets in the
dashboard or CLI before that deploy. Do not pass the values on the command
line in a way that lands in shell history or CI logs. Do not add a project
ref to notes, issues, or this file.

Local checks, with no live Stream credentials:

```bash
deno test supabase/functions/mint-stream-call-token/member_call_test.ts \
  supabase/functions/mint-stream-call-token/seatkey_test.ts
```

Expect the Deno tests to pass, and the seat-key script to print
`PASS seatKey join/refresh/release`. Those tests stub Stream. They do not
run in the Flutter CI job. The Flutter and Node checks that do run in CI
are listed in the [testing guide](../../../docs/automated_testing.md) and
the [preview call page](../../../docs/wiki/Stream-Video-Preview.md).

After a real deploy, a `POST` with no `Authorization` header and a body of
`{"callId":"monthly"}` should be HTTP 401 and the sentence
`Sign in is required.` The body must not contain `apiSecret` or `secret`.
Do not paste the function URL into git. It embeds the project ref.

## Logs

Each line is one JSON object on stdout: `event`, `ok`, and sometimes
`callId`, `role`, `reason`, `renewed`, or `released`.

Logs do **not** include tokens, the API secret, seat keys, invite tokens,
Firebase ID tokens, emails, or display names. A 401 on the member mint is
not logged today. That gap is [#966](https://github.com/neiljaywarner/refuge/issues/966).

| `event` | `ok` | `reason` or extra field | Meaning |
| --- | --- | --- | --- |
| `mintStreamCallToken` | true | `callId`, `role` | Member token issued. `role` is `call_member` or `admin`. |
| `mintStreamCallToken` | false | `not-configured` | `STREAM_API_KEY` or `STREAM_API_SECRET` is empty. |
| `mintStreamCallToken` | false | `room` | The call could not be created or the member could not be upserted. No token. |
| `mintStreamCallToken` | false | `internal` | The handler threw. The client sees a generic sentence. |
| `createStreamGuestInvite` | true | `callId` | A link was stored. The raw token is only in the HTTP response. |
| `createStreamGuestInvite` | false | `not-configured` | Secrets or the database URL are missing. |
| `revokeStreamGuestInvite` | true | `callId` | The creator revoked that link. |
| `revokeStreamGuestInvite` | false | `not-creator` | A different member tried to revoke it. |
| `joinStreamGuest` | true | `callId`, `renewed` | Guest token issued. `renewed` means the same seat was refreshed. |
| `joinStreamGuest` | false | `rate` | More than 20 attempts on that link in 10 minutes. |
| `joinStreamGuest` | false | `revoked` | The link was revoked. |
| `joinStreamGuest` | false | `expired` | The link is older than 24 hours. |
| `joinStreamGuest` | false | `mismatch` | The body's call name is a different room. |
| `joinStreamGuest` | false | `name` | Empty, too long, an email, or a web link. |
| `joinStreamGuest` | false | `seat` | A guest id was sent without the matching seat key. |
| `joinStreamGuest` | false | `not-configured` | Secrets are missing. |
| `joinStreamGuest` | false | `cap` | Ten guests already hold seats. |
| `joinStreamGuest` | false | `room` | Stream did not accept the room setup. A new seat is released. |
| `releaseStreamGuest` | true | `callId`, `released` | `released` is true only when the seat key matched. |

## FAQ

**Is this production?**
No. Preview and dev only. Production hosting does not turn the call on.

**Who is allowed to mint?**
A Belong Firebase member, or a person holding a live invite link. The call
name alone is not enough.

**Why is the creator `call_member` and not `host`?**
On the morning of 14 Nov 2026, `host` on `default` had no grants, so the
share button never appeared. The function writes `call_member` instead, and
rewrites an existing `host` to `call_member`. As of later that day, `host`
grants exist and include screenshare. The function still does not assign
`host`. Moderator buttons in the app follow `createdByMe`.

**Can a guest end the call?**
No. The guest token is checked so it cannot moderate. End and remove stay
on the signed-in creator (or a Stream admin).

**What if Stream asks for a fresh token mid-call?**
A member's app calls this function again with the Firebase ID token. A
guest's app calls `joinGuest` again with the same invite token, guest id,
and seat key, and does not take a second seat.

## Troubleshooting

| What you see | HTTP | What to do |
| --- | --- | --- |
| `Sign in is required.` | 401 | The member path had no usable Firebase ID token. Sign in again. A guest must use the invite link, not the call name. This 401 is not in the function logs ([#966](https://github.com/neiljaywarner/refuge/issues/966)). |
| `This preview cannot mint a call token.` | 403 | The browser `Origin` is not a `web.app` / `firebaseapp.com` host or loopback. |
| `This account cannot join a call.` | 403 | Stream refused the membership update. The function does not echo Stream's body. |
| `Only the member who created this link can revoke it.` | 403 | `revokeInvite` from a different member. |
| `This invite link is for a different call.` | 403 | `joinGuest` `callId` does not match the link. |
| `This invite link is not valid for that seat.` | 403 | Refresh without the original seat key. Open the link again. |
| `The call could not start. Try again in a moment.` | 502 | Member path: get-or-create or the member upsert failed or timed out (about 12 seconds). No token was returned. |
| `Video calling is not configured on this preview.` | 503 | `STREAM_API_KEY` or `STREAM_API_SECRET` is unset, or guest storage is missing. |
| `The call could not be prepared.` | 503 | Guest path: Stream did not accept the room. Try again. |
| `Too many join attempts.` | 429 | That link was tried more than 20 times in 10 minutes. Wait and retry. |
| `This call already has 10 guests.` | 409 | The seat cap is full. Wait for someone to leave or for a 30-minute seat to expire. |
| `This invite link has expired or was revoked.` | 410 | Older than 24 hours, or the creator revoked it. Make a new link. |
| No screen share button | | The app hides share when the call type does not grant `screenshare`. On Stream call type `default`, check the grants for `host`, `call_member`, and `guest`. As of 14 Nov 2026, `host` includes screenshare. This function still puts signed-in members and guests on `call_member`, so a missing button means that role's grant is off, or the person is still on a role the dashboard does not grant. Belong's host label is `createdByMe` and does not by itself enable share. Screen-share UI is [#952](https://github.com/neiljaywarner/refuge/pull/952). |

The app replaces a mint failure with one of those sentences. It does not
show the response body, because a misconfigured function might echo a
credential.

## Appendix

### Role and grant table

Dashboard column is what was known on 14 Nov 2026. It is not read by this
repo. Re-check the Stream dashboard before treating it as current.

| Role | What this function does | Screenshare on `default` |
| --- | --- | --- |
| `call_member` | Written for signed-in members, including the creator, and for guests. | Yes. This is the role the share button depends on. |
| `admin` | Kept when the person is already admin. Not granted by this function. | Yes. |
| `host` | Not written. An existing `host` row is changed to `call_member`. | Yes, as of later on 14 Nov 2026. Earlier that day this role had no grants, which hid the share button. |
| `guest` | Not written. Someone who is not a member was treated as `guest` before the upsert. | Yes, in the earlier check. |
| `user` | App-level user record only. Not the call membership this function writes. | Yes, in the earlier check. |

`call-member` with a hyphen is only the guest token's role label. Stream's
members API wants `call_member`.

### Request and response shapes

Placeholders are not secrets. Do not paste a real token into an issue.

Signed-in mint. Header `Authorization: Bearer <firebase-id-token>`.

```json
{ "callId": "monthly" }
```

```json
{
  "apiKey": "<public-stream-key>",
  "token": "<user-token>",
  "userId": "member_abc",
  "callId": "monthly",
  "expiresAt": 1700000000
}
```

Create a guest link (same Authorization header):

```json
{ "action": "createInvite", "callId": "monthly" }
```

```json
{
  "inviteToken": "<shown-once>",
  "callId": "monthly",
  "expiresAt": 1700000000,
  "guestLimit": 10
}
```

Revoke:

```json
{ "action": "revokeInvite", "inviteToken": "<shown-once>" }
```

```json
{ "revoked": true, "callId": "monthly" }
```

Join as a guest. No Authorization header. `seatKey` and `guestUserId` are
sent only on refresh.

```json
{
  "action": "joinGuest",
  "inviteToken": "<shown-once>",
  "displayName": "Ada",
  "callId": "monthly"
}
```

```json
{
  "apiKey": "<public-stream-key>",
  "token": "<guest-token>",
  "userId": "g<32-hex>",
  "callId": "monthly",
  "expiresAt": 1700000000,
  "displayName": "Ada",
  "actor": "guest",
  "callRole": "call-member",
  "canModerate": false,
  "seatKey": "<shown-once-on-first-join>"
}
```

Release:

```json
{
  "action": "releaseGuest",
  "inviteToken": "<shown-once>",
  "guestUserId": "g<32-hex>",
  "seatKey": "<shown-once>"
}
```

```json
{ "released": true }
```

A response that contains `apiSecret` or `secret` is refused by the app.

### Related issues

- [#905](https://github.com/neiljaywarner/refuge/pull/905) ports the guest
  actions this function implements.
- [#952](https://github.com/neiljaywarner/refuge/pull/952) is the preview
  screen-share UI. The share button still needs the call-type grant above.
- [#966](https://github.com/neiljaywarner/refuge/issues/966) tracks call
  analytics and the missing 401 log on this function.
- [#928](https://github.com/neiljaywarner/refuge/issues/928) is the screen
  share goal. [#904](https://github.com/neiljaywarner/refuge/issues/904) is
  the guest link.

App behavior, join gates, and the in-call controls are on
[preview group video call](../../../docs/wiki/Stream-Video-Preview.md).
How to run the repo tests is in the
[testing guide](../../../docs/automated_testing.md) and the
[root README](../../../README.md).
