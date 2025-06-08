// Basic widget test for the Roudoku app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roudoku/main.dart';
import 'package:roudoku/services/tts_service.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    // Set up test dependencies
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ttsService = TtsService();
    await ttsService.initialize();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(RoudokuApp(prefs: prefs, ttsService: ttsService));

    // Pump and settle to ensure all async operations complete
    await tester.pumpAndSettle();
    
    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
