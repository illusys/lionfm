import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum AudioQuality { dataSaver, standard, high }

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    @Default(false) bool isPremium,
    DateTime? subscriptionExpiresAt,
    @Default(true) bool notifyShowAlerts,
    @Default(true) bool notifyBreakingNews,
    @Default(true) bool notifyRequestConfirmation,
    @Default(true) bool notifySpecialEvents,
    @Default(AudioQuality.standard) AudioQuality audioQuality,
    @Default(0) int totalListeningMinutes,
    @Default(0) int episodesPlayed,
    @Default('Music') String topCategory,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
