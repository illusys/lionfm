import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';

const _guestUser = UserModel(
  id: 'guest_01',
  name: 'Lion FM Listener',
  email: 'listener@unn.edu.ng',
);

class UserNotifier extends StateNotifier<UserModel> {
  UserNotifier() : super(_guestUser) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_bindUser);
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  void _bindUser(User? firebaseUser) {
    _profileSub?.cancel();
    if (firebaseUser == null) {
      state = _guestUser;
      return;
    }
    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .snapshots()
        .listen((doc) {
      state = UserModel.fromFirestore(
        firebaseUser.uid,
        doc.data() ?? <String, dynamic>{},
        fallbackName: firebaseUser.displayName ?? 'Lion FM Listener',
        fallbackEmail: firebaseUser.email ?? '',
      );
    });
  }

  Future<void> _persist(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePremiumStatus(bool isPremium) async {
    // Premium is ultimately controlled by verified payment Cloud Functions.
    await _persist({'requestedPremiumUpgrade': isPremium});
  }

  Future<void> updateName(String name) =>
      _persist({'name': name, 'displayName': name});

  Future<void> updateEmail(String email) => _persist({'email': email});

  Future<void> toggleNotification(String type) async {
    final field = switch (type) {
      'showAlerts' => 'notifyShowAlerts',
      'breakingNews' => 'notifyBreakingNews',
      'requestConfirmation' => 'notifyRequestConfirmation',
      'specialEvents' => 'notifySpecialEvents',
      _ => null,
    };
    if (field == null) return;
    final current = switch (field) {
      'notifyShowAlerts' => state.notifyShowAlerts,
      'notifyBreakingNews' => state.notifyBreakingNews,
      'notifyRequestConfirmation' => state.notifyRequestConfirmation,
      'notifySpecialEvents' => state.notifySpecialEvents,
      _ => true,
    };
    await _persist({field: !current});
  }

  Future<void> setAudioQuality(AudioQuality quality) async {
    if (quality == AudioQuality.high && !state.isPremium) return;
    await _persist({'audioQuality': quality.name});
  }

  Future<void> incrementListeningTime(int minutes) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await _persist({'totalListeningMinutes': FieldValue.increment(minutes)});
  }

  Future<void> incrementEpisodesPlayed() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await _persist({'episodesPlayed': FieldValue.increment(1)});
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel>((ref) {
  return UserNotifier();
});
