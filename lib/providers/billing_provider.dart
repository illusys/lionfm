import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final stationPaymentsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, stationId) {
  return FirebaseFirestore.instance
      .collection('station_payments')
      .where('stationId', isEqualTo: stationId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs
          .map<Map<String, dynamic>>((d) => {'id': d.id, ...d.data()})
          .toList());
});
