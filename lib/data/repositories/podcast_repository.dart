import '../models/episode_model.dart';

abstract class PodcastRepository {
  Future<List<EpisodeModel>> getEpisodes();
}

class MockPodcastRepository implements PodcastRepository {
  @override
  Future<List<EpisodeModel>> getEpisodes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      EpisodeModel(
        id: 'ep_01',
        showId: 'sat_02',
        showName: 'Health Talks',
        title: 'Managing Stress During Exams',
        description: 'UNN pharmacy students discuss practical strategies for managing academic stress, sleep hygiene, and mental health during exam season.',
        durationMinutes: 42,
        publishedAt: now.subtract(const Duration(days: 3)),
        audioUrl: 'https://podcast.lionfm.unn.edu.ng/episodes/ep_01.mp3',
        category: 'health',
      ),
      EpisodeModel(
        id: 'ep_02',
        showId: 'sat_03',
        showName: 'Tech & Career Forum',
        title: 'How to Land a Tech Job After UNN',
        description: 'Engr. Ada Obi breaks down everything you need — from building your portfolio to acing technical interviews at top Nigerian tech companies.',
        durationMinutes: 58,
        publishedAt: now.subtract(const Duration(days: 5)),
        audioUrl: 'https://podcast.lionfm.unn.edu.ng/episodes/ep_02.mp3',
        category: 'tech',
      ),
      EpisodeModel(
        id: 'ep_03',
        showId: 'sat_01',
        showName: 'Morning Glory',
        title: 'Convocation Special 2025',
        description: 'DJ Emeka hosts a special convocation episode covering the 2025 UNN graduation ceremony highlights and alumni stories.',
        durationMinutes: 35,
        publishedAt: now.subtract(const Duration(days: 7)),
        audioUrl: 'https://podcast.lionfm.unn.edu.ng/episodes/ep_03.mp3',
        category: 'news',
      ),
      EpisodeModel(
        id: 'ep_04',
        showId: 'sat_02',
        showName: 'Health Talks',
        title: 'Sexual & Reproductive Health Q&A',
        description: 'An open, informative discussion on sexual and reproductive health tailored for university students, with expert responses to listener questions.',
        durationMinutes: 50,
        publishedAt: now.subtract(const Duration(days: 10)),
        audioUrl: 'https://podcast.lionfm.unn.edu.ng/episodes/ep_04.mp3',
        category: 'health',
      ),
      EpisodeModel(
        id: 'ep_05',
        showId: 'sat_06',
        showName: 'Afternoon Drive',
        title: 'Best of Afrobeats Top 20',
        description: 'DJ Chi counts down the 20 hottest Afrobeats tracks of the month — from Burna Boy to Asake, Rema to Wizkid.',
        durationMinutes: 120,
        publishedAt: now.subtract(const Duration(days: 2)),
        audioUrl: 'https://podcast.lionfm.unn.edu.ng/episodes/ep_05.mp3',
        category: 'music',
      ),
      EpisodeModel(
        id: 'ep_06',
        showId: 'sat_03',
        showName: 'Tech & Career Forum',
        title: 'Building Your First Flutter App',
        description: 'A beginner-friendly deep dive into Flutter development — from setting up your environment to publishing your first app on the Play Store.',
        durationMinutes: 75,
        publishedAt: now.subtract(const Duration(days: 14)),
        audioUrl: 'https://podcast.lionfm.unn.edu.ng/episodes/ep_06.mp3',
        category: 'tech',
      ),
      EpisodeModel(
        id: 'ep_07',
        showId: 'sat_05',
        showName: 'SUG Spotlight',
        title: 'Election Results Analysis',
        description: 'A post-election breakdown of the Student Union Government elections — winners, margins, and what the results mean for UNN students.',
        durationMinutes: 45,
        publishedAt: now.subtract(const Duration(days: 21)),
        audioUrl: 'https://podcast.lionfm.unn.edu.ng/episodes/ep_07.mp3',
        category: 'news',
      ),
      EpisodeModel(
        id: 'ep_08',
        showId: 'sat_08',
        showName: 'Night Owls',
        title: '3-Hour Lo-fi Study Session',
        description: 'Three uninterrupted hours of lo-fi beats, ambient jazz, and chill instrumentals — the perfect study companion for any UNN night owl.',
        durationMinutes: 180,
        publishedAt: now.subtract(const Duration(days: 1)),
        audioUrl: 'https://podcast.lionfm.unn.edu.ng/episodes/ep_08.mp3',
        category: 'music',
      ),
    ];
  }
}
