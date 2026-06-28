import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves the current station slug from the browser hostname.
///
/// Rules:
///   - Mobile (Android/iOS): always 'lion' — single-station native build
///   - localhost / lionfm.online / www.lionfm.online: 'lion'
///   - [slug].fmstream.online: slug (e.g. 'xyz' → stationId 'xyz')
///   - Unknown custom domain: 'lion' (Phase 3b will do a Firestore lookup)
String _resolveStationId() {
  if (!kIsWeb) return 'lion';
  try {
    final host = Uri.base.host;
    if (host.isEmpty ||
        host == 'localhost' ||
        host == 'lionfm.online' ||
        host == 'www.lionfm.online') {
      return 'lion';
    }
    if (host.endsWith('.fmstream.online')) {
      final slug = host.split('.').first;
      return slug.isNotEmpty ? slug : 'lion';
    }
    // Unknown custom domain — Phase 3b: look up stations by customDomain field
    return 'lion';
  } catch (_) {
    return 'lion';
  }
}

final currentStationIdProvider = Provider<String>((ref) => _resolveStationId());
