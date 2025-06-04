import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishika/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishika/screens/login_screen.dart';

void main() {
  testWidgets('App should start with login screen', (WidgetTester tester) async {
    // Setup SharedPreferences mock
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Initial load should show CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for FutureBuilder to complete
    await tester.pump();

    // Should find LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Should find login form elements
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email/Phone and Password fields
    expect(find.byType(ElevatedButton), findsOneWidget); // Login button
    expect(find.text('Don\'t have an account? Sign up'), findsOneWidget);
  });
}
