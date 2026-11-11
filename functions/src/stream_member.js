'use strict';

const SIGN_IN_REQUIRED = 'Sign in is required.';
const ACCOUNT_BLOCKED = 'This account cannot join a call.';

/**
 * Firebase uid from a verified ID token.
 * Anonymous sign-in is not a member, matching `isSignedInMember` in
 * firestore.rules. A token with no provider still counts: unit fixtures
 * only set `uid`, and email/password tokens from the Admin SDK include
 * a non-anonymous provider.
 */
function memberUserId(decoded) {
  const userId = decoded && typeof decoded.uid === 'string' ? decoded.uid.trim() : '';
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(userId)) return '';
  const firebase = decoded.firebase;
  const provider =
    firebase && typeof firebase.sign_in_provider === 'string' ? firebase.sign_in_provider : '';
  if (provider === 'anonymous') return '';
  return userId;
}

/**
 * Same standing records as `uidBanActive` in firestore.rules.
 * `banned_uids/{uid}.banned` and a matching `soft_deleted_users/{uid}` row.
 * The Admin SDK reads them. Clients cannot.
 */
async function memberBanActive(db, uid) {
  const banned = await db.collection('banned_uids').doc(uid).get();
  if (banned.exists && banned.data() && banned.data().banned === true) return true;
  const soft = await db.collection('soft_deleted_users').doc(uid).get();
  if (!soft.exists) return false;
  const data = soft.data() || {};
  return data.softDeleted === true && data.userId === uid;
}

/**
 * Signed-in member gate for minting a token or creating an invite.
 * Missing `banActive` skips the ban read so older unit fixtures keep working.
 * Production always passes `banActive`. A throw fails closed.
 */
async function decideMember(req, deps) {
  const header = req.headers.authorization || '';
  const match = /^Bearer\s+(\S+)$/.exec(header);
  if (!match) return refused(401, 'auth', SIGN_IN_REQUIRED);
  let decoded;
  try {
    decoded = await deps.verifyIdToken(match[1]);
  } catch (_) {
    return refused(401, 'auth', SIGN_IN_REQUIRED);
  }
  const userId = memberUserId(decoded);
  if (!userId) return refused(401, 'auth', SIGN_IN_REQUIRED);
  if (typeof deps.banActive !== 'function') return { ok: true, userId };
  try {
    if (await deps.banActive(userId)) return refused(403, 'forbidden', ACCOUNT_BLOCKED);
  } catch (_) {
    return refused(403, 'forbidden', ACCOUNT_BLOCKED);
  }
  return { ok: true, userId };
}

function refused(status, code, error) {
  return { ok: false, status, code, error };
}

module.exports = {
  SIGN_IN_REQUIRED,
  ACCOUNT_BLOCKED,
  memberUserId,
  memberBanActive,
  decideMember,
};
