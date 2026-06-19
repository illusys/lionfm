import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';

class UserNotifier extends StateNotifier<UserModel> {
  UserNotifier()
      : super(const UserModel(
          id: 'guest_01',
          name: 'Lion FM Listener',
          email: 'listener@unn.edu.ng',
        ));

  void updatePremiumStatus(bool isPremium) {
    state = state.copyWith(
      isPremium: isPremium,
      subscriptionExpiresAt: isPremium
          ? DateTime.now().add(const Duration(days: 30))
          : null,
      audioQuality: isPremium ? AudioQuality.high : AudioQuality.standard,
    );
  }

  void updateName(String name) => state = state.copyWith(name: name);
  void updateEmail(String email) => state = state.copyWith(email: email);

  void toggleNotification(String type) {
    switch (type) {
      case 'showAlerts':
        state = state.copyWith(notifyShowAlerts: !state.notifyShowAlerts);
      case 'breakingNews':
        state = state.copyWith(notifyBreakingNews: !state.notifyBreakingNews);
      case 'requestConfirmation':
        state = state.copyWith(notifyRequestConfirmation: !state.notifyRequestConfirmation);
      case 'specialEvents':
        state = state.copyWith(notifySpecialEvents: !state.notifySpecialEvents);
    }
  }

  void setAudioQuality(AudioQuality quality) {
    if (quality == AudioQuality.high && !state.isPremium) return;
    state = state.copyWith(audioQuality: quality);
  }

  void incrementListeningTime(int minutes) {
    state = state.copyWith(
      totalListeningMinutes: state.totalListeningMinutes + minutes,
    );
  }

  void incrementEpisodesPlayed() {
    state = state.copyWith(episodesPlayed: state.episodesPlayed + 1);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel>((ref) {
  return UserNotifier();
});
