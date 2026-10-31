import '../../reflections/domain/post.dart';

/// When search matches [Post.toneTag] or [Post.specialInterestTag] but not visible
/// body or author text, return a calm affordance label for the result row (#697).
String? communitySearchMatchedTagLabel({required Post post, required String query}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return null;

  final bodyMatches = post.content.toLowerCase().contains(normalized);
  final authorMatches = post.authorName.toLowerCase().contains(normalized);
  if (bodyMatches || authorMatches) return null;

  if (post.toneTag.toLowerCase().contains(normalized)) {
    return 'Matched tag: ${_displayTag(post.toneTag)}';
  }
  final interest = post.specialInterestTag;
  if (interest != null && interest.toLowerCase().contains(normalized)) {
    return 'Matched tag: $interest';
  }
  return null;
}

String _displayTag(String toneTag) {
  var label = toneTag.trim();
  if (label.startsWith('[') && label.endsWith(']') && label.length > 2) {
    label = label.substring(1, label.length - 1);
  }
  return label;
}

/// True when [post] should appear for a non-empty [query] (same rules as feed search).
bool communitySearchPostMatches({required Post post, required String query}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return post.content.toLowerCase().contains(normalized) ||
      post.authorName.toLowerCase().contains(normalized) ||
      post.toneTag.toLowerCase().contains(normalized) ||
      (post.specialInterestTag?.toLowerCase().contains(normalized) ?? false);
}
