# Preview Stream mint

This is the Belong **preview/dev** token mint (`mint-stream-call-token`). It
is not the production site and must not be deployed as production.

`STREAM_API_KEY` and `STREAM_API_SECRET` are read from function secrets, never
from this repo or a dart-define. Guest join has no JWT, so the function keeps
`verify_jwt` off and does its own checks.

A first-time `joinGuest` returns a seat key. Only the SHA-256 hash of that
key is stored. Refresh and release require the same key.

A signed-in mint (no `action`) also gets or creates the `default` call and
adds the caller. The creator, or someone who is already host, is `host`. An
existing admin stays `admin`. Everyone else is `call_member`, which can share
a screen. The token response is unchanged. Logs stay free of tokens, secrets,
and email addresses.
