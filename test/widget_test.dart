// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:futsmandu/features/auth/presentation/screens/login_screen.dart';
import 'package:futsmandu/features/auth/presentation/screens/register_screen.dart';

void main() {
  Widget buildAuthTestApp() {
    return MaterialApp(
      home: LoginScreen(),
      routes: {'/register': (_) => RegisterScreen()},
    );
  }

  testWidgets('Login screen renders key elements', (WidgetTester tester) async {
    await tester.pumpWidget(buildAuthTestApp());

    // Login screen heading should be present
    expect(find.text('Welcome Back'), findsOneWidget);

    // Both primary actions should be visible
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('Login screen navigates to register', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildAuthTestApp());

    // Scroll the outlined CTA into view before tapping.
    await tester.ensureVisible(find.text('Create Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Register screen header should now be visible
    expect(find.textContaining('Create Owner'), findsOneWidget);
  });
}
