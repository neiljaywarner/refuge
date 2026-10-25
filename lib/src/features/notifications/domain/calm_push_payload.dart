import 'package:equatable/equatable.dart';

/// User-visible text for a calm push or local shade notification.
class const CalmPushDisplay(final String title, final String body, final String? category)
    extends Equatable {
  @override
  List<Object?> get props => [title, body, category];
}

/// Builds display text from FCM notification and/or data payloads.
CalmPushDisplay calmPushDisplayFromParts({
  String? notificationTitle,
  String? notificationBody,
  Map<String, dynamic>? data,
}) {
  final map = data ?? const <String, dynamic>{};
  final title =
      _firstNonEmpty([notificationTitle, map['title']?.toString(), map['subject']?.toString()]) ??
      'Belong';

  final body =
      _firstNonEmpty([
        notificationBody,
        map['body']?.toString(),
        map['snippet']?.toString(),
        map['message']?.toString(),
      ]) ??
      'A fellow member sent you a calm update.';

  final category = map['category']?.toString();

  return CalmPushDisplay(title, body, category);
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}
