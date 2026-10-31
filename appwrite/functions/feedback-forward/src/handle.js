'use strict';

/**
 * File one stored member_feedback note as a private GitHub issue.
 *
 * `main.js` supplies `deps`. Tests supply fakes. The request body is not
 * trusted for the note text: this reads the Firestore document.
 */

const { formatFeedbackIssue, labelSpec } = require('./format');

const firebaseProjectId = 'belongonthespectrum';
const feedbackCollection = 'member_feedback';
const feedbackIdPattern = /^[A-Za-z0-9_-]{1,128}$/;

/**
 * @param {object} body
 * @param {object} deps
 */
async function handleFeedbackForward(body, deps) {
  const feedbackId = body && typeof body.feedbackId === 'string' ? body.feedbackId.trim() : '';
  if (!feedbackIdPattern.test(feedbackId)) {
    return { status: 400, body: { error: 'missing feedback' } };
  }

  let claims;
  try {
    claims = await deps.verifyIdToken(body.idToken);
  } catch (_) {
    return { status: 401, body: { error: 'unauthorized' } };
  }
  const uid = claims && (claims.sub || claims.user_id);
  if (!uid) return { status: 401, body: { error: 'missing member' } };

  const doc = await deps.readFeedback(feedbackId);
  if (!doc) return { status: 404, body: { error: 'feedback not readable' } };
  if (doc.userId !== uid && doc.authorId !== uid) {
    return { status: 403, body: { error: 'not the author' } };
  }
  if (!doc.isPrivateTriage) {
    return { status: 200, body: { forwarded: false, reason: 'not private triage' } };
  }

  const existing = filedIssue(doc);
  if (existing) {
    return {
      status: 200,
      body: {
        forwarded: true,
        idempotent: true,
        githubIssueNumber: existing.number,
        githubIssueUrl: existing.htmlUrl,
      },
    };
  }

  if (!deps.canCreateIssue) {
    return {
      status: 200,
      body: { forwarded: false, reason: 'github credential is not configured' },
    };
  }

  const payload = formatFeedbackIssue(doc, feedbackId);
  for (const label of payload.labels) {
    await deps.ensureLabel(labelSpec(label));
  }
  const created = await deps.createIssue({
    repository: payload.repository,
    title: payload.title,
    body: payload.body,
    labels: payload.labels,
  });
  const number = created && created.number;
  if (!Number.isInteger(number) || number <= 0) {
    return { status: 502, body: { error: 'github issue was not created' } };
  }
  const htmlUrl = (created && created.htmlUrl) || issueUrl(number);

  let persisted = false;
  try {
    await deps.updateFeedback(feedbackId, {
      githubIssueCreated: true,
      githubIssueNumber: number,
      githubIssueUrl: htmlUrl,
    });
    persisted = true;
  } catch (_) {
    persisted = false;
  }

  return {
    status: 200,
    body: {
      forwarded: true,
      idempotent: false,
      persisted,
      githubIssueNumber: number,
      githubIssueUrl: htmlUrl,
    },
  };
}

function filedIssue(doc) {
  const number = doc && doc.githubIssueNumber;
  if (!Number.isInteger(number) || number <= 0) return null;
  const htmlUrl =
    doc.githubIssueUrl && String(doc.githubIssueUrl).trim()
      ? String(doc.githubIssueUrl).trim()
      : issueUrl(number);
  return { number, htmlUrl };
}

function issueUrl(number) {
  return `https://github.com/neiljaywarner/belong_feedback/issues/${number}`;
}

function firestoreString(field) {
  return field && typeof field.stringValue === 'string' ? field.stringValue : '';
}

function firestoreBool(field) {
  if (!field || typeof field.booleanValue !== 'boolean') return null;
  return field.booleanValue === true;
}

function firestoreInt(field) {
  if (!field || field.integerValue == null) return null;
  const parsed = Number(field.integerValue);
  return Number.isInteger(parsed) ? parsed : null;
}

function firestoreTimestamp(field) {
  return field && typeof field.timestampValue === 'string' ? field.timestampValue : '';
}

function feedbackFromFirestoreDocument(doc) {
  const fields = (doc && doc.fields) || {};
  const sentiment = firestoreString(fields.sentiment);
  const explicitPrivate = firestoreBool(fields.isPrivateTriage);
  const submittedAt = firestoreString(fields.submittedAt) || firestoreTimestamp(fields.createdAt);
  return {
    userId: firestoreString(fields.userId),
    authorId: firestoreString(fields.authorId),
    sentiment,
    message: firestoreString(fields.message),
    contactEmail: firestoreString(fields.contactEmail),
    attachmentUrl: firestoreString(fields.attachmentUrl),
    attachmentBytesBase64: firestoreString(fields.attachmentBytesBase64),
    sourceEnvironment: firestoreString(fields.sourceEnvironment),
    sourceHost: firestoreString(fields.sourceHost),
    sourceUrl: firestoreString(fields.sourceUrl),
    submittedAt,
    isPrivateTriage:
      explicitPrivate == null ? sentiment === 'sad' || sentiment === 'neutral' : explicitPrivate,
    githubIssueCreated: firestoreBool(fields.githubIssueCreated) === true,
    githubIssueNumber: firestoreInt(fields.githubIssueNumber),
    githubIssueUrl: firestoreString(fields.githubIssueUrl),
  };
}

module.exports = {
  handleFeedbackForward,
  feedbackFromFirestoreDocument,
  firebaseProjectId,
  feedbackCollection,
  feedbackIdPattern,
};
