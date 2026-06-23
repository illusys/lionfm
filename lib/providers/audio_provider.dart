import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/episode_model.dart';
import '../data/models/stream_status_model.dart';
import '../data/repositories/stream_repository.dart';
import '../data/services/audio_service.dart';
import '../core/utils/app_logger.dart';

// ─── Core handler (singleton) ─────────────────────────────────────────────────

final audioHandlerProvider = Provider<LionFMAudioHandler>((ref) {
  final handler = LionFMAudioHandler();

  // Wire Riverpod state so any widget can react to source/episode changes
  handler.onSourceChanged = (source, episode, adDurationSec) {
    ref.read(currentAudioSourceProvider.notifier).state = source;
    ref.read(currentEpisodeProvider.notifier).state = episode;
    ref.read(currentAdDurationProvider.notifier).state = adDurationSec;
  };

  ref.onDispose(handler.dispose);
  return handler;
});

// Derived — keeps the raw AudioPlayer accessible for existing stream providers
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  return ref.watch(audioHandlerProvider).player;
});

// ─── Current playback source ──────────────────────────────────────────────────

final currentAudioSourceProvider =
    StateProvider<AudioSourceType>((ref) => AudioSourceType.liveRadio);

final currentEpisodeProvider = StateProvider<EpisodeModel?>((ref) => null);

final currentAdDurationProvider = StateProvider<int>((ref) => 0);

// ─── Playback state streams (derived from the single AudioPlayer) ─────────────

final playbackStateStreamProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(audioPlayerProvider).playerStateStream;
});

final positionStreamProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioPlayerProvider).positionStream;
});

final durationStreamProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(audioPlayerProvider).durationStream;
});

// ─── Live stream URL (from Firestore) ─────────────────────────────────────────

final liveStreamUrlProvider = StreamProvider<String>((ref) {
  return FirebaseFirestore.instance
      .collection('stream_config')
      .doc('current')
      .snapshots()
      .map((doc) => doc.data()?['streamUrl'] as String? ?? '');
});

final currentStreamUrlProvider = Provider<String>((ref) {
  return ref.watch(liveStreamUrlProvider).valueOrNull ?? '';
});

// ─── Volume (persisted via handler) ───────────────────────────────────────────

final volumeProvider = StateProvider<double>((ref) => 0.75);

// ─── Stream status ────────────────────────────────────────────────────────────

final streamRepositoryProvider = Provider<StreamRepository>((ref) {
  return FirestoreStreamRepository();
});

final streamStatusProvider = StreamProvider<StreamStatusModel>((ref) async* {
  final repo = ref.watch(streamRepositoryProvider);
  while (true) {
    try {
      yield await repo.getStreamStatus();
    } catch (e, st) {
      AppLogger.warning('Stream status poll failed', e, st);
    }
    await Future.delayed(const Duration(seconds: 30));
  }
});

final reconnectingProvider = StateProvider<bool>((ref) => false);
