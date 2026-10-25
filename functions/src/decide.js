'use strict';

/// Same rule as direct_message_push_policy.dart. Opt-in, not muted, real token.
function shouldSendDirectMessagePush(prefs) {
  if (!prefs || prefs.enabled !== true) return false;
  if (prefs.schedule === 'muted') return false;
  const token = typeof prefs.fcmToken === 'string' ? prefs.fcmToken.trim() : '';
  if (!token || token.startsWith('fcm_token_calm')) return false;
  return true;
}

function directMessagePushBody(senderName, content) {
  const name = (senderName || '').trim() || 'Fellow Member';
  const snippet = (content || '').trim();
  if (!snippet) return `${name} sent you a direct message`;
  const short = snippet.length <= 80 ? snippet : snippet.slice(0, 80);
  return `${name} sent you a direct message: "${short}"`;
}

const directMessageChannelId = 'direct_messages';
const quietDigestChannelId = 'calm_digest_channel_v2';

/// Standard Android notification unless the member picked the quiet schedule.
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
