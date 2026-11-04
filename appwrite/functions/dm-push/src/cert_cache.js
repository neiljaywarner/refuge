'use strict';

/**
 * Cache for Google's Firebase ID token signing certificates (#811).
 *
 * Google rotates these keys. Its response carries `Cache-Control: max-age`.
 * Keys are kept until that age passes. A token whose `kid` is missing gets
 * one forced refetch with cooldown, so a rotation does not lock every caller
 * out until the function cold-starts.
 *
 * `fetchImpl` and `now` are injectable so tests never touch the network.
 * This file is duplicated in dm-mirror because each function deploys alone.
 */

const defaultCertUrl =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

/** Fallback lifetime when the response has no usable max-age. */
const defaultMaxAgeMs = 60 * 60 * 1000;

/** Minimum interval between forced refetches for unknown kid values. */
const defaultUnknownKidCooldownMs = 60 * 1000;

/**
 * Reads `max-age` seconds from a Cache-Control header value.
 * Returns null when it is absent or not a non-negative integer.
 */
function maxAgeSeconds(cacheControl) {
  if (typeof cacheControl !== 'string') return null;
  const match = /(?:^|[,\s])max-age=(\d+)(?=\s*(?:,|$))/i.exec(cacheControl);
  if (!match) return null;
  const seconds = Number.parseInt(match[1], 10);
  return seconds >= 0 ? seconds : null;
}

function createCertCache({
  fetchImpl = (url) => fetch(url),
  now = () => Date.now(),
  certUrl = defaultCertUrl,
  unknownKidCooldownMs = defaultUnknownKidCooldownMs,
} = {}) {
  let certs = null;
  let expiresAt = 0;
  let inFlight = null;
  let lastUnknownKidRefreshAt = 0;

  async function load() {
    if (!inFlight) {
      inFlight = (async () => {
        const response = await fetchImpl(certUrl);
        if (!response.ok) throw new Error('could not load token certificates');
        const header = response.headers && response.headers.get
          ? response.headers.get('cache-control')
          : null;
        const seconds = maxAgeSeconds(header);
        certs = await response.json();
        const noStore = typeof header === 'string' && /(?:^|[,\s])no-store(?:$|[,\s])/i.test(header);
        expiresAt = noStore ? 0 : now() + (seconds === null ? defaultMaxAgeMs : seconds * 1000);
      })().finally(() => {
        inFlight = null;
      });
    }
    return inFlight;
  }

  /** Returns the PEM certificate for `kid`, or throws `unknown token key`. */
  async function certificateFor(kid) {
    if (!certs || now() >= expiresAt) await load();
    if (certs && certs[kid]) return certs[kid];

    // Key rotation: forced refresh with cooldown to avoid unthrottled upstream Google fetches
    if (now() - lastUnknownKidRefreshAt >= unknownKidCooldownMs) {
      lastUnknownKidRefreshAt = now();
      await load();
      if (certs && certs[kid]) return certs[kid];
    }
    throw new Error('unknown token key');
  }

  return { certificateFor };
}

module.exports = {
  createCertCache,
  maxAgeSeconds,
  defaultMaxAgeMs,
  defaultUnknownKidCooldownMs,
};
