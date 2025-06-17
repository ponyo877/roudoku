import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/audio_player_provider.dart';
import 'providers/user_provider.dart';
import 'providers/context_provider.dart';
import 'providers/reading_analytics_provider.dart';
import 'providers/notification_provider.dart';
import 'services/audio_service.dart';
import 'services/session_service.dart';
import 'services/unified_tts_service.dart';
import 'services/unified_swipe_service.dart';
import 'services/firestore_service.dart';
import 'services/recommendation_service.dart';
import 'services/context_service.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'core/network/dio_client.dart';
import 'screens/auth_wrapper.dart';
import 'utils/constants.dart';

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

  // Initialize Unified TTS Service
  final unifiedTtsService = UnifiedTtsService();
  await unifiedTtsService.initialize();

  runApp(RoudokuApp(prefs: prefs, unifiedTtsService: unifiedTtsService));
}

class RoudokuApp extends StatelessWidget {
  final SharedPreferences prefs;
  final UnifiedTtsService unifiedTtsService;

  const RoudokuApp({super.key, required this.prefs, required this.unifiedTtsService});

  @override
  Widget build(BuildContext context) {
    // Initialize services using centralized Dio client
    DioClient.instance.updateBaseUrl(Constants.apiBaseUrl);
    final audioService = AudioService(dio: DioClient.instance.dio, baseUrl: Constants.apiBaseUrl);
    final sessionService = SessionService(dio: DioClient.instance.dio, baseUrl: Constants.apiBaseUrl);
    final contextService = ContextService(prefs);
    final firestoreService = FirestoreService();
    final recommendationService = RecommendationService(
      dio: DioClient.instance.dio,
      baseUrl: Constants.apiBaseUrl,
      contextService: contextService,
    );
    final notificationService = NotificationService(dio: DioClient.instance.dio, baseUrl: Constants.apiBaseUrl);
    final unifiedSwipeService = UnifiedSwipeService.full(prefs);
    final apiService = HttpApiService(dio: DioClient.instance.dio, baseUrl: Constants.apiBaseUrl);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(
          create: (_) => AudioPlayerProvider(
            audioService: audioService,
            sessionService: sessionService,
            ttsService: unifiedTtsService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ContextProvider()),
        // ChangeNotifierProvider(
        //   create: (_) => SwipeProvider(swipeService, contextService),
        // ), // Using SimpleSwipeService in screens instead
        ChangeNotifierProvider(
          create: (_) => ReadingAnalyticsProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService),
        ),
        // Provide services for other screens
        Provider<AudioService>.value(value: audioService),
        Provider<SessionService>.value(value: sessionService),
        Provider<UnifiedTtsService>.value(value: unifiedTtsService),
        Provider<ContextService>.value(value: contextService),
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<RecommendationService>.value(value: recommendationService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<UnifiedSwipeService>.value(value: unifiedSwipeService),
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
