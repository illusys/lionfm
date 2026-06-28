import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All station onboarding requests, newest first. Platform owner only.
final onboardingRequestsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('station_onboarding')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map<Map<String, dynamic>>((d) => {'id': d.id, ...d.data()})
          .toList());
});
