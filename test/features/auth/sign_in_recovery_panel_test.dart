import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/sign_in_recovery_panel.dart';

void main() {
  testWidgets('forgot password and resend help are plain language', (tester) async {
    var forgotTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignInRecoveryPanel(
            canUseAppWhileWaiting: true,
            onForgotPassword: () => forgotTaps++,
          ),
        ),
      ),
    );

    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.text('We email you a link to choose a new password.'), findsOneWidget);
    expect(
      find.textContaining(
        'You can use the app while you wait, then send the verification email again.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('sign_in_forgot_password')));
    await tester.pump();
    expect(forgotTaps, 1);
  });

  testWidgets('production help points at the check-email screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SignInRecoveryPanel(canUseAppWhileWaiting: false))),
    );

    expect(
      find.textContaining('The next screen lets you send the verification email again.'),
      findsOneWidget,
    );
    expect(find.textContaining('You can use the app while you wait'), findsNothing);
    final button = tester.widget<TextButton>(find.byKey(const Key('sign_in_forgot_password')));
    expect(button.onPressed, isNull);
  });
}
