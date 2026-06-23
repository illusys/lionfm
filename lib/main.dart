import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app.dart';
import 'data/services/analytics_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background audio via just_audio_background (mobile only).
  // Android: add <service android:name="com.ryanheise.audioservice.AudioServiceBackground…"/>
  // to AndroidManifest.xml. iOS: enable "Audio, AirPlay, and Picture in Picture"
  // background mode in Xcode.
  if (!kIsWeb) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'online.lionfm.channel',
        androidNotificationChannelName: 'Lion FM',
        androidNotificationOngoing: true,
        preloadArtwork: true,
      );
    } catch (e) {
      debugPrint('JustAudioBackground init error (non-fatal): $e');
    }
  }

  // FCM topic subscription is silent on mobile. Permission prompts are shown
  // contextually from Settings when a listener enables notification categories.
  try {
    final messaging = FirebaseMessaging.instance;
    if (!kIsWeb) {
      await messaging.subscribeToTopic('all_listeners');
      await messaging.subscribeToTopic('show_alerts');
      await messaging.subscribeToTopic('breaking_news');
    }
  } catch (e) {
    debugPrint('FCM setup error (non-fatal): $e');
  }

  // Seed today's analytics doc so the dashboard never shows empty on first run
  await AnalyticsService.ensureTodayDoc();

  // Lock to portrait on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: LionFMApp(),
    ),
  );
}
