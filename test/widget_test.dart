// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedding_planner/main.dart';
import 'package:wedding_planner/providers/wedding_provider.dart';

void main() {
  testWidgets('Wedding Planner smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences with mock values
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const WeddingPlannerApp(),
      ),
    );

    // Verify that the navigation items are present
    expect(find.text('홈'), findsWidgets);
    expect(find.text('준비'), findsWidgets);
  });
}
