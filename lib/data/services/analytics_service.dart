import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static Future<void> initialize() async {
    // Firebase Analytics initialized alongside Firebase in main.dart.
    // Additional setup (e.g. user properties) goes here.
    debugPrint('[Analytics] initialized');
  }

  static Future<void> logStreamStart({required String showTitle}) async {
    debugPrint('[Analytics] stream_start: $showTitle');
    // await FirebaseAnalytics.instance.logEvent(name: 'stream_start', ...);
  }

  static Future<void> logStreamStop({required int durationSeconds}) async {
    debugPrint('[Analytics] stream_stop: ${durationSeconds}s');
  }

  static Future<void> logEpisodePlay({required String episodeId, required String title}) async {
    debugPrint('[Analytics] episode_play: $title');
  }

  static Future<void> logSongRequest({required String showName}) async {
    debugPrint('[Analytics] song_request: $showName');
  }

  static Future<void> logShowPitch() async {
    debugPrint('[Analytics] show_pitch_submitted');
  }

  static Future<void> logPremiumPurchase({required String reference}) async {
    debugPrint('[Analytics] premium_purchase: $reference');
  }

  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    debugPrint('[Analytics] user_property: $name=$value');
  }
}
