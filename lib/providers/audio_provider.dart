import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/stream_status_model.dart';
import '../data/repositories/stream_repository.dart';

// Singleton AudioPlayer
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final streamRepositoryProvider = Provider<StreamRepository>((ref) {
  return MockStreamRepository();
});

// Stream status, polled every 30s
final streamStatusProvider = StreamProvider<StreamStatusModel>((ref) async* {
  final repo = ref.watch(streamRepositoryProvider);
  while (true) {
    try {
      yield await repo.getStreamStatus();
    } catch (_) {
      // keep last known state on error
    }
    await Future.delayed(const Duration(seconds: 30));
  }
});

final isPlayingLiveProvider = StateProvider<bool>((ref) => true);
final reconnectingProvider = StateProvider<bool>((ref) => false);
final volumeProvider = StateProvider<double>((ref) => 0.75);

final isPlayingProvider = Provider<bool>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.playing;
});

final playbackStateStreamProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(audioPlayerProvider).playerStateStream;
});

// Reactively watches Firestore stream_config/current.streamUrl
// Returns '' (empty) when no URL configured — player must NOT auto-load in that case
final liveStreamUrlProvider = StreamProvider<String>((ref) {
  return FirebaseFirestore.instance
      .collection('stream_config')
      .doc('current')
      .snapshots()
      .map((doc) => doc.data()?['streamUrl'] as String? ?? '');
});

// Synchronous read: returns last known Firestore value or '' (never BBC)
final currentStreamUrlProvider = Provider<String>((ref) {
  return ref.watch(liveStreamUrlProvider).valueOrNull ?? '';
});
