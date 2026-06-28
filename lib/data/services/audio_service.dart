import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_ad_model.dart';
import '../models/episode_model.dart';

enum AudioSourceType { liveRadio, podcast, ad }

typedef AudioSourceChangedCallback = void Function(
  AudioSourceType source,
  EpisodeModel? episode,
  int adDurationSec,
);

/// Single app-wide audio pipeline. Exposes [player] for stream-based
/// Riverpod providers. All playback goes through this class — never
/// create a raw AudioPlayer anywhere else.
class LionFMAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioSourceType _currentSource = AudioSourceType.liveRadio;
  EpisodeModel? _currentEpisode;
  String? _currentAdId;
  int _currentAdDurationSec = 0;
  EpisodeModel? _pendingEpisodeAfterAd;
  String _currentStreamUrl = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<PlaybackEvent>? _eventSub;

  /// Called by the Riverpod layer to propagate state into providers.
  AudioSourceChangedCallback? onSourceChanged;

  LionFMAudioHandler() {
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
    _eventSub = _player.playbackEventStream.listen(
      (_) {},
      onError: _onPlaybackError,
    );
    _loadVolume();
  }

  // ─── Public getters ────────────────────────────────────────────────────────

  // Set by audioHandlerProvider after creation; used to scope ad queries.
  String stationId = 'lion';

  AudioPlayer get player => _player;
  AudioSourceType get currentSource => _currentSource;
  EpisodeModel? get currentEpisode => _currentEpisode;
  int get currentAdDurationSec => _currentAdDurationSec;

  // ─── Internal state machine ────────────────────────────────────────────────

  void _onPlayerState(PlayerState state) {
    if (state.processingState != ProcessingState.completed) return;
    switch (_currentSource) {
      case AudioSourceType.ad:
        final pending = _pendingEpisodeAfterAd;
        _pendingEpisodeAfterAd = null;
        if (_currentAdId != null) _trackAdCompletion(_currentAdId!);
        if (pending != null) _playEpisodeDirectly(pending);
      case AudioSourceType.liveRadio:
        _scheduleRetry();
      case AudioSourceType.podcast:
        break;
    }
  }

  void _onPlaybackError(Object _, StackTrace __) {
    if (_currentSource == AudioSourceType.liveRadio) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() async {
    if (_currentStreamUrl.isEmpty || _retryCount >= _maxRetries) return;
    _retryCount++;
    await Future.delayed(const Duration(seconds: 5));
    try {
      await _player.setAudioSource(AudioSource.uri(
        Uri.parse(_currentStreamUrl),
        tag: const MediaItem(
          id: 'live_radio',
          title: 'Lion FM Live',
          album: 'Lion FM 91.1 MHz',
        ),
      ));
      await _player.play();
      _retryCount = 0;
    } catch (_) {
      _scheduleRetry();
    }
  }

  // ─── Public playback API ───────────────────────────────────────────────────

  Future<void> playLiveRadio(String url) async {
    if (url.isEmpty) return;
    _currentSource = AudioSourceType.liveRadio;
    _currentStreamUrl = url;
    _currentEpisode = null;
    _pendingEpisodeAfterAd = null;
    _retryCount = 0;
    onSourceChanged?.call(AudioSourceType.liveRadio, null, 0);
    try {
      await _player.setAudioSource(AudioSource.uri(
        Uri.parse(url),
        tag: const MediaItem(
          id: 'live_radio',
          title: 'Lion FM Live',
          album: 'Lion FM 91.1 MHz',
        ),
      ));
      await _player.play();
    } catch (_) {
      _scheduleRetry();
    }
  }

  Future<void> playPodcast(
    EpisodeModel episode, {
    required bool isPremium,
  }) async {
    if (!isPremium) {
      final ad = await _fetchPrerollAd();
      if (ad != null) {
        _currentSource = AudioSourceType.ad;
        _currentAdId = ad.id;
        _currentAdDurationSec = ad.durationSec;
        _pendingEpisodeAfterAd = episode;
        onSourceChanged?.call(AudioSourceType.ad, null, ad.durationSec);
        try {
          await _player.setAudioSource(AudioSource.uri(
            Uri.parse(ad.audioUrl),
            tag: const MediaItem(
              id: 'ad',
              title: 'Sponsored',
              album: 'Lion FM',
            ),
          ));
          await _player.play();
          _trackAdImpression(ad.id);
          return;
        } catch (_) {
          // Ad failed — fall through to episode
          _pendingEpisodeAfterAd = null;
        }
      }
    }
    await _playEpisodeDirectly(episode);
  }

  Future<void> _playEpisodeDirectly(EpisodeModel episode) async {
    _currentSource = AudioSourceType.podcast;
    _currentEpisode = episode;
    onSourceChanged?.call(AudioSourceType.podcast, episode, 0);
    await _player.setAudioSource(AudioSource.uri(
      Uri.parse(episode.audioUrl),
      tag: MediaItem(
        id: episode.id,
        title: episode.title,
        album: episode.showName,
        artUri: episode.imageUrl != null
            ? Uri.tryParse(episode.imageUrl!)
            : null,
      ),
    ));
    await _player.play();
  }

  // ─── Seek controls (podcast only) ─────────────────────────────────────────

  Future<void> seekForward([Duration delta = const Duration(seconds: 30)]) async {
    if (_currentSource != AudioSourceType.podcast) return;
    final pos = _player.position;
    final dur = _player.duration ?? Duration.zero;
    final next = pos + delta;
    await _player.seek(next > dur ? dur : next);
  }

  Future<void> seekBackward([Duration delta = const Duration(seconds: 15)]) async {
    if (_currentSource != AudioSourceType.podcast) return;
    final pos = _player.position;
    final prev = pos - delta;
    await _player.seek(prev < Duration.zero ? Duration.zero : prev);
  }

  // ─── Volume (persisted) ────────────────────────────────────────────────────

  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    await _player.setVolume(v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('volume', v);
    } catch (_) {}
  }

  Future<void> _loadVolume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vol = prefs.getDouble('volume') ?? 0.75;
      await _player.setVolume(vol);
    } catch (_) {}
  }

  // ─── Pass-through controls ─────────────────────────────────────────────────

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  // ─── Ad helpers ────────────────────────────────────────────────────────────

  Future<AudioAdModel?> _fetchPrerollAd() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('ads')
          .where('stationId', isEqualTo: stationId)
          .where('type', isEqualTo: 'audio_instream')
          .where('isActive', isEqualTo: true)
          .where('placement', isEqualTo: 'preroll')
          .where('endDate',
              isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return AudioAdModel.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }

  void _trackAdImpression(String adId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(adId)
          .update({'impressions': FieldValue.increment(1)});
    } catch (_) {}
  }

  void _trackAdCompletion(String adId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(adId)
          .update({'completions': FieldValue.increment(1)});
    } catch (_) {}
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _stateSub?.cancel();
    await _eventSub?.cancel();
    await _player.dispose();
  }
}
