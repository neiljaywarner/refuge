/// Member-facing confirmation after a note is saved for organizers.
///
/// Issue trackers and clipboard handoff stay out of this sentence.
String feedbackSavedForOrganizers({required bool hasReplyEmail, required bool keptDrawing}) {
  final reply = hasReplyEmail ? '' : ' We can only reply if you add a valid email.';
  final drawing = keptDrawing ? ' Your drawing is saved with the note.' : '';
  return 'Thanks! Your note was saved for organizers.$reply$drawing';
}
