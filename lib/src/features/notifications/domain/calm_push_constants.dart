/// Public FCM topic for calm digest previews and QA demos (#382, #411).
///
/// Not a secret — devices opt in by subscribing after the member grants push.
const kCalmFcmPreviewTopic = 'belong_calm_digest_preview';

/// Android notification channel for silent calm digests (ADR-0010).
const kCalmDigestNotificationChannelId = 'calm_digest_channel_v2';

/// Android 8+ channel for an ordinary direct-message notification.
///
/// A new id is required. The digest channel was created without sound, and
/// Android does not let an app turn sound on for a channel that already exists.
const kDirectMessageChannelId = 'direct_messages';
