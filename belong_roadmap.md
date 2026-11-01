# Belong on the Spectrum — Product roadmap

> **Updated**: Sunday, November 1, 2026 (America/Chicago)  
> **Repository**: [neiljaywarner/refuge](https://github.com/neiljaywarner/refuge)  
> **Living checklist**: [Issue #765](https://github.com/neiljaywarner/refuge/issues/765) and [`docs/solid_1.0_checklist.md`](docs/solid_1.0_checklist.md)  
> **Plain-language page**: [`docs/wiki/Non-Technical-Roadmap-to-Oct-31.md`](docs/wiki/Non-Technical-Roadmap-to-Oct-31.md)

## Hosts

| Role | URL |
| :--- | :--- |
| Production / soft launch | [https://belongonthespectrum.web.app/](https://belongonthespectrum.web.app/) |
| Dev | [https://dev-belongonthespectrum.web.app/](https://dev-belongonthespectrum.web.app/) |
| Marketing site (not the app) | [https://www.belongonthespectrum.com/](https://www.belongonthespectrum.com/) |

[https://onthespectrum.web.app/](https://onthespectrum.web.app/) is **not** a Belong host (Firebase Site Not Found). Prefer the `belongonthespectrum` URLs above.

## Now: solid 1.0

The Circle overlap window (October 24–31, 2026) is behind us. Soft launch is the two web hosts above. Calling **1.0 solid** is a short list for the next few hours and days, not a new multi-week calendar. Nothing in that list is marked done here.

1. Ship a fresh **non-DEV** production build and deploy it to `belongonthespectrum.web.app`. Aim for **0.9.7** or **0.9.8**, or **1.0.0** if that name is chosen. Strangers should hit the production sign-in wall.
2. Close, fix, or explicitly defer the open pull requests, and prune leftover worktrees. The list lives on [#765](https://github.com/neiljaywarner/refuge/issues/765).
3. Finish the soft-launch Giphy path: the calm **Attach media** sheet ([#762](https://github.com/neiljaywarner/refuge/issues/762) / [#764](https://github.com/neiljaywarner/refuge/pull/764)) with Powered by GIPHY on the picker. Defer Clips, the JS SDK spike, and quota-key work unless they block attach.
4. Confirm both web hosts load Belong.
5. On production, confirm **Vote & Feedback** is the only support face, the ban lockout is present, and the email-verification message is the soft gate.

## Not required to call 1.0 solid

- Public App Store and Play listings ([#45](https://github.com/neiljaywarner/refuge/issues/45), [#46](https://github.com/neiljaywarner/refuge/issues/46)) and a full TestFlight matrix ([#44](https://github.com/neiljaywarner/refuge/issues/44)).
- iOS APNs device verification and public Google/Apple 1-tap as the default sign-in.
- Maestro suite cleanup beyond a smoke check.
- Circle CSV re-import polish.

## Earlier schedule

Day-by-day tables for October 18–31 lived in this file while that window was still ahead. Git history keeps them. Do not treat “still scheduled for October 24” lines from older copies as open work.
