import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves the current station slug from the browser URL.
///
/// Returns null when on the platform-level domain (app.fmstream.online).
/// Returns a slug string for a specific tenant subdomain or legacy domain.
String? _resolveStationId() {
  if (!kIsWeb) return 'lion';
  try {
    final uri = Uri.base;
    final hostname = uri.host.toLowerCase();

    // a) Platform sentinel — no tenant
    if (hostname == 'app.fmstream.online' ||
        hostname == 'www.app.fmstream.online') return null;

    // b) Subdomain of fmstream.online
    if (hostname.endsWith('.fmstream.online')) {
      final sub = hostname.split('.').first;
      if (sub.isNotEmpty) return sub;
    }

    // c) ?station= query param (dev only)
    final stationParam = uri.queryParameters['station'];
    if (stationParam != null && stationParam.isNotEmpty) return stationParam;

    // d) Legacy Lion FM domains
    if (hostname == 'lionfm.online' ||
        hostname == 'www.lionfm.online') return 'lion';
    if (hostname.contains('lionfm.vercel.app')) return 'lion';

    // e) Local dev default
    if (hostname == 'localhost' || hostname == '127.0.0.1') return 'lion';

    // f) Unknown — platform level
    return null;
  } catch (_) {
    return 'lion';
  }
}

/// Returns null for the platform-level domain (app.fmstream.online),
/// or a tenant slug string for any station subdomain or legacy domain.
final currentStationIdProvider = Provider<String?>((ref) => _resolveStationId());
