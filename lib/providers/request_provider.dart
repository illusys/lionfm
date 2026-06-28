import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/request_repository.dart';
import 'current_station_provider.dart';

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return FirestoreRequestRepository(
      stationId: ref.watch(currentStationIdProvider));
});
