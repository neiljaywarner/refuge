import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a persistent local receipt of a feedback submission so members
/// can always see "what I entered" even after closing the sheet or leaving the app.
class LocalFeedbackReceipt {
  final String id;
  final String message;
  final String sentimentLabel;
  final String sentimentEmoji;
  final int? rating;
  final String? contact;
  final bool hasDrawing;
  final DateTime timestamp;

  const LocalFeedbackReceipt({
    required this.id,
    required this.message,
    required this.sentimentLabel,
    required this.sentimentEmoji,
    this.rating,
    this.contact,
    this.hasDrawing = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'sentimentLabel': sentimentLabel,
    'sentimentEmoji': sentimentEmoji,
    'rating': rating,
    'contact': contact,
    'hasDrawing': hasDrawing,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LocalFeedbackReceipt.fromJson(Map<String, dynamic> json) => LocalFeedbackReceipt(
    id: json['id'] as String? ?? '',
    message: json['message'] as String? ?? '',
    sentimentLabel: json['sentimentLabel'] as String? ?? '',
    sentimentEmoji: json['sentimentEmoji'] as String? ?? '',
    rating: json['rating'] as int?,
    contact: json['contact'] as String?,
    hasDrawing: json['hasDrawing'] as bool? ?? false,
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

/// Manages local storage of feedback receipts in SharedPreferences.
class LocalFeedbackReceiptStore {
  static const String prefKey = 'belong_local_feedback_receipts_v1';
  static const int maxStoredReceipts = 15;

  static Future<List<LocalFeedbackReceipt>> loadReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(prefKey) ?? [];
    return raw
        .map((entry) {
          try {
            return LocalFeedbackReceipt.fromJson(jsonDecode(entry) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<LocalFeedbackReceipt>()
        .toList();
  }

  static Future<void> saveReceipt(LocalFeedbackReceipt receipt) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadReceipts();
    final updated = [receipt, ...current.where((r) => r.id != receipt.id)];
    if (updated.length > maxStoredReceipts) {
      updated.removeRange(maxStoredReceipts, updated.length);
    }
    await prefs.setStringList(
      prefKey,
      updated.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }
}
