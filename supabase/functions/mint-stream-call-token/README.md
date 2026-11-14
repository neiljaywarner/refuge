# Preview Stream mint

This is the Belong **preview/dev** token mint (`mint-stream-call-token`). It
is not the production site and must not be deployed as production.

`STREAM_API_KEY` and `STREAM_API_SECRET` are read from function secrets, never
from this repo or a dart-define. Guest join has no JWT, so the function keeps
`verify_jwt` off and does its own checks.

A first-time `joinGuest` returns a seat key. Only the SHA-256 hash of that
key is stored. Refresh and release require the same key.

A signed-in mint (no `action`) also gets or creates the `default` call and
adds the caller. On that call type, `host` has no grants, so it cannot share
a screen. Signed-in members, including the creator and anyone already listed
as `host`, are upserted as `call_member`. An existing admin stays `admin`.
This path does not assign `host`. The call is still created with
`created_by_id` set to the creator. Belong's end and remove controls use that
owner flag (`createdByMe`), not the Stream membership role. Guest setup uses
the same rule for the inviting member. The token response is unchanged. Logs
stay free of tokens, secrets, and email addresses.
