import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Generic cache-first wrapper.
/// T — the model type returned.
/// Caches JSON-serialisable data in SharedPreferences with a TTL.
class CacheFirstRepository<T> {
  final String cacheKey;
  final Duration ttl;
  final Future<List<T>> Function() fetchFromNetwork;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  CacheFirstRepository({
    required this.cacheKey,
    required this.ttl,
    required this.fetchFromNetwork,
    required this.fromJson,
    required this.toJson,
  });

  Future<List<T>> get() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt('${cacheKey}_ts');
    final now = DateTime.now().millisecondsSinceEpoch;

    final isFresh = cachedTime != null &&
        now - cachedTime < ttl.inMilliseconds;

    if (isFresh && cachedJson != null) {
      try {
        final list = (jsonDecode(cachedJson) as List)
            .cast<Map<String, dynamic>>()
            .map(fromJson)
            .toList();
        return list;
      } catch (_) {
        // Cache corrupt — fall through to network
      }
    }

    try {
      final data = await fetchFromNetwork();
      final encoded = jsonEncode(data.map(toJson).toList());
      await prefs.setString(cacheKey, encoded);
      await prefs.setInt('${cacheKey}_ts', now);
      return data;
    } catch (e) {
      // Network failed — return stale cache if available
      if (cachedJson != null) {
        debugPrint('[Cache] Network error, serving stale $cacheKey');
        return (jsonDecode(cachedJson) as List)
            .cast<Map<String, dynamic>>()
            .map(fromJson)
            .toList();
      }
      rethrow;
    }
  }

  Future<void> invalidate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
    await prefs.remove('${cacheKey}_ts');
  }
}
