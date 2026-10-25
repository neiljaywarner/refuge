import 'package:equatable/equatable.dart';

/// User-visible text for a calm push or local shade notification.
class CalmPushDisplay extends Equatable {
  const CalmPushDisplay({
    required this.title,
    required this.body,
    this.category,
  });

  final String title;
  final String body;
  final String? category;

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
      _firstNonEmpty([
        notificationTitle,
        map['title']?.toString(),
        map['subject']?.toString(),
      ]) ??
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

  return CalmPushDisplay(title: title, body: body, category: category);
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
