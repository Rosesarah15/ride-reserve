import 'package:bus_booking/utils/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bus_booking/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login and view trips', (WidgetTester tester) async {
    app.main();
    // Wait for the app to settle, especially for Firebase to initialize.
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Ensure user is signed out to guarantee we start on the login page.
    // This prevents test failures caused by a persistent login state from previous runs.
    await FirebaseAuth.instance.signOut();
    
    // Wait for the sign-out to process and for the UI to navigate to the login page.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Now find the email and password fields
    final emailField = find.byType(CustomTextField).at(0);
    final passwordField = find.byType(CustomTextField).at(1);
    final loginButton = find.widgetWithText(CustomButton, 'Login');

    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(loginButton, findsOneWidget);

    const testEmail = 'martha@gmail.com';
    const testPassword = 'Martha123';

    await tester.enterText(emailField, testEmail);
    await tester.enterText(passwordField, testPassword);
    await tester.pumpAndSettle();

    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // After login, we expect to see trip cards.
    final tripCard = find.byType(CustomCard);
    expect(tripCard, findsWidgets);
  });
}