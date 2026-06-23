import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonalizationService {
  PersonalizationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Stream<Set<String>> watchFollowedShows() => _watchIdSet('followedShows');
  Stream<Set<String>> watchSavedEpisodes() => _watchIdSet('savedEpisodes');
  Stream<List<String>> watchRecentlyPlayedEpisodes() => _watchList('recentlyPlayedEpisodes');

  Future<void> setShowFollowed(String showId, bool followed) =>
      _setInMap('followedShows', showId, followed);

  Future<void> setEpisodeSaved(String episodeId, bool saved) =>
      _setInMap('savedEpisodes', episodeId, saved);

  Future<void> recordRecentlyPlayed(String episodeId) async {
    final uid = _uid;
    if (uid == null) return;
    final ref = _db.collection('users').doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['recentlyPlayedEpisodes'] as List<dynamic>? ?? [])
          .cast<String>();
      final updated = [episodeId, ...current.where((id) => id != episodeId)].take(20).toList();
      tx.set(ref, {'recentlyPlayedEpisodes': updated}, SetOptions(merge: true));
    });
  }

  Future<void> setShowReminderMinutes(String showId, int minutesBefore) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'showReminderMinutes.$showId': minutesBefore,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _setInMap(String field, String id, bool value) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      '$field.$id': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Set<String>> _watchIdSet(String field) {
    final uid = _uid;
    if (uid == null) return Stream.value(<String>{});
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final map = doc.data()?[field] as Map<String, dynamic>? ?? {};
      return map.entries.where((e) => e.value == true).map((e) => e.key).toSet();
    });
  }

  Stream<List<String>> _watchList(String field) {
    final uid = _uid;
    if (uid == null) return Stream.value(<String>[]);
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => (doc.data()?[field] as List<dynamic>? ?? []).cast<String>(),
        );
  }
}
