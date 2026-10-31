# Giphy GIF search

Belong uses Giphy so members can attach calm, wholesome media to reflections. The experience is designed to feel **complete on the website** and **delightful on the phone** when the native apps ship.

## Official package (Android and iOS)

Phone builds use the **official Giphy Flutter SDK** from [giphy.com](https://pub.dev/publishers/giphy.com/packages) — [`giphy_flutter_sdk`](https://pub.dev/packages/giphy_flutter_sdk) on pub.dev.

As of 31 Oct 2026, pub.dev listed that package at **130 / 160 pub points** and about **115,000 downloads in the previous 30 days**. It is Giphy’s supported integration, not a third-party wrapper.

## Remote Config (all platforms)

| Parameter | Purpose | Default |
| --- | --- | --- |
| `giphy_api_key` | Beta key from the [Giphy developer dashboard](https://developers.giphy.com/dashboard/). Leave blank to turn search off. The same beta key can be shared across PG refuge apps while you try the feature. Free tier: about **100 API calls per hour** shared across whatever uses that key. | `""` *(paste in Firebase console, never in git)* |
| `giphy_content_rating` | Highest rating to request: `g`, `pg`, or `pg-13`. **`pg`** includes mild superhero-style content and excludes PG-13 and R. Invalid values, including `r`, are treated as `pg`. | `pg` |

The app also accepts `--dart-define=GIPHY_API_KEY=...` as a developer fallback when Remote Config is empty.

Putting the key in Remote Config is normal for Giphy: it is not a payment secret. If someone copies it, the worst case is using up the free hourly quota — search pauses until the hour resets.

## Website: a real GIF picker

On **belongonthespectrum.web.app** (and other web/desktop targets), **Search GIFs** is a full picker, not a placeholder:

- Trending and search against Giphy’s API at the published rating ceiling.
- **Still previews** while you browse (motion starts after you attach).
- **Powered by GIPHY** attribution.
- Paste-a-URL still works if search is off or you already have a link.

That is enough for reflections, memes, and calm humor on the web. We do not treat the website as a “demo” of the phone app.

## Phone apps: the same button, more Giphy

On **Android and iOS**, the same **Search GIFs** tab opens Giphy’s official dialog with:

| Feature | Phone (SDK) | Website (API) |
| --- | --- | --- |
| GIFs | Yes | Yes |
| Stickers | Yes | — |
| Emoji | Yes | — |
| Animated text | Yes | — |
| **Clips** (short video with sound) | Yes | — |
| Recents | Yes | — |

### What are Clips?

**Giphy Clips** are short videos — a quote, a reaction, a character moment — often with **sound in the picker**. They are the kind of content that makes Giphy feel like Slack or Instagram, not just a static image search.

Belong’s calm-tech rule for the **feed**: when you attach a Clip, the reflection stores an **https image or GIF URL**, not autoplaying audio in the sanctuary scroll. You can preview sound **while choosing** in the native picker; the shared post stays visually calm for sensitive members.

That split is intentional: the website gives you GIF search that feels finished; the phone app gives you **Clips, stickers, emoji, and animated text** — a fair reason to install from the store later and, if the experience feels good, leave a **5-star review**. We never beg for stars; we earn them by shipping something worth installing.

## Android setup (required for SDK + Clips)

- `MainActivity` must extend **`FlutterFragmentActivity`** (the Giphy dialog does not open from `FlutterActivity`).
- **`GiphyFlutterSDK.videoPlayerAdapter=exoplayeradapter@2.18.1`** in `android/gradle.properties` so Clips are not stubbed out.

iOS uses the SDK’s built-in clips player; the project deployment target already meets the SDK minimum.

## Architecture (for contributors)

- `giphy_surface.dart` — `nativeSdk` on Android/iOS, `webApi` on web/desktop.
- `giphy_remote_settings.dart` — reads Remote Config + dart-define fallback.
- `giphy_sdk_picker.dart` — configures and shows `GiphyDialog` on phones.
- `giphy_search.dart` — HTTP client for the PWA only.

See also **[Organizer Remote Config Guide](Organizer-Remote-Config-Guide)** for parameter descriptions.

## Related work

- GitHub: [#666](https://github.com/neiljaywarner/refuge/issues/666) (Giphy integration), PR [#715](https://github.com/neiljaywarner/refuge/pull/715).
- Store beta path: [#44](https://github.com/neiljaywarner/refuge/issues/44) (TestFlight and Play internal/closed beta before [#45](https://github.com/neiljaywarner/refuge/issues/45) / [#46](https://github.com/neiljaywarner/refuge/issues/46)).
