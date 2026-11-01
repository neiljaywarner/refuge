# Solid 1.0 checklist (November 1, 2026)

> **When**: Sunday, November 1, 2026 (America/Chicago). The next few hours and days, not a new multi-week plan.  
> **Living issue**: [#765](https://github.com/neiljaywarner/refuge/issues/765). If this page and the issue disagree, follow the issue.  
> **This page does not mark items done.** Checking a box belongs on the issue after someone verifies it.

## Hosts

- **Production / soft launch:** [https://belongonthespectrum.web.app/](https://belongonthespectrum.web.app/)
- **Dev:** [https://dev-belongonthespectrum.web.app/](https://dev-belongonthespectrum.web.app/)
- **Not a Belong host:** [https://onthespectrum.web.app/](https://onthespectrum.web.app/) (Firebase Site Not Found)

The marketing site [https://www.belongonthespectrum.com/](https://www.belongonthespectrum.com/) is separate from the Flutter web app.

## Still open

### A. Fresh non-DEV production build

- [ ] Tag a release from current `main` after the merges below. Aim **0.9.7** or **0.9.8**, or **1.0.0** if that name is chosen.
- [ ] Deploy production web to `belongonthespectrum.web.app` (not `onthespectrum.web.app`).
- [ ] Confirm strangers hit the **non-DEV** sign-in wall.
- [ ] Confirm the Android open-beta / App Distribution build includes the Giphy path and the merges already on `main`, or republish it.

The last production deploy this repository’s runbook records is **v0.9.2** on 2026-10-28. That note is not a claim about which build is live today.

### B. Open pull requests and worktrees

Close, fix CI, or close with a reason. The November 1 afternoon list is on [#765](https://github.com/neiljaywarner/refuge/issues/765) (including [#764](https://github.com/neiljaywarner/refuge/pull/764), [#763](https://github.com/neiljaywarner/refuge/pull/763), [#757](https://github.com/neiljaywarner/refuge/pull/757), [#754](https://github.com/neiljaywarner/refuge/pull/754), [#747](https://github.com/neiljaywarner/refuge/pull/747), [#746](https://github.com/neiljaywarner/refuge/pull/746), [#734](https://github.com/neiljaywarner/refuge/pull/734)). Then prune worktrees and agent branches whose pull requests are merged or abandoned.

### C. Giphy, enough for soft launch

- [ ] Land the calm **Attach media** sheet with Powered by GIPHY on the picker ([#764](https://github.com/neiljaywarner/refuge/pull/764) / [#762](https://github.com/neiljaywarner/refuge/issues/762)).
- [ ] Smoke GIF search on **production** and **dev** after deploy.
- [ ] Confirm Remote Config keys `giphy_api_key*` exist. No keys in git.

Defer past 1.0 unless they block attach: [#751](https://github.com/neiljaywarner/refuge/issues/751) (JS SDK spike), [#738](https://github.com/neiljaywarner/refuge/issues/738) / [#743](https://github.com/neiljaywarner/refuge/issues/743) (Clips / iPhone verify), [#741](https://github.com/neiljaywarner/refuge/issues/741) (quota keys).

### D. Both web hosts

- [ ] [https://dev-belongonthespectrum.web.app/](https://dev-belongonthespectrum.web.app/) loads Belong.
- [ ] Guest / Demo versus signed-in paths behave as expected for QA.
- [ ] Note DEV versus production flavor differences so they are not filed as bugs.
- [ ] Hand testers a short “how to drive the dev site” note.

### E. Support and safety on production

Verify on the production host. [#765](https://github.com/neiljaywarner/refuge/issues/765) records related merges already on `main` (#756, #752, #759, and the Giphy base in #715). This checklist does not re-verify them.

- [ ] About / help points at **Vote & Feedback only** (no branded support email) — #495 / #752.
- [ ] Ban / lockout path is present after #759.
- [ ] Email-verify banner soft-gate messaging is present after #756.

## Explicitly later

App Store / Play public listing, a full TestFlight matrix, iOS APNs device verification, public Google/Apple 1-tap as the default, Maestro suite cleanup beyond smoke, and Circle CSV re-import polish.
