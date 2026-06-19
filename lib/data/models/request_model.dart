import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_model.freezed.dart';
part 'request_model.g.dart';

enum RequestType { song, showPitch }

enum RequestStatus { pending, acknowledged, played }

@freezed
class RequestModel with _$RequestModel {
  const factory RequestModel({
    required String id,
    required RequestType type,
    String? songTitle,
    String? artistName,
    String? dedicatedTo,
    required String requesterName,
    String? requestedShow,
    String? message,
    String? showConceptName,
    String? department,
    String? preferredSlot,
    String? format,
    String? contactInfo,
    required DateTime submittedAt,
    @Default(RequestStatus.pending) RequestStatus status,
  }) = _RequestModel;

  factory RequestModel.fromJson(Map<String, dynamic> json) =>
      _$RequestModelFromJson(json);
}
