# Local QA media for Giphy (#666). Do not commit API keys. Screenshots are status-bar cropped when captured via `tool/capture_device.sh`.

## Preview build (PR 715 branch, FLAVOR=dev)

- Web: https://dev-belongonthespectrum--giphy-666-qa-vasz0dlu.web.app (expires ~3 Nov 2026)
- Prod-site mirror (same build): https://belongonthespectrum--giphy-666-qa-zo975xii.web.app

## Test account (yopmail — you can read inbox at yopmail.com)

Use env vars in Maestro: `GIPHY_QA_EMAIL`, `GIPHY_QA_PASSWORD` (not stored in this folder).

## Pixel 9a Android SDK (primary QA)

See **`PIXEL_9A_ANDROID_SDK_QA.md`** for the full matrix.

| File | Who validates |
| --- | --- |
| `pixel_01`–`pixel_11`, `pixel_99` | Agent + you |
| `pixel_giphy_sdk_full_walkthrough.mp4` | **You** — full SDK tabs + Clips motion/sound |

## Web / preview (secondary)

| File | Who validates |
| --- | --- |
| `local_*.png` / `web_*.png` | Agent + you |
| Web video | N/A (Maestro web record noop) |

## Re-run Pixel (recommended)

```bash
cd .worktrees/issue-666-giphy-search
flutter build apk --debug --dart-define=FLAVOR=dev -t lib/main_dev.dart
adb -s 58221JEBF20835 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s 58221JEBF20835 shell screenrecord --bit-rate 8000000 --time-limit 300 /sdcard/pixel_giphy_sdk_full.mp4 &
maestro --device 58221JEBF20835 test \
  -e GIPHY_QA_EMAIL=... -e 'GIPHY_QA_PASSWORD=...' \
  .maestro/giphy_pixel9a_android_sdk_full.yaml
# pkill screenrecord; adb pull → qa_artifacts/giphy/pixel_giphy_sdk_full_walkthrough.mp4
```

## Re-run web (after localhost server)

```bash
flutter run -t lib/main_dev.dart -d web-server --release \
  --web-port 8095 --web-hostname 127.0.0.1 --dart-define=FLAVOR=dev
maestro -p web test --headless -e GIPHY_QA_EMAIL=... -e 'GIPHY_QA_PASSWORD=...' \
  .maestro/web/giphy_media_capture_localhost.yaml
```
