import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_exception.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_exception.dart';

class _MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class _MockFirebaseApp extends Mock implements FirebaseApp {}

class _MockFirebaseOptions extends Mock implements FirebaseOptions {}

class _MockUser extends Mock implements fb.User {}

class _MockUserCredential extends Mock implements fb.UserCredential {}

void main() {
  late _MockFirebaseAuth auth;
  late _MockUser user;
  late _MockUserCredential credential;

  setUpAll(() {
    registerFallbackValue(fb.ActionCodeSettings(url: 'https://belongonthespectrum.web.app/auth'));
  });

  setUp(() {
    auth = _MockFirebaseAuth();
    user = _MockUser();
    credential = _MockUserCredential();
    when(() => credential.user).thenReturn(user);
    when(() => user.uid).thenReturn('uid-member');
    when(() => user.email).thenReturn('member@belongonthespectrum.com');
    when(() => user.displayName).thenReturn('David M.');
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.emailVerified).thenReturn(false);
    when(() => user.photoURL).thenReturn(null);
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => user.sendEmailVerification()).thenAnswer((_) async {});
    when(() => user.reload()).thenAnswer((_) async {});
    when(() => auth.currentUser).thenReturn(user);
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
    when(
      () => auth.signInWithEmailLink(
        email: any(named: 'email'),
        emailLink: any(named: 'emailLink'),
      ),
    ).thenAnswer((_) async => credential);
    when(
      () => auth.sendSignInLinkToEmail(
        email: any(named: 'email'),
        actionCodeSettings: any(named: 'actionCodeSettings'),
      ),
    ).thenAnswer((_) async {});
    when(() => auth.sendPasswordResetEmail(email: any(named: 'email'))).thenAnswer((_) async {});
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(user));
  });

  tearDown(() async {
    final repo = FirebaseAuthRepository(firebaseAuth: auth, flavor: AppFlavor.dev);
    await repo.signOut();
  });

  void useApiKey(String apiKey) {
    final app = _MockFirebaseApp();
    final options = _MockFirebaseOptions();
    when(() => options.apiKey).thenReturn(apiKey);
    when(() => app.options).thenReturn(options);
    when(() => auth.app).thenReturn(app);
  }

  FirebaseAuthRepository repo({
    AppFlavor flavor = AppFlavor.prod,
    Future<bool> Function(String userId)? blocked,
  }) => FirebaseAuthRepository(firebaseAuth: auth, flavor: flavor, isAccountSoftDeleted: blocked);

  test('a dummy or short API key stays on the in-memory fallback', () async {
    useApiKey('DummyKey');
    final offline = repo();
    final session = await offline.registerWithPassword(
      email: 'member@belongonthespectrum.com',
      password: 'calm-pass',
      displayName: 'Sarah K.',
      icocChurchAffiliation: 'I am not a member of an ICOC church',
    );
    expect(session.authMethod, 'in_memory_password');
    expect(offline.currentSession().isSignedIn, isTrue);

    useApiKey('short');
    final signedOut = await offline.signOut();
    expect(signedOut.isSignedIn, isFalse);
  });

  test('real credentials register, verify on prod, and map a Firebase failure', () async {
    useApiKey('belong-test-api-key-0123456789');
    final created = await repo().registerWithPassword(
      email: 'member@belongonthespectrum.com',
      password: 'calm-pass',
      displayName: 'David M.',
      bio: 'Prayer and quiet reflection.',
      icocChurchAffiliation: 'DFW Church (Partner)',
    );
    expect(created.userId, 'uid-member');
    expect(created.authMethod, 'firebase_password');
    verify(() => user.sendEmailVerification()).called(1);

    final devCreated = await repo(flavor: AppFlavor.dev).registerWithPassword(
      email: 'tester@example.com',
      password: 'calm-pass',
      displayName: 'Fellow Member',
      icocChurchAffiliation: 'I am not a member of an ICOC church',
    );
    expect(devCreated.userId, 'uid-member');
    expect(devCreated.authMethod, 'firebase_password');

    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(fb.FirebaseAuthException(code: 'email-already-in-use'));
    expect(
      () => repo().registerWithPassword(
        email: 'member@belongonthespectrum.com',
        password: 'calm-pass',
        displayName: 'David M.',
        icocChurchAffiliation: 'DFW Church (Partner)',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('sign-in refuses a soft-deleted account and otherwise returns the user', () async {
    useApiKey('belong-test-api-key-0123456789');
    when(() => auth.signOut()).thenThrow(StateError('already signed out'));
    final blocked = repo(blocked: (_) async => true);
    expect(
      () => blocked.signInWithPassword(
        email: 'member@belongonthespectrum.com',
        password: 'calm-pass',
      ),
      throwsA(
        isA<AuthException>()
            .having((error) => error.code, 'code', 'account-soft-deleted')
            .having((error) => error.message, 'message', AccountDeletionMessages.signInBlocked),
      ),
    );

    when(() => auth.signOut()).thenAnswer((_) async {});
    final open = await repo(blocked: (_) async => false)
        .signInWithPassword(email: 'member@belongonthespectrum.com', password: 'calm-pass');
    expect(open.emailVerified, isFalse);
    expect(open.displayName, 'David M.');
  });

  test('magic link, password reset, reload, and verification email', () async {
    useApiKey('belong-test-api-key-0123456789');
    final live = repo();
    await live.sendMagicLink(email: 'member@belongonthespectrum.com');
    final linked = await live.signInWithMagicLink(
      email: 'member@belongonthespectrum.com',
      emailLink: 'https://belongonthespectrum.web.app/auth?oobCode=test',
    );
    expect(linked.authMethod, 'firebase_magic_link');
    expect(linked.emailVerified, isTrue);

    await live.sendPasswordResetEmail(email: 'member@belongonthespectrum.com');
    final reloaded = await live.reloadCurrentUser();
    expect(reloaded.userId, 'uid-member');

    await live.sendEmailVerification();
    verify(() => user.sendEmailVerification()).called(greaterThan(0));

    when(() => auth.currentUser).thenReturn(null);
    expect(
      () => live.sendEmailVerification(),
      throwsA(isA<AuthException>().having((error) => error.code, 'code', 'no-current-user')),
    );

    await repo(flavor: AppFlavor.dev).sendEmailVerification();
  });

  test('auth state, anonymous session, oauth, and email-name sign-in', () async {
    useApiKey('belong-test-api-key-0123456789');
    final live = repo();
    final states = await live.authStateChanges().take(1).toList();
    expect(states.single.userId, 'uid-member');
    expect(live.currentSession().photoUrl, isNull);

    when(() => user.isAnonymous).thenReturn(true);
    expect(live.currentSession().isSignedIn, isFalse);

    await live.signOut();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.displayName).thenReturn('');
    expect(live.currentSession().displayName, 'Fellowship Member');

    final named = live.signInWithEmailAndName(
      displayName: 'Sarah K.',
      email: 'member@belongonthespectrum.com',
      icocChurchAffiliation: 'I am not a member of an ICOC church',
    );
    expect(named.authMethod, 'firebase_email');
    expect(live.currentSession().displayName, 'Sarah K.');

    final oauth = live.signInWithOAuthProvider('google');
    expect(oauth.authMethod, 'firebase_google');

    when(
      () => auth.sendSignInLinkToEmail(
        email: any(named: 'email'),
        actionCodeSettings: any(named: 'actionCodeSettings'),
      ),
    ).thenThrow(fb.FirebaseAuthException(code: 'invalid-email'));
    expect(() => live.sendMagicLink(email: 'not-an-email'), throwsA(isA<AuthException>()));

    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    final signedOutStream = await live.authStateChanges().take(1).toList();
    expect(signedOutStream.single.isSignedIn, isTrue);
  });

  test('missing Firebase auth uses the fallback for reset and magic link', () async {
    final offline = FirebaseAuthRepository(firebaseAuth: null, flavor: AppFlavor.prod);
    await offline.sendPasswordResetEmail(email: 'member@belongonthespectrum.com');
    await offline.sendMagicLink(email: 'member@belongonthespectrum.com');
    final session = await offline.signInWithMagicLink(
      email: 'member@belongonthespectrum.com',
      emailLink: 'https://belongonthespectrum.web.app/auth?email=member@belongonthespectrum.com',
    );
    expect(session.isSignedIn, isTrue);
    expect(offline.target, BackendTarget.firebase);
  });
}
