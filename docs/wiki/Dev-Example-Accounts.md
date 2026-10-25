# Dev example accounts (organizers & testers)

*Last updated: October 24, 2026*

Use this page when you drive the **dev** flavor of Belong on **Android** (`com.belongonthespectrum.refuge.dev`) or **web** at [https://dev-belongonthespectrum.web.app/](https://dev-belongonthespectrum.web.app/). These shortcuts do **not** appear on production (`belongonthespectrum.web.app` or the production Android package).

Production still requires a normal sign-in and, when applicable, a verified email. Dev skips the verification wall so you can test faster.

---

## One-tap sign-in (dev Android & dev web)

On the sign-in wall, below the email form, you may see:

- **Tap here to use Example User 1**
- **Tap here to use Example User 2**

They work only when the app was built with a **`DEV_EXAMPLE_PASSWORD`** dart-define. That value is **not** stored in this wiki or in git. Local VS Code launch configs read it from the same-named environment variable. Dev-web deploy (`tool/deploy_dev_web.dart`) forwards it from the environment when present. **Production builds must omit it** so the password never ships in a prod bundle. Never post that password in issues, PRs, or chat screenshots.

If the buttons are grayed out, the build is missing that define. You will see: *Dev example sign-in needs DEV_EXAMPLE_PASSWORD*.

---

## The two personas

Both accounts use public **yopmail** inboxes (anyone can read mail sent to those addresses). Use them only for **dev testing**, not for real fellowship identity or private conversation.

| Shortcut | Email | Display name | Role you are simulating |
| :--- | :--- | :--- | :--- |
| Example User 1 | `exampleuser1@yopmail.com` | **David M.** | Longtime **ICOC fellowship member** — prayer and quiet reflection; affiliated with **DFW Church (Partner)**; comfort cues include *Prayer requests welcome*. |
| Example User 2 | `exampleuser2@yopmail.com` | **Sarah K.** | **Welcoming visitor / newcomer** — exploring at a sensory-friendly pace; not an ICOC member; comfort cues include *New here* and *Low sensory preferred*. |

After sign-in, open the **profile avatar** (top right) to confirm display name, bio, and church affiliation match the persona you expect.

### Inboxes (optional)

If you need password-reset or verification mail while testing production-like flows:

- [exampleuser1@yopmail.com inbox](https://yopmail.com/?login=exampleuser1)
- [exampleuser2@yopmail.com inbox](https://yopmail.com/?login=exampleuser2)

Treat anything in those inboxes as public.

---

## Creating or refreshing the accounts

Maintainers usually create both users **through the dev app** (Register on the sign-in wall, or the one-tap buttons after `DEV_EXAMPLE_PASSWORD` is set). They live in the same Firebase Authentication project as production packages, but dev builds do not block on email verification.

If a shortcut says the password does not match:

1. Confirm you are on a dev build with the correct `DEV_EXAMPLE_PASSWORD` define.
2. Use **Forgotten password?** in the app for that yopmail address, or ask a maintainer to reset the Auth user in the Firebase console.

Do not use these emails for real member data or PII.

---

## Related

- [Manual testing & UAT flows](Manual-Testing-and-UAT-Flows) — broader volunteer checklist
- [QA, device driving & beta testing](QA-and-Beta-Testing-Guide)
- GitHub: [Require sign-in, and verify email only in production](https://github.com/neiljaywarner/refuge/issues/574) / [PR #575](https://github.com/neiljaywarner/refuge/pull/575)
- GitHub: [Members-only data access](https://github.com/neiljaywarner/refuge/issues/601) — no guest browse, no anonymous Firebase
