'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  formatFeedbackIssue,
  maxGitHubIssueBodyLength,
  normalizeEnvironment,
  environmentPrefix,
  environmentLabels,
} = require('../src/format');

const previewHost = 'belongonthespectrum--feedback-659-abc.web.app';

function note(overrides) {
  return {
    sentiment: 'sad',
    message: 'The quiet digest banner overflows on a narrow phone.',
    contactEmail: 'member@belongonthespectrum.com',
    sourceEnvironment: 'production',
    sourceHost: 'belongonthespectrum.web.app',
    sourceUrl: 'https://belongonthespectrum.web.app',
    submittedAt: '2026-10-31T16:00:00.000Z',
    ...overrides,
  };
}

test('preview notes are prefixed, labeled, and name the host', () => {
  const issue = formatFeedbackIssue(
    note({
      sourceEnvironment: 'preview',
      sourceHost: previewHost,
      sourceUrl: `https://${previewHost}`,
    }),
    'feedbackDoc1',
  );

  assert.equal(issue.environment, 'preview');
  assert.equal(issue.title.startsWith('[preview] '), true);
  assert.equal(issue.title.includes('[Bug / Confusing]'), true);
  assert.equal(issue.labels.includes('preview'), true);
  assert.equal(issue.labels.includes('bug-report'), true);
  assert.equal(issue.labels.includes('user-feedback'), true);
  assert.match(issue.body, /\*\*Source environment\*\*: `preview`/);
  assert.match(issue.body, new RegExp(previewHost.replaceAll('.', '\\.')));
  assert.match(issue.body, /member_feedback\/feedbackDoc1/);
  assert.match(issue.body, /member@belongonthespectrum.com/);
});

test('production notes stay unprefixed and unlabeled as preview', () => {
  const issue = formatFeedbackIssue(note(), 'feedbackDoc2');
  assert.equal(issue.title.startsWith('['), true);
  assert.equal(issue.title.startsWith('[preview]'), false);
  assert.equal(issue.title.startsWith('[Bug / Confusing]'), true);
  assert.equal(issue.labels.includes('preview'), false);
  assert.equal(issue.labels.includes('dev'), false);
  assert.equal(issue.labels.includes('local'), false);
  assert.match(issue.body, /\*\*Source environment\*\*: `production`/);
  assert.match(issue.body, /belongonthespectrum\.web\.app/);
});

test('dev and local notes get their own prefix and label', () => {
  const dev = formatFeedbackIssue(note({ sourceEnvironment: 'dev', sourceHost: 'dev-belongonthespectrum.web.app' }), 'd1');
  assert.equal(dev.title.startsWith('[dev] '), true);
  assert.deepEqual(environmentLabels('dev'), ['dev']);

  const local = formatFeedbackIssue(note({ sourceEnvironment: 'local', sourceHost: 'localhost' }), 'd2');
  assert.equal(local.title.startsWith('[local] '), true);
  assert.deepEqual(environmentLabels('local'), ['local']);
});

test('an unknown environment is filed as preview', () => {
  assert.equal(normalizeEnvironment(''), 'preview');
  assert.equal(normalizeEnvironment('staging'), 'preview');
  assert.equal(environmentPrefix('staging'), '[preview] ');
  const issue = formatFeedbackIssue(note({ sourceEnvironment: 'staging' }), 'd3');
  assert.equal(issue.title.startsWith('[preview] '), true);
  assert.equal(issue.labels.includes('preview'), true);
  assert.match(issue.body, /\*\*Source environment\*\*: `preview`/);
});

test('a large scribble stays out of the issue body', () => {
  const issue = formatFeedbackIssue(
    note({ attachmentBytesBase64: 'A'.repeat(70000) }),
    'd4',
  );
  assert.equal(issue.body.length <= maxGitHubIssueBodyLength, true);
  assert.equal(issue.body.includes('<img src="data:image/png;base64,'), false);
  assert.match(issue.body, /exceeded GitHub inline 65 KB issue body limit/);
  assert.match(issue.body, /\*\*Source environment\*\*/);
});

test('a short scribble is inlined and a huge note is truncated', () => {
  const inlined = formatFeedbackIssue(note({ attachmentBytesBase64: 'abcd' }), 'd5');
  assert.match(inlined.body, /<img src="data:image\/png;base64,abcd"/);
  assert.match(inlined.body, /<details><summary>Raw Base64 PNG<\/summary>/);

  const huge = formatFeedbackIssue(note({ message: 'm'.repeat(70000) }), 'd6');
  assert.equal(huge.body.length <= maxGitHubIssueBodyLength, true);
  assert.match(huge.body, /truncated to fit the GitHub issue body limit/);
  assert.match(huge.body, /\*\*Source environment\*\*: `production`/);
});
