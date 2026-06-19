import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_strings.dart';

class LionFMAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  static const String _primaryUrl = AppStrings.liveStreamUrl;
  static const String _fallbackUrl = AppStrings.fallbackStreamUrl;

  bool _isPlayingEpisode = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  LionFMAudioHandler() {
    _init();
  }

  void _init() {
    _player.playbackEventStream.listen(_broadcastState, onError: _handleError);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleError(null, null);
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  void _handleError(Object? error, StackTrace? stack) async {
    if (_retryCount >= _maxRetries) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
      return;
    }
    _retryCount++;
    await Future.delayed(const Duration(seconds: 5));
    try {
      final url = _retryCount > 1 ? _fallbackUrl : _primaryUrl;
      await _player.setUrl(url);
      await _player.play();
      _retryCount = 0;
    } catch (_) {
      _handleError(null, null);
    }
  }

  String getStreamUrl(String qualityBitrate) {
    return '$_primaryUrl?bitrate=$qualityBitrate';
  }

  Future<void> playLiveStream({String bitrate = '128'}) async {
    _isPlayingEpisode = false;
    _retryCount = 0;
    final url = getStreamUrl(bitrate);
    mediaItem.add(const MediaItem(
      id: 'live_stream',
      title: 'Lion FM 91.1 MHz',
      artist: 'Live Radio',
      album: 'University of Nigeria, Nsukka',
      artUri: Uri.parse('https://lionfm.unn.edu.ng/logo.png'),
    ));
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      _handleError(null, null);
    }
  }

  Future<void> playEpisode({
    required String url,
    required String title,
    required String showName,
    String? artUrl,
  }) async {
    _isPlayingEpisode = true;
    mediaItem.add(MediaItem(
      id: url,
      title: title,
      artist: showName,
      album: 'Lion FM Podcasts',
      artUri: artUrl != null ? Uri.parse(artUrl) : null,
    ));
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> returnToLiveStream() => playLiveStream();

  bool get isPlayingEpisode => _isPlayingEpisode;

  void updateMediaItem(String showTitle, String hostName) {
    mediaItem.add(MediaItem(
      id: 'live_stream',
      title: showTitle,
      artist: hostName,
      album: 'Lion FM 91.1 MHz · Live',
      artUri: Uri.parse('https://lionfm.unn.edu.ng/logo.png'),
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> onTaskRemoved() => stop();

  @override
  Future<void> onNotificationDeleted() => stop();

  AudioPlayer get player => _player;
}
