import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/station.dart';

class StationRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('stations');

  Stream<Station> watchStation(String stationId) {
    return _col.doc(stationId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Station "$stationId" not found',
        );
      }
      return Station.fromFirestore(snap);
    });
  }

  Stream<List<Station>> watchAll() {
    return _col
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(Station.fromFirestore).toList());
  }

  Stream<List<Station>> watchAllActive() {
    return _col
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(Station.fromFirestore).toList());
  }

  Future<void> updateStation(String stationId, Map<String, dynamic> fields) {
    return _col.doc(stationId).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Station>> watchFeatured() {
    return _col
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(Station.fromFirestore).toList());
  }

  /// Idempotent seed — writes stations/lion only if it does not already exist.
  /// Returns null on success, or a human-readable string if already seeded.
  Future<String?> seedLionFmStation() async {
    final ref = _col.doc('lion');
    final existing = await ref.get();
    if (existing.exists) return 'Lion FM station is already seeded.';

    // Pull the current stream URL from the legacy stream_config document.
    String streamUrl = '';
    try {
      final config =
          await _db.collection('stream_config').doc('current').get();
      streamUrl = config.data()?['streamUrl'] as String? ?? '';
    } catch (_) {}

    await ref.set({
      'stationId': 'lion',
      'name': 'Lion FM 91.1 MHz',
      'slug': 'lion',
      'frequency': '91.1 MHz',
      'tagline': 'Your Interactive Radio',
      'logoUrl':
          'https://lionfm.online/assets/assets/images/lionfm_logo.png',
      'faviconUrl': 'https://lionfm.online/favicon.png',
      'brandColors': {
        'primary': '#1E9B43',
        'secondary': '#28D7D2',
        'accent': '#C89A29',
        'background': '#0A0A0A',
      },
      'streamUrl': streamUrl,
      'streamType': 'byo',
      'plan': 'enterprise',
      'planStatus': 'active',
      'trialEndsAt': null,
      'ownerUid': 'CAyIAzQ2JWOI7o8L5OdQJoxCdQc2',
      'contactEmail': 'benakanbassey@gmail.com',
      'customDomain': 'lionfm.online',
      'isActive': true,
      'isFeatured': true,
      'listenerCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return null;
  }

  /// Stamps stationId='lion' on all existing tenant-scoped documents that
  /// do not yet have it. Idempotent — safe to run more than once.
  /// Returns a human-readable summary string.
  Future<String> stampTenantDocs() async {
    const stationId = 'lion';
    const collections = [
      'shows', 'podcasts', 'podcast_feeds', 'news', 'requests', 'ads',
      'events', 'chat_messages', 'chat_config', 'banned_users',
      'notification_queue', 'analytics', 'admin_config', 'episodes',
    ];

    int total = 0;
    for (final col in collections) {
      final snap = await _db.collection(col).get();
      final unstamped = snap.docs
          .where((d) => (d.data()['stationId'] as String?) == null)
          .toList();

      var batch = _db.batch();
      int batchCount = 0;
      for (final doc in unstamped) {
        batch.update(doc.reference, {'stationId': stationId});
        batchCount++;
        total++;
        if (batchCount == 400) {
          await batch.commit();
          batch = _db.batch();
          batchCount = 0;
        }
      }
      if (batchCount > 0) await batch.commit();
    }

    return 'Stamped stationId="lion" on $total documents.';
  }
}
