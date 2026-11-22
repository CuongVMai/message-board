// SPICE #2: automated Firestore security-rules tests.
// Runs against the Firestore EMULATOR only (never the real database).
// Run from the project root:
//   firebase emulators:exec --only firestore --project message-board-c2f59 "npm --prefix rules_tests test"

import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'message-board-c2f59',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await env.cleanup();
});

// Fresh data before every test: one message owned by "alice".
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'messages/m1'), {
      text: 'hello from alice',
      authorUid: 'alice',
      authorName: 'Alice Test',
      createdAt: new Date(),
    });
  });
});

test('1. signed-out read is DENIED', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'messages/m1')));
});

test('2. cross-uid update is DENIED (bob edits alice\'s message)', async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(
    updateDoc(doc(db, 'messages/m1'), {
      text: 'hacked',
      editedAt: serverTimestamp(),
    }),
  );
});

test('2b. cross-uid delete is DENIED (bob deletes alice\'s message)', async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(deleteDoc(doc(db, 'messages/m1')));
});

test('3. forged authorUid create is DENIED (bob posts as alice)', async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(
    setDoc(doc(db, 'messages/forged'), {
      text: 'forged post',
      authorUid: 'alice',
      authorName: 'Alice Test',
      createdAt: serverTimestamp(),
    }),
  );
});

test('4. correct author can create, read, update, and delete', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const ref = doc(db, 'messages/m2');
  await assertSucceeds(
    setDoc(ref, {
      text: 'my own post',
      authorUid: 'alice',
      authorName: 'Alice Test',
      createdAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(
    updateDoc(ref, { text: 'my edited post', editedAt: serverTimestamp() }),
  );
  await assertSucceeds(deleteDoc(ref));
});
