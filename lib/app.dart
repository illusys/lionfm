import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_router.dart';
import 'providers/current_station_provider.dart';
import 'providers/station_provider.dart';
import 'providers/theme_provider.dart';

class LionFMApp extends ConsumerWidget {
  const LionFMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(stationThemeProvider);
    final stationId = ref.watch(currentStationIdProvider);
    final station = stationId != null
        ? ref.watch(stationProvider(stationId)).valueOrNull
        : null;
    final title = station != null
        ? '${station.name} — Live Radio'
        : 'FMStream — Radio Streaming Platform';

    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
      builder: (context, child) {
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ));
        return child!;
      },
    );
  }
}
