// ══════════════════════════════════════════════════════════════════════════════
// STARTUP SEQUENCE — guiding principle: reach runApp() as fast as possible.
//
// Before this refactor the sequence was:
//   Firebase.init → JustAudioBackground.init → 3× FCM subscribes (sequential)
//   → AnalyticsService.ensureTodayDoc() (Firestore read + write!) → runApp()
//
// The Firestore call alone added ~300–800 ms of network round-trip BEFORE the
// browser had even started painting. On mobile web that translated directly into
// TBT (total blocking time) because the JS engine was stuck awaiting a Promise.
//
// After this refactor:
//   Firebase.init ‖ setPreferredOrientations (parallel)
//   → runApp() immediately
//   → [background] mobile services (JustAudioBackground + FCM in parallel)
//   → [first frame callback] ensureTodayDoc() — zero impact on startup
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:async';

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

  // ── Step 0: Background audio — must complete before any playback attempt ───
  // JustAudioBackground.init() registers the Android service and sets up the
  // notification channel. Running it unawaited caused a race where a user
  // tapping play before init completed crashed the app.
  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'ng.edu.unn.lionfm.channel.audio',
      androidNotificationChannelName: 'LionFM Audio Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_notification',
    );
  }

  // ── Step 1: Parallelise the only two truly blocking boot tasks ─────────────
  // Firebase.initializeApp() and setPreferredOrientations() are completely
  // independent. Running them concurrently saves the orientation-lock cost
  // (~20–50 ms on mobile) from the critical path.
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    // On web setPreferredOrientations is a no-op that resolves immediately,
    // so this never adds latency on the web critical path.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  ]);

  // ── Step 2: Synchronous system-UI chrome (no await needed) ─────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // ── Step 3: Fire mobile-only services in the background ────────────────────
  // unawaited() documents that we are deliberately not blocking on this future.
  // JustAudioBackground and FCM topic subscriptions don't affect the initial
  // render — starting them here lets them initialise in parallel with Flutter's
  // first-frame rendering work.
  if (!kIsWeb) {
    unawaited(_initMobileServices());
  }

  // ── Step 4: Start the app immediately ──────────────────────────────────────
  runApp(const ProviderScope(child: LionFMApp()));

  // ── Step 5: Non-critical analytics — deferred to after first frame ─────────
  // ensureTodayDoc() makes a Firestore read (and conditional write) on every
  // cold start. Running it before runApp() was the primary cause of the 2 500 ms
  // TBT on web because the JS engine was blocked on a pending network response.
  // Moved here: the first frame paints, *then* we do the analytics work in the
  // background. Users see the UI immediately; analytics lands ~100 ms later.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(AnalyticsService.ensureTodayDoc());
  });
}

/// Initialises mobile-only services that have no bearing on the initial render.
/// Runs fully in the background via unawaited() so it never delays runApp().
Future<void> _initMobileServices() async {
  // FCM topic subscriptions — run the three in parallel, not sequentially.
  // Previously three sequential awaits added ~200–400 ms of sequential latency
  // even though the subscribes are completely independent of each other.
  try {
    await Future.wait([
      FirebaseMessaging.instance.subscribeToTopic('all_listeners'),
      FirebaseMessaging.instance.subscribeToTopic('show_alerts'),
      FirebaseMessaging.instance.subscribeToTopic('breaking_news'),
    ]);
  } catch (e) {
    debugPrint('FCM setup error (non-fatal): $e');
  }
}
