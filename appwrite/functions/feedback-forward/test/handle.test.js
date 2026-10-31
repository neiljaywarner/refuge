'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  handleFeedbackForward,
  feedbackFromFirestoreDocument,
} = require('../src/handle');

const previewHost = 'belongonthespectrum--feedback-659-abc.web.app';

function sample(overrides) {
  return {
    userId: 'member-a',
    authorId: 'member-a',
    sentiment: 'sad',
    message: 'The quiet digest banner overflows.',
    contactEmail: '',
    isPrivateTriage: true,
    sourceEnvironment: 'preview',
    sourceHost: previewHost,
    sourceUrl: `https://${previewHost}`,
    submittedAt: '2026-10-31T16:00:00.000Z',
    githubIssueNumber: null,
    githubIssueUrl: '',
    ...overrides,
  };
}

function deps(overrides) {
  const calls = [];
  return {
    calls,
    verifyIdToken: async () => ({ sub: 'member-a', user_id: 'member-a' }),
    readFeedback: async () => sample(),
    canCreateIssue: true,
    ensureLabel: async (spec) => {
      calls.push(['label', spec.name]);
    },
    createIssue: async (payload) => {
      calls.push(['issue', payload]);
      return {
        number: 4,
        htmlUrl: 'https://github.com/neiljaywarner/belong_feedback/issues/4',
      };
    },
    updateFeedback: async (id, fields) => {
      calls.push(['update', id, fields]);
    },
    ...overrides,
  };
}

test('files the stored note and ignores a message on the request', async () => {
  const gate = deps();
  const result = await handleFeedbackForward(
    {
      feedbackId: 'feedbackDoc1',
      idToken: 'token',
      message: 'this text must be ignored',
      title: '[production] fake',
    },
    gate,
  );

  assert.equal(result.status, 200);
  assert.equal(result.body.forwarded, true);
  assert.equal(result.body.idempotent, false);
  assert.equal(result.body.persisted, true);
  assert.equal(result.body.githubIssueNumber, 4);
  const created = gate.calls.find((call) => call[0] === 'issue')[1];
  assert.equal(created.title.startsWith('[preview] '), true);
  assert.equal(created.body.includes('The quiet digest banner overflows.'), true);
  assert.equal(created.body.includes('this text must be ignored'), false);
  assert.equal(created.body.includes('**Source environment**: `preview`'), true);
  assert.equal(created.labels.includes('preview'), true);
  assert.equal(gate.calls.some((call) => call[0] === 'label' && call[1] === 'preview'), true);
  const update = gate.calls.find((call) => call[0] === 'update');
  assert.equal(update[1], 'feedbackDoc1');
  assert.equal(update[2].githubIssueCreated, true);
  assert.equal(update[2].githubIssueNumber, 4);
  assert.equal(
    update[2].githubIssueUrl,
    'https://github.com/neiljaywarner/belong_feedback/issues/4',
  );
});

test('production notes are not labeled preview', async () => {
  const gate = deps({
    readFeedback: async () =>
      sample({
        sourceEnvironment: 'production',
        sourceHost: 'belongonthespectrum.web.app',
        sourceUrl: 'https://belongonthespectrum.web.app',
      }),
  });
  await handleFeedbackForward({ feedbackId: 'feedbackDoc2', idToken: 'token' }, gate);
  const created = gate.calls.find((call) => call[0] === 'issue')[1];
  assert.equal(created.title.startsWith('[Bug / Confusing]'), true);
  assert.equal(created.title.startsWith('[preview]'), false);
  assert.equal(created.labels.includes('preview'), false);
  assert.equal(gate.calls.some((call) => call[0] === 'label' && call[1] === 'preview'), false);
});

test('an existing issue number is returned without creating another', async () => {
  const gate = deps({
    readFeedback: async () =>
      sample({
        githubIssueCreated: true,
        githubIssueNumber: 8,
        githubIssueUrl: 'https://github.com/neiljaywarner/belong_feedback/issues/8',
      }),
  });
  const result = await handleFeedbackForward({ feedbackId: 'feedbackDoc3', idToken: 'token' }, gate);
  assert.equal(result.body.idempotent, true);
  assert.equal(result.body.githubIssueNumber, 8);
  assert.equal(gate.calls.some((call) => call[0] === 'issue'), false);
  assert.equal(gate.calls.some((call) => call[0] === 'update'), false);
});

test('a missing credential does not create an issue', async () => {
  const gate = deps({ canCreateIssue: false });
  const result = await handleFeedbackForward({ feedbackId: 'feedbackDoc4', idToken: 'token' }, gate);
  assert.equal(result.body.forwarded, false);
  assert.equal(result.body.reason, 'github credential is not configured');
  assert.equal(gate.calls.length, 0);
});

test('public praise is not filed', async () => {
  const gate = deps({
    readFeedback: async () => sample({ sentiment: 'happy', isPrivateTriage: false }),
  });
  const result = await handleFeedbackForward({ feedbackId: 'feedbackDoc5', idToken: 'token' }, gate);
  assert.equal(result.body.reason, 'not private triage');
  assert.equal(gate.calls.length, 0);
});

test('another member cannot forward the note', async () => {
  const gate = deps({
    verifyIdToken: async () => ({ sub: 'member-b' }),
  });
  const result = await handleFeedbackForward({ feedbackId: 'feedbackDoc6', idToken: 'token' }, gate);
  assert.equal(result.status, 403);
  assert.equal(gate.calls.length, 0);
});

test('a rejected token is unauthorized and a bad id is rejected', async () => {
  const gate = deps({
    verifyIdToken: async () => {
      throw new Error('expired');
    },
  });
  const denied = await handleFeedbackForward({ feedbackId: 'feedbackDoc7', idToken: 'token' }, gate);
  assert.equal(denied.status, 401);

  const missing = await handleFeedbackForward({ feedbackId: '../posts', idToken: 'token' }, gate);
  assert.equal(missing.status, 400);
});

test('a failed Firestore patch still returns the new issue number', async () => {
  const gate = deps({
    updateFeedback: async () => {
      throw new Error('could not update feedback (403)');
    },
  });
  const result = await handleFeedbackForward({ feedbackId: 'feedbackDoc8', idToken: 'token' }, gate);
  assert.equal(result.body.forwarded, true);
  assert.equal(result.body.persisted, false);
  assert.equal(result.body.githubIssueNumber, 4);
});

test('firestore documents parse the fields the function files', () => {
  const parsed = feedbackFromFirestoreDocument({
    fields: {
      userId: { stringValue: 'member-a' },
      sentiment: { stringValue: 'neutral' },
      message: { stringValue: 'Please keep the digest quiet.' },
      isPrivateTriage: { booleanValue: true },
      sourceEnvironment: { stringValue: 'preview' },
      sourceHost: { stringValue: previewHost },
      sourceUrl: { stringValue: `https://${previewHost}` },
      submittedAt: { stringValue: '2026-10-31T16:00:00.000Z' },
      githubIssueCreated: { booleanValue: false },
      githubIssueNumber: { integerValue: '0' },
    },
  });
  assert.equal(parsed.userId, 'member-a');
  assert.equal(parsed.isPrivateTriage, true);
  assert.equal(parsed.sourceEnvironment, 'preview');
  assert.equal(parsed.githubIssueNumber, 0);
  assert.equal(parsed.submittedAt, '2026-10-31T16:00:00.000Z');
});
