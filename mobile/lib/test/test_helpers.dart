import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/di/service_locator.dart';
import '../core/config/app_config.dart';
import '../core/logging/logger.dart';

class TestHelpers {
  static Future<void> setupTestEnvironment() async {
    // Initialize test configuration
    AppConfig.initialize(
      environment: Environment.development,
      apiBaseUrl: 'http://localhost:8080',
      enableLogging: true,
      enableCrashReporting: false,
      enableAnalytics: false,
    );

    // Set debug mode for logger
    Logger.setDebugMode(true);

    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    
    // Reset service locator
    await ServiceLocator.reset();
  }

  static Future<void> initializeServiceLocator() async {
    await ServiceLocator.init();
  }

  static Widget createTestApp({
    required Widget child,
    ThemeData? theme,
    Locale? locale,
  }) {
    return MaterialApp(
      home: child,
      theme: theme,
      locale: locale,
      debugShowCheckedModeBanner: false,
    );
  }

  static Widget wrapWithMaterialApp(Widget widget) {
    return MaterialApp(
      home: Scaffold(body: widget),
      debugShowCheckedModeBanner: false,
    );
  }

  static Future<void> pumpAndSettle(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  static Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  static Finder findTextContaining(String text) {
    return find.text(text);
  }

  static Finder findWidgetWithText(String text) {
    return find.widgetWithText(Widget, text);
  }

  static Future<void> expectToFindWidget(Finder finder) async {
    expect(finder, findsOneWidget);
  }

  static Future<void> expectNotToFindWidget(Finder finder) async {
    expect(finder, findsNothing);
  }

  static Future<void> waitForAnimation(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  static Future<void> scrollAndSettle(
    WidgetTester tester,
    Finder scrollable,
    Offset offset,
  ) async {
    await tester.drag(scrollable, offset);
    await tester.pumpAndSettle();
  }
}

class MockData {
  static const Map<String, dynamic> sampleBook = {
    'id': 'book_1',
    'title': 'Sample Book',
    'author': 'Test Author',
    'summary': 'A sample book for testing',
    'genre': 'Fiction',
    'word_count': 50000,
    'is_premium': false,
    'is_active': true,
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
    'chapters': [],
  };

  static const Map<String, dynamic> sampleChapter = {
    'id': 'chapter_1',
    'book_id': 'book_1',
    'title': 'Chapter 1',
    'content': 'Sample chapter content for testing.',
    'position': 1,
    'word_count': 1000,
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
  };

  static const Map<String, dynamic> sampleUser = {
    'user_id': 'user_1',
    'email': 'test@example.com',
    'display_name': 'Test User',
    'email_verified': true,
  };

  static List<Map<String, dynamic>> get sampleBooks => [
    sampleBook,
    {
      ...sampleBook,
      'id': 'book_2',
      'title': 'Another Book',
      'author': 'Another Author',
    },
  ];

  static List<Map<String, dynamic>> get sampleChapters => [
    sampleChapter,
    {
      ...sampleChapter,
      'id': 'chapter_2',
      'title': 'Chapter 2',
      'position': 2,
    },
  ];
}

class TestMatchers {
  static Matcher isLoadingState() {
    return predicate<dynamic>((state) {
      return state.toString().contains('loading');
    }, 'is loading state');
  }

  static Matcher isSuccessState() {
    return predicate<dynamic>((state) {
      return state.toString().contains('success');
    }, 'is success state');
  }

  static Matcher isErrorState() {
    return predicate<dynamic>((state) {
      return state.toString().contains('error');
    }, 'is error state');
  }

  static Matcher hasData() {
    return predicate<dynamic>((state) {
      return state.hasData == true;
    }, 'has data');
  }

  static Matcher hasErrorMessage(String message) {
    return predicate<dynamic>((state) {
      return state.errorMessage?.contains(message) == true;
    }, 'has error message: $message');
  }
}

extension WidgetTesterExtensions on WidgetTester {
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    bool timerDone = false;
    final timer = Timer(timeout, () => timerDone = true);
    
    while (timerDone != true) {
      await pump();
      
      if (finder.evaluate().isNotEmpty) {
        timer.cancel();
        return;
      }
      
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    timer.cancel();
    throw Exception('Widget not found within timeout: $finder');
  }

  Future<void> ensureVisible(Finder finder) async {
    await scrollUntilVisible(finder, 100.0);
  }
}