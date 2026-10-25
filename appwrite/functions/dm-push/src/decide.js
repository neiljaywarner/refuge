'use strict';

/**
 * Send rule for a direct-message notification.
 *
 * This file is the JavaScript copy of
 * lib/src/features/notifications/domain/direct_message_push_policy.dart.
 * Change both together. A push is sent only when alerts are on, the schedule
 * is not muted, and the token is a real device token.
 */

/**
 * @param {{ enabled?: boolean, schedule?: string, fcmToken?: string } | null} prefs
 * @returns {boolean}
 */
function shouldSendDirectMessagePush(prefs) {
  if (!prefs || prefs.enabled !== true) return false;
  if (prefs.schedule === 'muted') return false;
  const token = typeof prefs.fcmToken === 'string' ? prefs.fcmToken.trim() : '';
  if (!token || token.startsWith('fcm_token_calm')) return false;
  return true;
}

/**
 * Shade text. The snippet is at most 80 characters. An empty name becomes
 * "Fellow Member". Never put an email address in this string.
 *
 * @param {string} senderName
 * @param {string} content
 * @returns {string}
 */
function directMessagePushBody(senderName, content) {
  const name = (senderName || '').trim() || 'Fellow Member';
  const snippet = (content || '').trim();
  if (!snippet) return `${name} sent you a direct message`;
  const short = snippet.length <= 80 ? snippet : snippet.slice(0, 80);
  return `${name} sent you a direct message: "${short}"`;
}

const directMessageChannelId = 'direct_messages';
const quietDigestChannelId = 'calm_digest_channel_v2';

/**
 * Android delivery for one schedule.
 *
 * `immediateGentle` is the quiet extra: normal priority, no sound, channel
 * `calm_digest_channel_v2`. Every other on schedule uses high priority and
 * the `direct_messages` channel, which the app creates with sound.
 *
 * @param {string} schedule
 * @returns {{ priority: string, notification: Record<string, unknown> }}
 */
function directMessageAndroidConfig(schedule) {
  if (schedule === 'immediateGentle') {
    return {
      priority: 'NORMAL',
      notification: {
        channel_id: quietDigestChannelId,
        default_sound: false,
        default_vibrate_timings: false,
      },
    };
  }
  return {
    priority: 'HIGH',
    notification: {
      channel_id: directMessageChannelId,
    },
  };
}

module.exports = {
  shouldSendDirectMessagePush,
  directMessagePushBody,
  directMessageAndroidConfig,
  directMessageChannelId,
};
