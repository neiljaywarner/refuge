import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';

import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, increment, setDoc, updateDoc } from 'firebase/firestore';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const rules = readFileSync(resolve(root, 'firestore.rules'), 'utf8');

const member = { firebase: { sign_in_provider: 'password' } };
const anonymous = { firebase: { sign_in_provider: 'anonymous' } };

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'belong-rules-ban',
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'rules_admins/admin-uid'), { seeded: true });
    await setDoc(doc(db, 'banned_uids/banned-uid'), {
      uid: 'banned-uid',
      banned: true,
      displayName: 'Fellow Member',
    });
    await setDoc(doc(db, 'reflections/post-1'), {
      authorId: 'member-uid',
      authorName: 'Fellow Member',
      content: 'A quiet note',
      spaceKey: 'prayer',
    });
    await setDoc(doc(db, 'direct_messages/dm-1'), {
      senderId: 'member-uid',
      senderName: 'Fellow Member',
      participantIds: ['member-uid', 'other-uid'],
      content: 'Private note',
    });
    await setDoc(doc(db, 'users/member-uid/sent_message_ids/dm-1'), {
      messageId: 'dm-1',
      senderId: 'member-uid',
    });
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

function dbFor(uid, token) {
  return testEnv.authenticatedContext(uid, token).firestore();
}

describe('firestore ban rules', () => {
  test('a guest cannot read a reflection', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'reflections/post-1')));
  });

  test('an anonymous session cannot read a reflection', async () => {
    const db = dbFor('anon-uid', anonymous);
    await assertFails(getDoc(doc(db, 'reflections/post-1')));
  });

  test('a member can read a reflection', async () => {
    const db = dbFor('member-uid', member);
    await assertSucceeds(getDoc(doc(db, 'reflections/post-1')));
  });

  test('a banned uid cannot read a reflection', async () => {
    const db = dbFor('banned-uid', member);
    await assertFails(getDoc(doc(db, 'reflections/post-1')));
  });

  test('a non-participant cannot read a direct message', async () => {
    const db = dbFor('stranger-uid', member);
    await assertFails(getDoc(doc(db, 'direct_messages/dm-1')));
  });

  test('a participant can read their direct message', async () => {
    const db = dbFor('other-uid', member);
    await assertSucceeds(getDoc(doc(db, 'direct_messages/dm-1')));
  });

  test('a rules admin can read the id-only sent-message index', async () => {
    const db = dbFor('admin-uid', member);
    await assertSucceeds(getDoc(doc(db, 'users/member-uid/sent_message_ids/dm-1')));
  });

  test('another member cannot read that index', async () => {
    const db = dbFor('stranger-uid', member);
    await assertFails(getDoc(doc(db, 'users/member-uid/sent_message_ids/dm-1')));
  });

  test('a member cannot ban themselves', async () => {
    const db = dbFor('member-uid', member);
    await assertFails(
      setDoc(doc(db, 'banned_uids/member-uid'), {
        uid: 'member-uid',
        banned: true,
        displayName: 'Fellow Member',
      }),
    );
  });

  test('a non-author can lower a reaction count without lowering the summary column', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'reflections/post-react'), {
        authorId: 'member-uid',
        authorName: 'Fellow Member',
        content: 'A quiet note',
        spaceKey: 'prayer',
        prayingCount: 1,
        reactions: { pray: 1 },
      });
    });
    const db = dbFor('other-uid', member);
    await assertSucceeds(
      updateDoc(doc(db, 'reflections/post-react'), {
        'reactions.pray': increment(-1),
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'reflections/post-react'), {
        prayingCount: increment(-1),
        'reactions.pray': increment(-1),
      }),
    );
  });

  test('a member can record their own care reaction and another member cannot', async () => {
    const owner = dbFor('member-uid', member);
    await assertSucceeds(
      setDoc(doc(owner, 'users/member-uid/care_reactions/dev_post-react'), {
        types: ['relatable'],
      }),
    );
    const stranger = dbFor('stranger-uid', member);
    await assertFails(getDoc(doc(stranger, 'users/member-uid/care_reactions/dev_post-react')));
  });

  test('a rules admin can record a uid ban', async () => {
    const db = dbFor('admin-uid', member);
    await assertSucceeds(
      setDoc(doc(db, 'banned_uids/other-target'), {
        uid: 'other-target',
        banned: true,
        displayName: 'Sarah K.',
      }),
    );
  });
});
