import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'current_station_provider.dart';
import 'station_provider.dart';

/// Resolves the active Material ThemeData for the current station.
///
/// - When station data is loaded: derives theme from station.brandColors.
/// - While loading (non-Lion FM tenant): neutral FMStream teal/navy defaults,
///   NOT Lion FM gold, to avoid briefly flashing wrong branding.
/// - Lion FM (stationId == 'lion'): falls back to AppTheme.dark while loading
///   so the Lion FM experience is unchanged.
final stationThemeProvider = Provider<ThemeData>((ref) {
  final stationId = ref.watch(currentStationIdProvider);

  // Platform level (app.fmstream.online): use FMStream default
  if (stationId == null) return AppTheme.fmstreamDefault;

  final stationAsync = ref.watch(stationProvider(stationId));

  return stationAsync.whenOrNull(
        data: (station) => AppTheme.fromBrandColors(station.brandColors),
      ) ??
      // While loading: Lion FM keeps its gold palette; tenants get neutral teal
      (stationId == 'lion' ? AppTheme.dark : AppTheme.fmstreamDefault);
});
