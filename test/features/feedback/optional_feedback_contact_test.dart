import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/optional_feedback_contact.dart';

void main() {
  const error = OptionalFeedbackContact.emailError;

  test('allows an empty contact', () {
    expect(OptionalFeedbackContact.errorText(''), isNull);
    expect(OptionalFeedbackContact.errorText('   '), isNull);
  });

  test('allows a plain name with no @', () {
    expect(OptionalFeedbackContact.errorText('Fellow Member'), isNull);
    expect(OptionalFeedbackContact.errorText('not-an-email'), isNull);
  });

  test('allows a full email address', () {
    expect(
      OptionalFeedbackContact.errorText('member@belongonthespectrum.com'),
      isNull,
    );
    expect(
      OptionalFeedbackContact.errorText('  member@belongonthespectrum.com  '),
      isNull,
    );
  });

  test('rejects a value that contains @ but is not an address', () {
    for (final value in [
      'not@email',
      'not-an-email@',
      '@belongonthespectrum.com',
      'name@@belongonthespectrum.com',
    ]) {
      expect(OptionalFeedbackContact.errorText(value), error, reason: value);
    }
  });
}
