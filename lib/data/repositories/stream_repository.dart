import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stream_status_model.dart';

abstract class StreamRepository {
  Future<StreamStatusModel> getStreamStatus();
}

/// Reads live stream status from Firestore `stream_config/current`.
class FirestoreStreamRepository implements StreamRepository {
  @override
  Future<StreamStatusModel> getStreamStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('stream_config')
          .doc('current')
          .get();

      if (!doc.exists) return _offline();

      final d = doc.data()!;
      return StreamStatusModel(
        isLive: d['isLive'] as bool? ?? false,
        listenerCount: (d['listenerCount'] as num?)?.toInt() ?? 0,
        currentShowId: d['currentShowId'] as String? ?? '',
        currentShowTitle: d['currentShowTitle'] as String? ?? 'Lion FM 91.1 MHz',
        currentHostName: d['currentHostName'] as String? ?? '',
        streamBitrate: (d['streamBitrate'] as num?)?.toInt() ?? 128,
        streamUrl: d['streamUrl'] as String? ?? '',
        lastCheckedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (_) {
      return _offline();
    }
  }

  StreamStatusModel _offline() => StreamStatusModel(
        isLive: false,
        listenerCount: 0,
        currentShowId: '',
        currentShowTitle: 'Lion FM 91.1 MHz',
        currentHostName: '',
        streamBitrate: 128,
        streamUrl: '',
        lastCheckedAt: DateTime.now(),
      );
}
