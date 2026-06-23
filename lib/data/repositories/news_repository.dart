import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';
import '../../core/utils/app_logger.dart';

abstract class NewsRepository {
  Future<List<NewsModel>> getNews();
}

/// Real Firestore-backed repository reading from 'news' collection.
class FirestoreNewsRepository implements NewsRepository {
  @override
  Future<List<NewsModel>> getNews() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .limit(30)
          .get();

      if (snap.docs.isEmpty) return _fallback();

      return snap.docs.map((doc) {
        final d = doc.data();
        final ts = d['publishedAt'];
        DateTime publishedAt;
        if (ts is Timestamp) {
          publishedAt = ts.toDate();
        } else if (ts is String) {
          publishedAt = DateTime.tryParse(ts) ?? DateTime.now();
        } else {
          publishedAt = DateTime.now();
        }

        return NewsModel(
          id: doc.id,
          headline: d['headline'] as String? ?? '',
          summary: d['summary'] as String? ?? '',
          category: _parseCategory(d['category'] as String?),
          publishedAt: publishedAt,
          imageUrl: d['imageUrl'] as String?,
          sourceUrl: d['sourceUrl'] as String? ?? '',
          isFeatured: d['isFeatured'] as bool? ?? false,
          readTimeMinutes: d['readTimeMinutes'] as int? ?? 2,
        );
      }).toList();
    } catch (e, st) {
      AppLogger.warning('News fetch failed; showing labelled sample content', e, st);
      return _fallback();
    }
  }

  NewsCategory _parseCategory(String? s) {
    return NewsCategory.values.firstWhere(
      (c) => c.name == s,
      orElse: () => NewsCategory.campus,
    );
  }

  /// Seed data shown while the 'news' Firestore collection is empty.
  List<NewsModel> _fallback() {
    final now = DateTime.now();
    return [
      NewsModel(
        id: 'news_01',
        headline: '[Sample] UNN CS Dept Wins National Hackathon Third Year Running',
        summary:
            "The University of Nigeria, Nsukka's Computer Science department "
            'has clinched the top prize at the 2025 National Tech Innovation '
            'Hackathon, beating 47 universities across Nigeria.',
        category: NewsCategory.campus,
        publishedAt: now.subtract(const Duration(hours: 2)),
        isFeatured: true,
        readTimeMinutes: 3,
        sourceUrl: 'https://www.lionfm.online/news/cs-hackathon-2025',
      ),
      NewsModel(
        id: 'news_02',
        headline: '[Sample] Registration Portal Opens Monday — Engineering Deadline Extended',
        summary:
            'The Academic Affairs division has announced an extension of the '
            'course registration deadline for Engineering students to June 28, 2025.',
        category: NewsCategory.academic,
        publishedAt: now.subtract(const Duration(hours: 5)),
        readTimeMinutes: 2,
        sourceUrl: 'https://www.lionfm.online/news/registration-extension',
      ),
      NewsModel(
        id: 'news_03',
        headline: '[Sample] UNN FC Defeats UNIZIK 3-1 in NUGA Qualifier',
        summary:
            "UNN's football team produced a commanding display against UNIZIK, "
            'securing their place in the NUGA Games knockout stage with a 3-1 victory.',
        category: NewsCategory.sports,
        publishedAt: now.subtract(const Duration(hours: 8)),
        readTimeMinutes: 2,
        sourceUrl: 'https://www.lionfm.online/news/unn-fc-nuga',
      ),
      NewsModel(
        id: 'news_04',
        headline: '[Sample] 2025 Convocation July 18-20, 8,400 Graduands Expected',
        summary:
            'The University has confirmed dates for the 2025 Convocation Ceremony. '
            'Over 8,400 students from the 2020/2021 session will receive their degrees.',
        category: NewsCategory.events,
        publishedAt: now.subtract(const Duration(hours: 12)),
        readTimeMinutes: 4,
        sourceUrl: 'https://www.lionfm.online/news/convocation-2025',
      ),
      NewsModel(
        id: 'news_05',
        headline: '[Sample] University Health Centre: Free Malaria Testing This Week',
        summary:
            'The UNN Health Centre is offering free malaria rapid diagnostic tests '
            'to all students and staff from June 19-23, 2025.',
        category: NewsCategory.health,
        publishedAt: now.subtract(const Duration(hours: 16)),
        readTimeMinutes: 2,
        sourceUrl: 'https://www.lionfm.online/news/malaria-testing',
      ),
    ];
  }
}

