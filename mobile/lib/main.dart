import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:dio/dio.dart';

import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/audio_player_provider.dart';
import 'providers/user_provider.dart';
import 'providers/context_provider.dart';
import 'services/audio_service.dart';
import 'services/session_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Mobile Ads
  MobileAds.instance.initialize();
  
  // Initialize audio service for background playback
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.roudoku.app.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  
  runApp(const RoudokuApp());
}

class RoudokuApp extends StatelessWidget {
  const RoudokuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final dio = Dio();
    const baseUrl = 'http://localhost:8080'; // Update with your API base URL
    final audioService = AudioService(dio: dio, baseUrl: baseUrl);
    final sessionService = SessionService(dio: dio, baseUrl: baseUrl);

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
        // Provide services for other screens
        Provider<AudioService>.value(value: audioService),
        Provider<SessionService>.value(value: sessionService),
      ],
      child: MaterialApp(
        title: 'roudoku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF2196F3),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
          ).copyWith(
            secondary: const Color(0xFF03DAC6),
          ),
          fontFamily: 'NotoSansJP',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}