import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_recipient.dart';

void main() {
  group('MessageRecipient.fromFirestoreUser', () {
    test('never uses the full email local-part as handle', () {
      final recipient = MessageRecipient.fromFirestoreUser('uid-1', {
        'displayName': 'David M.',
        'email': 'neilwarner+admin@belongonthespectrum.com',
        'bio': 'Organizer',
      });

      expect(recipient.handle, 'admin');
      expect(recipient.pickerSubtitle, contains('@admin'));
      expect(recipient.pickerSubtitle, isNot(contains('neilwarner')));
      expect(recipient.pickerSubtitle, isNot(contains('+')));
    });

    test('omits handle subtitle when address has no plus-tag', () {
      final recipient = MessageRecipient.fromFirestoreUser('uid-2', {
        'displayName': 'Community Member',
        'email': 'grokbot2@example.com',
        'bio': 'Test peer',
      });

      expect(recipient.handle, isNull);
      expect(recipient.pickerSubtitle, 'Test peer');
    });

    test('prefers published directory handle over email', () {
      final recipient = MessageRecipient.fromFirestoreUser('uid-3', {
        'displayName': 'Sarah K.',
        'email': 'member+othertag@example.com',
        'handle': 'publicnick',
        'tagline': 'Circle host',
      });

      expect(recipient.handle, 'publicnick');
      expect(recipient.tagline, 'Circle host');
      expect(recipient.pickerSubtitle, 'Circle host · @publicnick');
    });
  });
}
