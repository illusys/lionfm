import '../models/stream_status_model.dart';

abstract class StreamRepository {
  Future<StreamStatusModel> getStreamStatus();
}

class MockStreamRepository implements StreamRepository {
  static const String _liveStreamUrl =
      'https://stream.lionfm.unn.edu.ng/live/stream.m3u8';

  @override
  Future<StreamStatusModel> getStreamStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return StreamStatusModel(
      isLive: true,
      listenerCount: 312,
      currentShowId: 'sat_02',
      currentShowTitle: 'Health Talks with the Radio Pharmacist',
      currentHostName: 'UNN Pharmacy Students',
      streamBitrate: 128,
      streamUrl: _liveStreamUrl,
      lastCheckedAt: DateTime.now(),
    );
  }
}
