import '../models/stream_status_model.dart';

abstract class StreamRepository {
  Future<StreamStatusModel> getStreamStatus();
}

class MockStreamRepository implements StreamRepository {
  @override
  Future<StreamStatusModel> getStreamStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return StreamStatusModel(
      isLive: false,
      listenerCount: 0,
      currentShowId: '',
      currentShowTitle: 'Waiting for stream',
      currentHostName: '',
      streamBitrate: 128,
      streamUrl: '',
      lastCheckedAt: DateTime.now(),
    );
  }
}
