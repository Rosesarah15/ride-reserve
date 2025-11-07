import 'package:bus_booking/admin/admin_home_page.dart';
import 'package:bus_booking/auth/login_page.dart';
import 'package:bus_booking/auth/register_page.dart';
import 'package:bus_booking/home/presentation/pages/main_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:matcher/matcher.dart'; // Import matcher for isA

// Mock classes for Firebase
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('LoginPage', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseFirestore mockFirebaseFirestore;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    // Specific placeholder values to avoid `any` matcher issues
    const String testEmail = 'test@example.com';
    const String testPassword = 'password123';
    const String adminEmail = 'admin@example.com';
    const String adminPassword = 'adminpassword';
    const String wrongPassword = 'wrongpassword';
    const String forgotEmail = 'forgot@example.com';
    const String testUid = 'test_uid';
    const String usersCollection = 'users';

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();

      // Stub the FirebaseAuth instance with default successful login
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => mockUserCredential);

      when(mockFirebaseAuth.sendPasswordResetEmail(email: forgotEmail)).thenAnswer((_) async => Future.value());

      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn(testUid);

      // Stub the FirebaseFirestore instance with specific values for collection/doc
      when(mockFirebaseFirestore.collection(usersCollection)).thenReturn(MockCollectionReference());
      when(mockFirebaseFirestore.collection(usersCollection).doc(testUid)).thenReturn(MockDocumentReference());
    });

    testWidgets('logs in successfully as a regular user', (WidgetTester tester) async {
      // Mock Firestore document for a regular user
      final mockDocumentSnapshot = MockDocumentSnapshot();
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn({'Role': 'user'} as Map<String, dynamic>);
      when(mockFirebaseFirestore.collection(usersCollection).doc(testUid).get()).thenAnswer((_) async => mockDocumentSnapshot);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => LoginPage(),
          ),
        ),
      );

      // Enter email and password
      await tester.enterText(find.bySemanticsLabel('Enter your email'), testEmail);
      await tester.enterText(find.bySemanticsLabel('Enter your password'), testPassword);

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify navigation to MainPage
      expect(find.byType(MainPage), findsOneWidget);
      verify(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
    });

    testWidgets('logs in successfully as an admin user', (WidgetTester tester) async {
      // Stub admin login for this specific test
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      )).thenAnswer((_) async => mockUserCredential);

      // Mock Firestore document for an admin user
      final mockDocumentSnapshot = MockDocumentSnapshot();
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn({'Role': 'Admin'} as Map<String, dynamic>);
      when(mockFirebaseFirestore.collection(usersCollection).doc(testUid).get()).thenAnswer((_) async => mockDocumentSnapshot);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => LoginPage(),
          ),
        ),
      );

      // Enter email and password
      await tester.enterText(find.bySemanticsLabel('Enter your email'), adminEmail);
      await tester.enterText(find.bySemanticsLabel('Enter your password'), adminPassword);

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify navigation to AdminHomePage
      expect(find.byType(AdminHomePage), findsOneWidget);
      verify(mockFirebaseAuth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword)).called(1);
    });

    testWidgets('shows error on failed login', (WidgetTester tester) async {
      // Stub failed login for this specific test
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: wrongPassword,
      )).thenThrow(FirebaseAuthException(code: 'wrong-password', message: 'Wrong password'));

      // No specific Firestore mock needed as login will fail before checking role

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => LoginPage(),
          ),
        ),
      );

      // Enter email and password that will cause failure
      await tester.enterText(find.bySemanticsLabel('Enter your email'), testEmail);
      await tester.enterText(find.bySemanticsLabel('Enter your password'), wrongPassword);

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pump(); // Pump once to show the SnackBar

      // Verify error message
      expect(find.text('Wrong password'), findsOneWidget);
      verify(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: wrongPassword)).called(1);
    });

    testWidgets('sends password reset email successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => LoginPage(),
          ),
        ),
      );

      // Tap forgot password button
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle(); // Wait for dialog to appear

      // Enter email in dialog
      await tester.enterText(find.byType(TextField), forgotEmail);
      await tester.tap(find.text('Submit'));
      await tester.pump(); // Pump once to show the SnackBar

      // Verify success message
      expect(find.text('Password reset email sent'), findsOneWidget);
      verify(mockFirebaseAuth.sendPasswordResetEmail(email: forgotEmail)).called(1);
    });
  });

  group('RegisterPage', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseFirestore mockFirebaseFirestore;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    // Specific placeholder values to avoid `any` matcher issues
    const String regFirstName = 'John';
    const String regLastName = 'Doe';
    const String regEmail = 'john.doe@example.com';
    const String regPassword = 'password123';
    const String regMismatchPassword = 'differentpassword';
    const String regUid = 'new_user_uid';
    const String usersCollection = 'users';

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();

      // Stub FirebaseAuth for registration with default successful values
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: regEmail,
        password: regPassword,
      )).thenAnswer((_) async => mockUserCredential);

      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn(regUid);

      // Stub FirebaseFirestore for user data storage with specific values for collection/doc
      when(mockFirebaseFirestore.collection(usersCollection)).thenReturn(MockCollectionReference());
      when(mockFirebaseFirestore.collection(usersCollection).doc(regUid)).thenReturn(MockDocumentReference());
      when(mockFirebaseFirestore.collection(usersCollection).doc(regUid).set({
        'FirstName': regFirstName,
        'LastName': regLastName,
        'email': regEmail,
        'Role': 'user',
      })).thenAnswer((_) async => Future.value());
    });

    testWidgets('registers successfully and navigates to MainPage', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => RegisterPage(),
          ),
        ),
      );

      // Enter registration details
      await tester.enterText(find.bySemanticsLabel('Enter your first name'), regFirstName);
      await tester.enterText(find.bySemanticsLabel('Enter your last name'), regLastName);
      await tester.enterText(find.bySemanticsLabel('Enter your email'), regEmail);
      await tester.enterText(find.bySemanticsLabel('Enter your password'), regPassword);
      await tester.enterText(find.bySemanticsLabel('Re-enter your password'), regPassword);

      // Tap register button
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Verify navigation to MainPage
      expect(find.byType(MainPage), findsOneWidget);
      verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: regEmail, password: regPassword)).called(1);
      verify(mockFirebaseFirestore.collection(usersCollection).doc(regUid).set({
        'FirstName': regFirstName,
        'LastName': regLastName,
        'email': regEmail,
        'Role': 'user',
      })).called(1);
    });

    testWidgets('shows error on failed registration (e.g., weak password)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => RegisterPage(),
          ),
        ),
      );

      // Enter registration details that will cause failure
      await tester.enterText(find.bySemanticsLabel('Enter your first name'), regFirstName);
      await tester.enterText(find.bySemanticsLabel('Enter your last name'), regLastName);
      await tester.enterText(find.bySemanticsLabel('Enter your email'), regEmail);
      await tester.enterText(find.bySemanticsLabel('Enter your password'), regMismatchPassword); // Using this to trigger the mocked failure
      await tester.enterText(find.bySemanticsLabel('Re-enter your password'), regMismatchPassword);

      // Tap register button
      await tester.tap(find.text('Register'));
      await tester.pump(); // Pump once to show the SnackBar

      // Verify error message
      expect(find.text('Weak password'), findsOneWidget);
      verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: regEmail, password: regMismatchPassword)).called(1);
    });

    testWidgets('shows error on password mismatch', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => RegisterPage(),
          ),
        ),
      );

      // Enter registration details with mismatched passwords
      await tester.enterText(find.bySemanticsLabel('Enter your first name'), regFirstName);
      await tester.enterText(find.bySemanticsLabel('Enter your last name'), regLastName);
      await tester.enterText(find.bySemanticsLabel('Enter your email'), regEmail);
      await tester.enterText(find.bySemanticsLabel('Enter your password'), regPassword);
      await tester.enterText(find.bySemanticsLabel('Re-enter your password'), regMismatchPassword);

      // Tap register button
      await tester.tap(find.text('Register'));
      await tester.pump();

      // Verify error message
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
