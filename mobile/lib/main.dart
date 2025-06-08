import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/audio_player_provider.dart';
import 'providers/user_provider.dart';
import 'providers/context_provider.dart';
import 'providers/swipe_provider.dart';
import 'providers/reading_analytics_provider.dart';
import 'providers/notification_provider.dart';
import 'services/audio_service.dart';
import 'services/session_service.dart';
import 'services/tts_service.dart';
import 'services/firestore_service.dart';
import 'services/recommendation_service.dart';
import 'services/context_service.dart';
import 'services/notification_service.dart';
import 'services/swipe_service.dart';
import 'services/api_service.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Test Firebase setup in debug mode
  // Uncomment the line below to test Firebase configuration
  // await FirebaseTest.testFirebaseInitialization();

  // Initialize Mobile Ads
  MobileAds.instance.initialize();

  // Initialize audio service for background playback
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.roudoku.app.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize TTS Service
  final ttsService = TtsService();
  await ttsService.initialize();

  runApp(RoudokuApp(prefs: prefs, ttsService: ttsService));
}

class RoudokuApp extends StatelessWidget {
  final SharedPreferences prefs;
  final TtsService ttsService;

  const RoudokuApp({super.key, required this.prefs, required this.ttsService});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final dio = Dio();
    const baseUrl = 'http://localhost:8080'; // Update with your API base URL
    final audioService = AudioService(dio: dio, baseUrl: baseUrl);
    final sessionService = SessionService(dio: dio, baseUrl: baseUrl);
    final contextService = ContextService(prefs);
    final firestoreService = FirestoreService();
    final recommendationService = RecommendationService(
      dio: dio,
      baseUrl: baseUrl,
      contextService: contextService,
    );
    final notificationService = NotificationService(dio: dio, baseUrl: baseUrl);
    final swipeService = SwipeService(dio, prefs);
    final apiService = HttpApiService(dio: dio, baseUrl: baseUrl);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(
          create: (_) => AudioPlayerProvider(
            audioService: audioService,
            sessionService: sessionService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ContextProvider()),
        ChangeNotifierProvider(
          create: (_) => SwipeProvider(swipeService, contextService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReadingAnalyticsProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService),
        ),
        // Provide services for other screens
        Provider<AudioService>.value(value: audioService),
        Provider<SessionService>.value(value: sessionService),
        Provider<TtsService>.value(value: ttsService),
        Provider<ContextService>.value(value: contextService),
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<RecommendationService>.value(value: recommendationService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<SwipeService>.value(value: swipeService),
      ],
      child: MaterialApp(
        title: 'roudoku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF2196F3),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
          ).copyWith(secondary: const Color(0xFF03DAC6)),
          fontFamily: 'NotoSansJP',
          appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
