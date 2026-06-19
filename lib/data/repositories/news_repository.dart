import '../models/news_model.dart';

abstract class NewsRepository {
  Future<List<NewsModel>> getNews();
}

class MockNewsRepository implements NewsRepository {
  @override
  Future<List<NewsModel>> getNews() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      NewsModel(
        id: 'news_01',
        headline: 'UNN CS Dept Wins National Hackathon Third Year Running',
        summary: 'The University of Nigeria, Nsukka\'s Computer Science department has clinched the top prize at the 2025 National Tech Innovation Hackathon, beating 47 universities across Nigeria.',
        category: NewsCategory.campus,
        publishedAt: now.subtract(const Duration(hours: 2)),
        isFeatured: true,
        readTimeMinutes: 3,
        sourceUrl: 'https://lionfm.unn.edu.ng/news/cs-hackathon-2025',
      ),
      NewsModel(
        id: 'news_02',
        headline: 'Registration Portal Opens Monday — Engineering Deadline Extended',
        summary: 'The Academic Affairs division has announced an extension of the course registration deadline for Engineering students to June 28, 2025.',
        category: NewsCategory.academic,
        publishedAt: now.subtract(const Duration(hours: 5)),
        readTimeMinutes: 2,
        sourceUrl: 'https://lionfm.unn.edu.ng/news/registration-extension',
      ),
      NewsModel(
        id: 'news_03',
        headline: 'UNN FC Defeats UNIZIK 3-1 in NUGA Qualifier',
        summary: 'UNN\'s football team produced a commanding display against UNIZIK, securing their place in the NUGA Games knockout stage with a 3-1 victory.',
        category: NewsCategory.sports,
        publishedAt: now.subtract(const Duration(hours: 8)),
        readTimeMinutes: 2,
        sourceUrl: 'https://lionfm.unn.edu.ng/news/unn-fc-nuga',
      ),
      NewsModel(
        id: 'news_04',
        headline: '2025 Convocation July 18-20, 8,400 Graduands Expected',
        summary: 'The University has confirmed dates for the 2025 Convocation Ceremony. Over 8,400 students from the 2020/2021 session will receive their degrees.',
        category: NewsCategory.events,
        publishedAt: now.subtract(const Duration(hours: 12)),
        readTimeMinutes: 4,
        sourceUrl: 'https://lionfm.unn.edu.ng/news/convocation-2025',
      ),
      NewsModel(
        id: 'news_05',
        headline: 'University Health Centre: Free Malaria Testing This Week',
        summary: 'The UNN Health Centre is offering free malaria rapid diagnostic tests to all students and staff from June 19-23, 2025.',
        category: NewsCategory.health,
        publishedAt: now.subtract(const Duration(hours: 16)),
        readTimeMinutes: 2,
        sourceUrl: 'https://lionfm.unn.edu.ng/news/malaria-testing',
      ),
      NewsModel(
        id: 'news_06',
        headline: 'Prof. Ngozi Obi-Adaora Wins National Research Award',
        summary: 'UNN\'s Prof. Ngozi Obi-Adaora of the Faculty of Pharmaceutical Sciences has been awarded the 2025 Nigerian Academy of Science Research Excellence Prize.',
        category: NewsCategory.academic,
        publishedAt: now.subtract(const Duration(hours: 24)),
        readTimeMinutes: 3,
        sourceUrl: 'https://lionfm.unn.edu.ng/news/prof-obi-award',
      ),
      NewsModel(
        id: 'news_07',
        headline: 'Lion FM Live Concert June 28 at Main Square',
        summary: 'Lion FM 91.1 MHz is organizing a live music concert on June 28 at the UNN Main Square featuring top campus artists and special guests.',
        category: NewsCategory.events,
        publishedAt: now.subtract(const Duration(hours: 30)),
        readTimeMinutes: 3,
        sourceUrl: 'https://lionfm.unn.edu.ng/news/concert-june28',
      ),
      NewsModel(
        id: 'news_08',
        headline: 'Power Supply Restored to South Campus Hostels',
        summary: 'EEDC and the UNN Works Department have restored electricity to the South Campus hostels following a 72-hour outage caused by a transformer fault.',
        category: NewsCategory.campus,
        publishedAt: now.subtract(const Duration(hours: 36)),
        readTimeMinutes: 2,
        sourceUrl: 'https://lionfm.unn.edu.ng/news/power-restored',
      ),
    ];
  }
}
