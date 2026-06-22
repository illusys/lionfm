import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/episode_model.dart';
import '../../services/rss_service.dart';

abstract class PodcastRepository {
  Future<List<EpisodeModel>> getEpisodes();
}

class FirestoreEpisodeRepository implements PodcastRepository {
  final _rss = RssService();

  @override
  Future<List<EpisodeModel>> getEpisodes() async {
    final results = await Future.wait([
      _fetchRssEpisodes(),
      _fetchUploadedEpisodes(),
    ]);
    final all = [...results[0], ...results[1]];
    all.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return all;
  }

  Future<List<EpisodeModel>> _fetchRssEpisodes() async {
    try {
      final feedsSnap = await FirebaseFirestore.instance
          .collection('podcast_feeds')
          .where('isActive', isEqualTo: true)
          .get();

      final futures = feedsSnap.docs.map((doc) async {
        final url = doc.data()['url'] as String? ?? '';
        final name = doc.data()['name'] as String? ?? 'Podcast';
        if (url.isEmpty) return <EpisodeModel>[];
        final rssEpisodes = await _rss.fetchFeed(url, feedName: name);
        return rssEpisodes.map((e) => EpisodeModel(
              id: '${doc.id}_${e.title.hashCode}',
              showId: doc.id,
              showName: e.feedName ?? name,
              title: e.title,
              description: e.description,
              durationMinutes: _parseDuration(e.duration),
              publishedAt: e.pubDate ?? DateTime.now(),
              audioUrl: e.audioUrl ?? '',
              imageUrl: e.imageUrl,
              category: doc.data()['category'] as String? ?? 'podcast',
            )).toList();
      });

      final nested = await Future.wait(futures);
      return nested.expand((e) => e).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<EpisodeModel>> _fetchUploadedEpisodes() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('podcasts')
          .orderBy('publishedAt', descending: true)
          .limit(50)
          .get();

      return snap.docs.map((doc) {
        final d = doc.data();
        final ts = d['publishedAt'];
        DateTime pub;
        if (ts is Timestamp) {
          pub = ts.toDate();
        } else if (ts is String) {
          pub = DateTime.tryParse(ts) ?? DateTime.now();
        } else {
          pub = DateTime.now();
        }
        return EpisodeModel(
          id: doc.id,
          showId: d['showId'] as String? ?? '',
          showName: d['showName'] as String? ?? 'Lion FM',
          title: d['title'] as String? ?? '',
          description: d['description'] as String? ?? '',
          durationMinutes: d['durationMinutes'] as int? ?? 0,
          publishedAt: pub,
          audioUrl: d['audioUrl'] as String? ?? '',
          imageUrl: d['imageUrl'] as String?,
          category: d['category'] as String? ?? 'podcast',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  int _parseDuration(String? s) {
    if (s == null || s.isEmpty) return 0;
    final parts = s.split(':');
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 60 +
          (int.tryParse(parts[1]) ?? 0);
    } else if (parts.length == 2) {
      return int.tryParse(parts[0]) ?? 0;
    }
    return int.tryParse(s) ?? 0;
  }
}

// Kept for fallback only; replaced by FirestoreEpisodeRepository
class MockPodcastRepository implements PodcastRepository {
  @override
  Future<List<EpisodeModel>> getEpisodes() async {
    return [];
  }
}
