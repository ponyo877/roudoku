// Basic widget test for the Roudoku app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roudoku/main.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RoudokuApp());

    // Verify that the app name is displayed.
    expect(find.text('roudoku'), findsOneWidget);
    
    // Verify that the bottom navigation bar is present.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
