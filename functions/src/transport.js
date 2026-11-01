'use strict';

/**
 * Parse the DM_EMAIL_TRANSPORT_JSON secret.
 *
 * The value is an HTTPS endpoint, an API key, and a From address.
 * A missing or unreadable secret means the function does not send.
 * Never log the parsed key.
 *
 * @param {string} raw
 * @returns {{ endpoint: string, apiKey: string, from: string } | null}
 */
function parseEmailTransport(raw) {
  if (typeof raw !== 'string' || !raw.trim()) return null;
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (_) {
    return null;
  }
  if (!parsed || typeof parsed !== 'object') return null;
  const endpoint = typeof parsed.endpoint === 'string' ? parsed.endpoint.trim() : '';
  const apiKey = typeof parsed.apiKey === 'string' ? parsed.apiKey.trim() : '';
  const from = typeof parsed.from === 'string' ? parsed.from.trim() : '';
  let endpointUrl;
  try {
    endpointUrl = new URL(endpoint);
  } catch (_) {
    return null;
  }
  if (endpointUrl.protocol !== 'https:' || !apiKey || !from || from.includes('\n')) return null;
  return { endpoint, apiKey, from };
}

module.exports = {
  parseEmailTransport,
};
