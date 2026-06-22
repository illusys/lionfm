import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/event_model.dart';

final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('events')
      .orderBy('startTime', descending: false)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => EventModel.fromFirestore(d)).toList());
});

final upcomingEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  return ref.watch(eventsStreamProvider).whenData((events) {
    final now = DateTime.now();
    return events.where((e) => e.endTime.isAfter(now) || e.isLive).toList();
  });
});

final liveEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  return ref.watch(eventsStreamProvider).whenData(
    (events) => events.where((e) => e.isLive).toList(),
  );
});

/// Whether the signed-in user holds a paid ticket for [eventId].
final ticketProvider =
    FutureProvider.family<bool, String>((ref, eventId) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('tickets')
        .doc('${uid}_$eventId')
        .get();
    return doc.exists && (doc.data()?['paid'] as bool? ?? false);
  } catch (_) {
    return false;
  }
});
