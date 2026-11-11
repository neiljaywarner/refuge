# Roadmap

Updated: 10 November 2026 (America/Chicago).

This is the current product and engineering sequence for Belong and the Refuge platform. It is not a release checklist.

The short solid-1.0 host and soft-launch list is still in [`docs/solid_1.0_checklist.md`](solid_1.0_checklist.md), the [non-technical 1.0 page](wiki/Non-Technical-Roadmap-to-Oct-31.md), and issue [#765](https://github.com/neiljaywarner/refuge/issues/765). Preview work is tested on [the dev site](https://dev-belongonthespectrum.web.app/). Production deploys stay on a separate path.

## 1. Video and audio calling

This comes first.

### Guest join

A signed-in member can create a one-day invite link. A guest opens it, types a display name, and joins the preview call without an account.

- Landed on `main` in [#905](https://github.com/neiljaywarner/refuge/pull/905), which closes [#872](https://github.com/neiljaywarner/refuge/issues/872) and [#904](https://github.com/neiljaywarner/refuge/issues/904).
- Follow-ups: Zoom-style defaults and the public mint ([#908](https://github.com/neiljaywarner/refuge/issues/908)); call shutdown and control-subscription cleanup ([#919](https://github.com/neiljaywarner/refuge/issues/919)).
- Later: scheduled group meetings should reuse the same invite rules ([#903](https://github.com/neiljaywarner/refuge/issues/903)).
- Parent epic: [#871](https://github.com/neiljaywarner/refuge/issues/871).

### Screen share

Zoom-style screen share in the preview call, including a shared screen as the main tile and a start/stop control that stays hidden without permission.

- Issue: [#928](https://github.com/neiljaywarner/refuge/issues/928)
- Open work: [#930](https://github.com/neiljaywarner/refuge/pull/930) on `cursor/screen-share-928`
- Related: a macOS desktop app for calls and sharing is later ([#929](https://github.com/neiljaywarner/refuge/issues/929))

### Audio confidence

Two-way audio has to be trustworthy before we ask people to rely on the call.

- [#909](https://github.com/neiljaywarner/refuge/issues/909) — the other person cannot hear after unmute; the issue has a silent test plan and how to resume.
- [#919](https://github.com/neiljaywarner/refuge/issues/919) also covers join/shutdown races that can leave a call in a bad state.
- Raise confidence with WebRTC and `#909` logs first. An audible listen is a later check, at a time when sound in the house is acceptable.

## 2. Events

Events come next, after calling is in good enough shape.

- **Potluck sign-ups** with SignUpGenius-style slots (who brings what, limited seats per slot).
- **RSVPs** that stay calm and one-tap, in the spirit of the earlier Actually Autistic Events work ([#375](https://github.com/neiljaywarner/refuge/issues/375), [#28](https://github.com/neiljaywarner/refuge/issues/28)).
- **Reminders** so members and hosts get a timely nudge without noisy or anxious messaging.

There is not yet a dedicated open issue for potluck slots. When that ticket is filed, link it here.

## 3. refuge-demo and the `refuge` package

After calling and events, split the reusable platform from Belong itself.

- Extract a reusable `refuge` Dart package and make Belong a thin white-label app on top ([#924](https://github.com/neiljaywarner/refuge/issues/924)).
- [refuge-demo](https://github.com/neiljaywarner/refuge/issues/943) is the public, neutral sales demo of that platform (Circle.so-style, not Belong-branded).
- Related: new demo repo ([#925](https://github.com/neiljaywarner/refuge/issues/925), [#910](https://github.com/neiljaywarner/refuge/issues/910)), demo site and walkthrough ([#941](https://github.com/neiljaywarner/refuge/issues/941)), strip Belong-specific code ([#938](https://github.com/neiljaywarner/refuge/issues/938)), neutral icons and branding ([#940](https://github.com/neiljaywarner/refuge/issues/940)), and package hosting ([#939](https://github.com/neiljaywarner/refuge/issues/939)).
