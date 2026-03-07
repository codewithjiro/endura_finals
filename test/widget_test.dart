// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:endura/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    await Hive.openBox('database');

    // Build our app and trigger a frame.
    await tester.pumpWidget(const AuthGate());

    // Verify that the splash screen is shown initially
    expect(find.text('Gigafy'), findsOneWidget);
  });
}
