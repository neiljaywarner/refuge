# Delete your account, and come back

A signed-in member can turn off their own sign-in. Posts stay. The member list hides them. This is not a full erase. Permanent deletion is still [an open decision](https://github.com/neiljaywarner/refuge/issues/545).

## What the member does

1. Open the profile and tap **Delete my account**.
2. Type `DELETE`.
3. Sign-in for that account turns off. The directory flag `listedInDirectory` is false.
4. To come back, sign in with the same email and password, then type `RESTORE`.

Only that member gets the return screen. It appears after the password is accepted, because that is the proof they still hold the account. **Stay deleted** signs them out again.

An organizer does not get a button that clears this. Unban applies to a community ban, which is a different record. Unban leaves a self-delete in place.

## What Circle does

Circle’s member action is **deactivation**, and only when an admin allows it. Posts stay. The member cannot rejoin from the public sign-up form. Circle tells them to ask an admin, who can re-invite them. A Circle **delete** is permanent and erases content. A deleted person who is invited again gets a new profile.

Belong’s default is different on purpose: the member who left is the one who comes back, by typing `RESTORE`. Whether an organizer should also be able to re-invite someone, and whether return should expire, is [needs an answer](https://github.com/neiljaywarner/refuge/issues/590).

## How this is tested

| Check | Where |
| --- | --- |
| Gherkin scenario (human-readable spec, not codegen) | `test/features/account_deletion/delete_and_return_account.feature` |
| Widget test, synthetic email with the current timestamp | `test/features/account_deletion/account_return_widget_test.dart` |
| Repository: delete, blocked sign-in, restore, admin unban does not clear it | `test/features/account_deletion/account_deletion_repository_test.dart` |
| Patrol integration | `integration_test/account_return_patrol_test.dart` |
| Maestro, dev package, opt-in | `.maestro/account_delete_and_return.yaml` |

The Maestro flow is tagged `known-gap`, so the default suite does not register an account. Pass `BELONG_AUTH_NAME`, `BELONG_AUTH_EMAIL`, and `BELONG_AUTH_PASSWORD`. Use a synthetic address such as `tester-<timestamp>@example.com` and the name Fellow Member.

Related: [#544](https://github.com/neiljaywarner/refuge/issues/544), [#581](https://github.com/neiljaywarner/refuge/issues/581), [#589](https://github.com/neiljaywarner/refuge/issues/589), [#590](https://github.com/neiljaywarner/refuge/issues/590).
