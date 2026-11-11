# Preview Stream mint

This is the Belong **preview/dev** token mint (`mint-stream-call-token`). It
is not the production site and must not be deployed as production.

`STREAM_API_KEY` and `STREAM_API_SECRET` are read from function secrets, never
from this repo or a dart-define. Guest join has no JWT, so the function keeps
`verify_jwt` off and does its own checks.

A first-time `joinGuest` returns a seat key. Only the SHA-256 hash of that
key is stored. Refresh and release require the same key.
