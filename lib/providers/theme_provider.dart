import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'current_station_provider.dart';
import 'station_provider.dart';

/// Resolves the active Material ThemeData for the current station.
/// Falls back to AppTheme.dark while the station document is loading
/// or if the station is not found.
final stationThemeProvider = Provider<ThemeData>((ref) {
  final stationId = ref.watch(currentStationIdProvider);
  final stationAsync = ref.watch(stationProvider(stationId));
  return stationAsync.whenOrNull(
        data: (station) => AppTheme.fromBrandColors(station.brandColors),
      ) ??
      AppTheme.dark;
});
