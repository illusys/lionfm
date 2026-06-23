import 'package:flutter_test/flutter_test.dart';
import 'package:lionfm/data/models/request_model.dart';

void main() {
  test('request JSON round trip preserves moderation fields', () {
    final model = RequestModel(
      id: '1',
      type: RequestType.song,
      songTitle: 'Song',
      artistName: 'Artist',
      requesterName: 'Listener',
      submittedAt: DateTime.utc(2026, 1, 1),
      status: RequestStatus.acknowledged,
      moderationNotes: 'Play during drive time',
      assignedTo: 'host-a',
    );

    final parsed = RequestModel.fromJson(model.toJson());
    expect(parsed.status, RequestStatus.acknowledged);
    expect(parsed.moderationNotes, 'Play during drive time');
    expect(parsed.assignedTo, 'host-a');
  });
}
