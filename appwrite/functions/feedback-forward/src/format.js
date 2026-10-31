'use strict';

/**
 * Issue text for neiljaywarner/belong_feedback.
 *
 * This is the JavaScript copy of PrivateFeedbackRouter.formatPrivateIssue.
 * The phone does not send the title or the body. The function builds both
 * from the stored Firestore document.
 *
 * Preview and production share one private repo, so a non-production note
 * is prefixed and labeled. Unknown environments are treated as preview so
 * they cannot look like production.
 */

const repository = 'neiljaywarner/belong_feedback';
const maxGitHubIssueBodyLength = 65536;
const maxDuplicateBase64Length = 28000;
const maxSingleInlineBase64Length = 60000;

const sentiments = {
  sad: {
    label: 'Bug / Confusing',
    emoji: '🛠️',
    subtitle: 'Private Triage',
    issueLabel: 'bug-report',
  },
  neutral: {
    label: 'Idea / Tweak',
    emoji: '💡',
    subtitle: 'Private Suggestion',
    issueLabel: 'community-idea',
  },
  happy: {
    label: 'Works Great',
    emoji: '💚',
    subtitle: 'Public Praise',
    issueLabel: 'praise',
  },
};

const labelColors = {
  'user-feedback': '0e8a16',
  'bug-report': 'd73a4a',
  'community-idea': 'a2eeef',
  praise: 'bfdadc',
  preview: 'fbca04',
  dev: 'c5def5',
  local: 'd4c5f9',
};

function normalizeEnvironment(value) {
  const env = String(value || '').trim().toLowerCase();
  if (env === 'production' || env === 'preview' || env === 'dev' || env === 'local') {
    return env;
  }
  return 'preview';
}

function environmentPrefix(sourceEnvironment) {
  const env = normalizeEnvironment(sourceEnvironment);
  if (env === 'production') return '';
  return `[${env}] `;
}

function environmentLabels(sourceEnvironment) {
  const env = normalizeEnvironment(sourceEnvironment);
  if (env === 'production') return [];
  return [env];
}

function labelSpec(name) {
  return {
    name,
    color: labelColors[name] || 'ededed',
    description: 'Belong member feedback',
  };
}

function formatFeedbackIssue(doc, feedbackId) {
  const note = normalizeNote(doc);
  let body = renderBody(note, feedbackId, true);
  if (body.length > maxGitHubIssueBodyLength) {
    body = renderBody(note, feedbackId, false);
  }
  if (body.length > maxGitHubIssueBodyLength) {
    const marker = '\n\n[truncated to fit the GitHub issue body limit]';
    body = body.slice(0, maxGitHubIssueBodyLength - marker.length) + marker;
  }
  return {
    repository,
    title: renderTitle(note),
    body,
    labels: renderLabels(note),
    environment: note.environment,
  };
}

function normalizeNote(doc) {
  const source = doc || {};
  const sentimentKey = typeof source.sentiment === 'string' ? source.sentiment : '';
  const sentiment = sentiments[sentimentKey] || {
    label: 'Feedback',
    emoji: '📝',
    subtitle: 'Private Triage',
    issueLabel: 'user-feedback',
  };
  const message = String(source.message || '').trim();
  const firstLine = message.split('\n')[0] || 'Member note';
  const environment = normalizeEnvironment(source.sourceEnvironment);
  return {
    sentiment,
    message,
    firstLine,
    environment,
    host: String(source.sourceHost || '').trim() || 'unknown host',
    sourceUrl: String(source.sourceUrl || '').trim() || 'unknown',
    submittedAt: String(source.submittedAt || '').trim() || new Date().toISOString(),
    contactEmail: String(source.contactEmail || '').trim(),
    attachmentBytesBase64: String(source.attachmentBytesBase64 || '').trim(),
    attachmentUrl: String(source.attachmentUrl || '').trim(),
  };
}

function renderTitle(note) {
  const truncated =
    note.firstLine.length > 60 ? `${note.firstLine.slice(0, 57)}...` : note.firstLine;
  return `${environmentPrefix(note.environment)}[${note.sentiment.label}] ${truncated}`;
}

function renderLabels(note) {
  const labels = ['user-feedback'];
  if (note.sentiment.issueLabel !== 'user-feedback') labels.push(note.sentiment.issueLabel);
  for (const extra of environmentLabels(note.environment)) {
    if (!labels.includes(extra)) labels.push(extra);
  }
  return labels;
}

function renderBody(note, feedbackId, includeImage) {
  const lines = [
    '## Community Feedback Submission',
    '',
    `- **Intent**: ${note.sentiment.emoji} **${note.sentiment.label}** (${note.sentiment.subtitle})`,
    `- **Submitted At**: \`${note.submittedAt}\``,
    `- **Target Triage Repo**: \`${repository}\``,
    `- **Source environment**: \`${note.environment}\` (\`${note.host}\`)`,
    `- **Source URL**: \`${note.sourceUrl}\``,
  ];
  if (feedbackId) {
    lines.push(`- **Feedback document**: \`member_feedback/${feedbackId}\``);
  }
  if (note.contactEmail) {
    lines.push(`- **Contact Info**: \`${note.contactEmail}\``);
  }
  const attachment = attachmentLines(note, includeImage);
  if (attachment.length > 0) {
    lines.push('', ...attachment);
  }
  lines.push('', '### Feedback Note', note.message);
  return lines.join('\n');
}

function attachmentLines(note, includeImage) {
  const bytes = note.attachmentBytesBase64;
  if (bytes) {
    const section = ['### Annotated Screenshot / Scribble Attachment'];
    const inline = includeImage && bytes.length <= maxSingleInlineBase64Length;
    if (inline && bytes.length <= maxDuplicateBase64Length) {
      section.push(
        `<img src="data:image/png;base64,${bytes}" alt="Annotated Screenshot" width="400" />`,
        '',
        '<details><summary>Raw Base64 PNG</summary>',
        '',
        '```',
        bytes,
        '```',
        '</details>',
      );
    } else if (inline) {
      section.push(
        `<img src="data:image/png;base64,${bytes}" alt="Annotated Screenshot" width="400" />`,
      );
    } else {
      const kb = ((bytes.length * 3) / 4 / 1024).toFixed(1);
      section.push(
        `Annotated screenshot (${kb} KB PNG) exceeded GitHub inline 65 KB issue body limit ` +
          'and is stored in Firestore `member_feedback`.',
      );
    }
    return section;
  }
  const url = note.attachmentUrl;
  if (!url) return [];
  const hosted = url.startsWith('https://') && !url.includes('storage.belongonthespectrum.com');
  return [
    '### Annotated Screenshot / Scribble Attachment',
    hosted
      ? `![Annotated Screenshot](${url})`
      : 'A drawing was kept with this note for an organizer handoff. ' +
        'It was not uploaded, and this text is not a download link.',
  ];
}

module.exports = {
  repository,
  maxGitHubIssueBodyLength,
  normalizeEnvironment,
  environmentPrefix,
  environmentLabels,
  labelSpec,
  formatFeedbackIssue,
};
