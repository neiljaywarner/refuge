/// Public FCM topic for calm digest previews and QA demos (#382, #411).
///
/// Not a secret — devices opt in by subscribing after the member grants push.
const kCalmFcmPreviewTopic = 'belong_calm_digest_preview';

/// Android notification channel for silent calm digests (ADR-0010).
const kCalmDigestNotificationChannelId = 'calm_digest_channel';
