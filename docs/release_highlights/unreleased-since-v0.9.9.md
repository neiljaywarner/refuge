# What's new since v0.9.9

These notes are for the next production release. Production is still **v0.9.9** (the public version file on 11 November 2026). The changes below are on `main` and on the dev site.

Nothing here is a store listing yet. Play Store and App Store pages are still pending. The short paragraph at the bottom is ready to paste into a "what's new" field when a listing exists.

## For members

- **Your phone's text size now changes Belong.** A larger system font grows the type in the app, together with the text size you pick in sensory settings. Sign-in, home, messages, and feedback were checked at several sizes. A few tight spots are still open: the feed can feel short, and some rows can clip on a phone ([#932](https://github.com/neiljaywarner/refuge/issues/932)). Call screens will get the same check after video calling lands ([#935](https://github.com/neiljaywarner/refuge/issues/935)).
- **Relate keeps a name this device already knows.** Press and hold Relate, and a person who related on this device stays listed when a later update only has the count. A phone opening the post for the first time, with only that count, can still show an empty list. This covers posts and comments ([#933](https://github.com/neiljaywarner/refuge/pull/933)).
- **Animated text on a post.** In the attach sheet, choose Animate Text, type a short phrase, and attach a styled text GIF. It works on the website, the Android web app, and an iPhone home-screen app. The result stays PG, motion stays calm, and the GIPHY credit stays visible ([#862](https://github.com/neiljaywarner/refuge/pull/862)).
- **A cleaner list of people you can message.** Someone who has left the member directory, or whose account is closed or banned, no longer shows up as a message recipient ([#813](https://github.com/neiljaywarner/refuge/issues/813)).
- **Honest notification settings on the web.** When the browser cannot offer push, the notification sheet says so ([#857](https://github.com/neiljaywarner/refuge/issues/857)).
- **Feedback is stored once.** If a feedback note is sent again after a hiccup, Belong keeps a single copy of that note ([#857](https://github.com/neiljaywarner/refuge/issues/857)).

## For organizers and contributors

These do not change what members see in the app.

- The partner wiki now shows Refuge as the platform and Belong as the first community, with a Circle.so scorecard and a 90-day playbook ([#923](https://github.com/neiljaywarner/refuge/pull/923)).
- When a free backend has to keep running with very little attention, the docs now prefer Supabase Free, because ordinary visits and requests count. The live member store is still Firestore ([#907](https://github.com/neiljaywarner/refuge/pull/907)).
- A sanitized November working-chat archive is in `docs/chat-transcripts/` for apprentices. It is not product documentation ([#881](https://github.com/neiljaywarner/refuge/pull/881)).
- Continuous integration now uses `actions/setup-java` 6 ([#921](https://github.com/neiljaywarner/refuge/pull/921)).

## Paste-ready "what's new"

Larger phone text now changes Belong's type, together with the in-app size. Press and hold Relate to see a name this device already saved. A first visit that only has the count can still be blank. You can attach animated text from GIPHY on the website and the home-screen app. The message list skips people who left the directory or whose accounts are closed. On the web, notification settings say when push is unavailable.

## Not in this batch

Video calling, guest join, and screen sharing are still open pull requests ([#905](https://github.com/neiljaywarner/refuge/pull/905), [#930](https://github.com/neiljaywarner/refuge/pull/930)). They are preview-only. A production build keeps the sign-in wall. The release checklist is [#937](https://github.com/neiljaywarner/refuge/issues/937).
