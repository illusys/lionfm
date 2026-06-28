import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  AnalyticsService._();

  static final _db = FirebaseFirestore.instance;
  static final _fa = FirebaseAnalytics.instance;

  // Phase 2 stub — Phase 3 updates this via the station context.
  static const _stationId = 'lion';

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }

  static String _platformKey() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }

  static String _locationKey() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      return (locale.countryCode ?? locale.languageCode).toLowerCase();
    } catch (_) {
      return 'ng';
    }
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    debugPrint('[Analytics] initialized');
  }

  static Future<void> ensureTodayDoc() async {
    try {
      final key = _todayKey();
      final ref = _db.collection('analytics').doc(key);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'stationId': _stationId,
          'date': key,
          'sessionStarts': 0,
          'totalListeningSeconds': 0,
          'uniqueListenersCount': 0,
          'peakConcurrent': 0,
          'listeners': 0,
          'requests': 0,
          'podcastPlays': 0,
          'premiumPurchases': 0,
          'eventTickets': 0,
          'platforms': {'web': 0, 'android': 0, 'ios': 0},
          'location': {},
        });
      }
    } catch (_) {}
  }

  // ─── Listening heartbeat ───────────────────────────────────────────────────

  static Future<void> logListeningHeartbeat(int seconds) async {
    if (seconds <= 0) return;
    try {
      final key = _todayKey();
      await _db.collection('analytics').doc(key).set(
        {
          'stationId': _stationId,
          'date': key,
          'totalListeningSeconds': FieldValue.increment(seconds),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  // ─── Session events ────────────────────────────────────────────────────────

  static Future<void> logListenStart({required String showTitle}) async {
    try {
      final key = _todayKey();
      final platform = _platformKey();
      final location = _locationKey();

      await _db.collection('analytics').doc(key).set(
        {
          'stationId': _stationId,
          'date': key,
          'sessionStarts': FieldValue.increment(1),
          'listeners': FieldValue.increment(1),
          'platforms.$platform': FieldValue.increment(1),
          'location.$location': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
      await _db.collection('analytics').doc('summary').set(
        {'stationId': _stationId, 'totalListeners': FieldValue.increment(1)},
        SetOptions(merge: true),
      );

      await _maybeCountUniqueListener();
      await _trackConcurrentPing();

      await _fa.logEvent(name: 'stream_start', parameters: {'show': showTitle});
    } catch (_) {}
  }

  static Future<void> logSessionEnd() async {
    try {
      await _db.collection('analytics').doc('live').set(
        {'stationId': _stationId, 'concurrent': FieldValue.increment(-1)},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  static Future<void> logListenStop({required int durationSeconds}) async {
    try {
      await logSessionEnd();
      await _fa.logEvent(
          name: 'stream_stop',
          parameters: {'duration_sec': durationSeconds});
    } catch (_) {}
  }

  // ─── Content events ────────────────────────────────────────────────────────

  static Future<void> logEpisodePlay(
      {required String episodeId, required String title}) async {
    try {
      final key = _todayKey();
      await _db.collection('analytics').doc(key).set(
        {'stationId': _stationId, 'date': key, 'podcastPlays': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _fa.logEvent(
          name: 'episode_play',
          parameters: {'episode_id': episodeId, 'title': title});
    } catch (_) {}
  }

  static Future<void> logSongRequest({required String showName}) async {
    try {
      final key = _todayKey();
      await _db.collection('analytics').doc(key).set(
        {'stationId': _stationId, 'date': key, 'requests': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _fa.logEvent(name: 'song_request', parameters: {'show': showName});
    } catch (_) {}
  }

  static Future<void> logShowPitch() async {
    try {
      await _fa.logEvent(name: 'show_pitch_submitted');
    } catch (_) {}
  }

  // ─── Monetisation events ───────────────────────────────────────────────────

  static Future<void> logPremiumPurchase({required String reference}) async {
    try {
      final key = _todayKey();
      await _db.collection('analytics').doc(key).set(
        {'stationId': _stationId, 'date': key, 'premiumPurchases': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _db.collection('analytics').doc('summary').set(
        {'stationId': _stationId, 'premiumUsers': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _fa.logPurchase(currency: 'NGN', value: 1000);
    } catch (_) {}
  }

  static Future<void> logEventTicketPurchase(
      {required String eventId, required int priceNGN}) async {
    try {
      final key = _todayKey();
      await _db.collection('analytics').doc(key).set(
        {'stationId': _stationId, 'date': key, 'eventTickets': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _fa.logPurchase(
          currency: 'NGN',
          value: priceNGN.toDouble(),
          parameters: {'event_id': eventId});
    } catch (_) {}
  }

  // ─── User properties ───────────────────────────────────────────────────────

  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _fa.setUserProperty(name: name, value: value);
    } catch (_) {}
  }

  static Future<void> updatePlatformBreakdown() async {
    try {
      final platform = _platformKey();
      await _db.collection('analytics').doc('summary').set(
        {
          'stationId': _stationId,
          'platformBreakdown.$platform': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  static Future<void> _maybeCountUniqueListener() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final flagKey = 'ual_${_todayKey()}';
      if (prefs.getBool(flagKey) == true) return;
      await prefs.setBool(flagKey, true);

      final todayKey = _todayKey();
      await _db.collection('analytics').doc(todayKey).set(
        {
          'stationId': _stationId,
          'date': todayKey,
          'uniqueListenersCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  static Future<void> _trackConcurrentPing() async {
    try {
      final liveRef = _db.collection('analytics').doc('live');
      final todayKey = _todayKey();
      final todayRef = _db.collection('analytics').doc(todayKey);

      await _db.runTransaction((tx) async {
        final live = await tx.get(liveRef);
        final current =
            ((live.data()?['concurrent'] as num?)?.toInt() ?? 0) + 1;
        tx.set(liveRef, {'stationId': _stationId, 'concurrent': current},
            SetOptions(merge: true));

        final today = await tx.get(todayRef);
        final storedPeak =
            (today.data()?['peakConcurrent'] as num?)?.toInt() ?? 0;
        if (current > storedPeak) {
          tx.set(todayRef,
              {'stationId': _stationId, 'date': todayKey, 'peakConcurrent': current},
              SetOptions(merge: true));
        }
      });
    } catch (_) {}
  }
}
