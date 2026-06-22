import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final _db = FirebaseFirestore.instance;
  static final _fa = FirebaseAnalytics.instance;

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> initialize() async {
    debugPrint('[Analytics] initialized');
  }

  /// Creates today's daily doc if it does not exist yet (backfill on first run).
  static Future<void> ensureTodayDoc() async {
    try {
      final key = _todayKey();
      final ref = _db.collection('analytics').doc(key);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'date': key,
          'listeners': 0,
          'uniqueListeners': 0,
          'requests': 0,
          'podcastPlays': 0,
          'premiumPurchases': 0,
          'eventTickets': 0,
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
        });
      }
    } catch (_) {}
  }

  static Future<void> logListenStart({required String showTitle}) async {
    try {
      final key = _todayKey();
      await _db.collection('analytics').doc(key).set(
        {
          'date': key,
          'listeners': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
      await _db.collection('analytics').doc('summary').set(
        {'totalListeners': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _fa.logEvent(name: 'stream_start', parameters: {'show': showTitle});
    } catch (_) {}
  }

  static Future<void> logListenStop({required int durationSeconds}) async {
    try {
      await _fa.logEvent(
          name: 'stream_stop',
          parameters: {'duration_sec': durationSeconds});
    } catch (_) {}
  }

  static Future<void> logEpisodePlay(
      {required String episodeId, required String title}) async {
    try {
      final key = _todayKey();
      await _db.collection('analytics').doc(key).set(
        {'date': key, 'podcastPlays': FieldValue.increment(1)},
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
        {'date': key, 'requests': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _fa.logEvent(
          name: 'song_request', parameters: {'show': showName});
    } catch (_) {}
  }

  static Future<void> logShowPitch() async {
    try {
      await _fa.logEvent(name: 'show_pitch_submitted');
    } catch (_) {}
  }

  static Future<void> logPremiumPurchase(
      {required String reference}) async {
    try {
      final key = _todayKey();
      await _db.collection('analytics').doc(key).set(
        {'date': key, 'premiumPurchases': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _db.collection('analytics').doc('summary').set(
        {'premiumUsers': FieldValue.increment(1)},
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
        {'date': key, 'eventTickets': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _fa.logPurchase(
          currency: 'NGN', value: priceNGN.toDouble(),
          parameters: {'event_id': eventId});
    } catch (_) {}
  }

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
      final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
      await _db.collection('analytics').doc('summary').set(
        {'platformBreakdown.$platform': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}
