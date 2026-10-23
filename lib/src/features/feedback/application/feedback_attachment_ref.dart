/// How a feedback drawing is referenced after the member taps send.
///
/// Cloud Storage is not connected. A drawing kept for an organizer handoff
/// must not be described as a file at `storage.belongonthespectrum.com`.
abstract final class FeedbackAttachmentRef {
  /// Host returned by the in-memory storage stub. It does not store bytes.
  static const stubHost = 'storage.belongonthespectrum.com';

  /// Prefix for a drawing kept with the note. Not an https download URL.
  static const localPrefix = 'local-handoff:feedback/attachments/';

  static String localHandoff(String filename) => '$localPrefix$filename';

  /// True only for an https URL whose host is present and is not [stubHost].
  static bool isHostedUpload(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed.startsWith(localPrefix)) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    if (uri.host == stubHost) return false;
    return true;
  }
}
