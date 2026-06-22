import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/stream_status_model.dart';
import '../data/repositories/stream_repository.dart';
import '../core/constants/app_strings.dart';

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

// Whether the player is currently playing live stream vs episode
final isPlayingLiveProvider = StateProvider<bool>((ref) => true);

final reconnectingProvider = StateProvider<bool>((ref) => false);

final volumeProvider = StateProvider<double>((ref) => 0.75);

final isPlayingProvider = Provider<bool>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.playing;
});

// Playback state stream
final playbackStateStreamProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(audioPlayerProvider).playerStateStream;
});

// Reactively watches Firestore stream_config/current.streamUrl
final liveStreamUrlProvider = StreamProvider<String>((ref) {
  return FirebaseFirestore.instance
      .collection('stream_config')
      .doc('current')
      .snapshots()
      .map((doc) =>
          doc.data()?['streamUrl'] as String? ?? AppStrings.liveStreamUrl);
});

// Backwards-compatible synchronous read (returns last known value or default)
final currentStreamUrlProvider = Provider<String>((ref) {
  return ref.watch(liveStreamUrlProvider).valueOrNull ?? AppStrings.liveStreamUrl;
});
