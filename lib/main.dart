import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM: request permission and subscribe to broadcast topics
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (!kIsWeb) {
      // subscribeToTopic is mobile-only; web clients receive via FCM token
      await messaging.subscribeToTopic('all_listeners');
      await messaging.subscribeToTopic('show_alerts');
      await messaging.subscribeToTopic('breaking_news');
    }
  } catch (e) {
    debugPrint('FCM setup error (non-fatal): $e');
  }

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
