import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_status_model.freezed.dart';
part 'stream_status_model.g.dart';

@freezed
class StreamStatusModel with _$StreamStatusModel {
  const StreamStatusModel._();

  const factory StreamStatusModel({
    required bool isLive,
    required int listenerCount,
    String? currentShowId,
    required String currentShowTitle,
    required String currentHostName,
    required int streamBitrate,
    required String streamUrl,
    required DateTime lastCheckedAt,
  }) = _StreamStatusModel;

  bool get isHealthy =>
      isLive &&
      streamUrl.isNotEmpty &&
      DateTime.now().difference(lastCheckedAt).inMinutes < 2;

  factory StreamStatusModel.fromJson(Map<String, dynamic> json) =>
      _$StreamStatusModelFromJson(json);
}
