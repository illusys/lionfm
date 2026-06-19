import '../models/show_model.dart';

abstract class ScheduleRepository {
  Future<List<ShowModel>> getShowsForDay(String dayOfWeek);
  Future<ShowModel?> getCurrentShow();
}

class MockScheduleRepository implements ScheduleRepository {
  DateTime _todayAt(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  List<ShowModel> _saturdayShows() => [
        ShowModel(
          id: 'sat_01',
          title: 'Morning Glory',
          hostName: 'DJ Emeka',
          description: 'Campus news, weather, and the perfect morning mix to start your Saturday right.',
          startTime: _todayAt(6, 0),
          endTime: _todayAt(8, 0),
          dayOfWeek: 'Saturday',
          category: ShowCategory.music,
          tags: ['morning', 'news', 'music'],
          isRecurring: true,
        ),
        ShowModel(
          id: 'sat_02',
          title: 'Health Talks with the Radio Pharmacist',
          hostName: 'UNN Pharmacy Students',
          description: 'Expert health advice from UNN\'s finest pharmacy students. Call in with your health questions.',
          startTime: _todayAt(8, 0),
          endTime: _todayAt(10, 0),
          dayOfWeek: 'Saturday',
          category: ShowCategory.health,
          tags: ['health', 'pharmacy', 'wellness', 'call-in'],
          isRecurring: true,
        ),
        ShowModel(
          id: 'sat_03',
          title: 'Tech & Career Forum',
          hostName: 'Engr. Ada Obi',
          description: 'Your gateway to tech careers, startup culture, and digital innovation at UNN and beyond.',
          startTime: _todayAt(10, 0),
          endTime: _todayAt(12, 0),
          dayOfWeek: 'Saturday',
          category: ShowCategory.tech,
          tags: ['tech', 'career', 'startups', 'engineering'],
          isRecurring: true,
        ),
        ShowModel(
          id: 'sat_04',
          title: 'Midday News Bulletin',
          hostName: 'Mass Comm Final Years',
          description: 'Comprehensive midday news coverage from the University and beyond, delivered by UNN\'s future journalists.',
          startTime: _todayAt(12, 0),
          endTime: _todayAt(14, 0),
          dayOfWeek: 'Saturday',
          category: ShowCategory.news,
          tags: ['news', 'bulletin', 'campus'],
          isRecurring: true,
        ),
        ShowModel(
          id: 'sat_05',
          title: 'SUG Spotlight',
          hostName: 'Student Union Government',
          description: 'Direct from the Student Union — updates, announcements, and student affairs discussions.',
          startTime: _todayAt(14, 0),
          endTime: _todayAt(16, 0),
          dayOfWeek: 'Saturday',
          category: ShowCategory.talkShow,
          tags: ['SUG', 'student', 'campus', 'governance'],
          isRecurring: true,
        ),
        ShowModel(
          id: 'sat_06',
          title: 'Afternoon Drive',
          hostName: 'DJ Chi',
          description: 'Afrobeats, Amapiano, and all your favourite campus vibes to power through the afternoon.',
          startTime: _todayAt(16, 0),
          endTime: _todayAt(19, 0),
          dayOfWeek: 'Saturday',
          category: ShowCategory.music,
          tags: ['afrobeats', 'music', 'campus', 'drive'],
          isRecurring: true,
        ),
        ShowModel(
          id: 'sat_07',
          title: 'Evening Devotion',
          hostName: 'UNN Chapel Team',
          description: 'Spiritual upliftment and evening reflection with the University Chapel team.',
          startTime: _todayAt(19, 0),
          endTime: _todayAt(20, 0),
          dayOfWeek: 'Saturday',
          category: ShowCategory.devotion,
          tags: ['devotion', 'spiritual', 'chapel'],
          isRecurring: true,
        ),
        ShowModel(
          id: 'sat_08',
          title: 'Night Owls',
          hostName: 'Chukwudi A.',
          description: 'Lo-fi beats, jazz, and late-night conversation for the night owls of UNN.',
          startTime: _todayAt(20, 0),
          endTime: _todayAt(23, 59),
          dayOfWeek: 'Saturday',
          category: ShowCategory.music,
          tags: ['lo-fi', 'jazz', 'night', 'chill'],
          isRecurring: true,
        ),
      ];

  List<ShowModel> _weekdayShows(String day) => [
        ShowModel(
          id: '${day}_01',
          title: 'Morning Glory',
          hostName: 'DJ Emeka',
          description: 'Start your day right with campus news, weather updates, and the best morning mix.',
          startTime: _todayAt(6, 0),
          endTime: _todayAt(8, 0),
          dayOfWeek: day,
          category: ShowCategory.music,
          tags: ['morning', 'news'],
          isRecurring: true,
        ),
        ShowModel(
          id: '${day}_02',
          title: 'Campus Express',
          hostName: 'UNN News Desk',
          description: 'All the campus news you need, fast and accurate.',
          startTime: _todayAt(8, 0),
          endTime: _todayAt(10, 0),
          dayOfWeek: day,
          category: ShowCategory.news,
          tags: ['news', 'campus'],
          isRecurring: true,
        ),
        ShowModel(
          id: '${day}_03',
          title: 'Academic Hour',
          hostName: 'Various Lecturers',
          description: 'Educational programming covering UNN academic topics and research highlights.',
          startTime: _todayAt(10, 0),
          endTime: _todayAt(12, 0),
          dayOfWeek: day,
          category: ShowCategory.general,
          tags: ['academic', 'education'],
          isRecurring: true,
        ),
        ShowModel(
          id: '${day}_04',
          title: 'Midday Bulletin',
          hostName: 'Mass Comm Students',
          description: 'Your midday news roundup from around UNN and Nigeria.',
          startTime: _todayAt(12, 0),
          endTime: _todayAt(14, 0),
          dayOfWeek: day,
          category: ShowCategory.news,
          tags: ['news', 'bulletin'],
          isRecurring: true,
        ),
        ShowModel(
          id: '${day}_05',
          title: 'Afternoon Mix',
          hostName: 'DJ Chi',
          description: 'The best Afrobeats and contemporary hits to fuel your afternoon.',
          startTime: _todayAt(14, 0),
          endTime: _todayAt(17, 0),
          dayOfWeek: day,
          category: ShowCategory.music,
          tags: ['music', 'afrobeats'],
          isRecurring: true,
        ),
        ShowModel(
          id: '${day}_06',
          title: 'Night Owls',
          hostName: 'Chukwudi A.',
          description: 'Lo-fi and jazz to wind down the night.',
          startTime: _todayAt(20, 0),
          endTime: _todayAt(23, 59),
          dayOfWeek: day,
          category: ShowCategory.music,
          tags: ['lo-fi', 'jazz', 'night'],
          isRecurring: true,
        ),
      ];

  @override
  Future<List<ShowModel>> getShowsForDay(String dayOfWeek) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (dayOfWeek == 'Saturday') return _saturdayShows();
    if (dayOfWeek == 'Sunday') {
      return [
        ShowModel(
          id: 'sun_01',
          title: 'Sunday Service Live',
          hostName: 'UNN Chapel',
          description: 'Live coverage of the University Sunday service.',
          startTime: _todayAt(8, 0),
          endTime: _todayAt(11, 0),
          dayOfWeek: 'Sunday',
          category: ShowCategory.devotion,
          tags: ['devotion', 'chapel', 'live'],
        ),
        ShowModel(
          id: 'sun_02',
          title: 'Weekend Rewind',
          hostName: 'DJ Emeka',
          description: 'Best of the week\'s music and highlights.',
          startTime: _todayAt(14, 0),
          endTime: _todayAt(17, 0),
          dayOfWeek: 'Sunday',
          category: ShowCategory.music,
          tags: ['music', 'rewind'],
        ),
        ShowModel(
          id: 'sun_03',
          title: 'Night Owls',
          hostName: 'Chukwudi A.',
          description: 'Lo-fi and jazz to close out the weekend.',
          startTime: _todayAt(20, 0),
          endTime: _todayAt(23, 59),
          dayOfWeek: 'Sunday',
          category: ShowCategory.music,
          tags: ['lo-fi', 'jazz'],
        ),
      ];
    }
    return _weekdayShows(dayOfWeek);
  }

  @override
  Future<ShowModel?> getCurrentShow() async {
    final now = DateTime.now();
    final dayName = _dayName(now.weekday);
    final shows = await getShowsForDay(dayName);
    try {
      return shows.firstWhere((s) => s.getStatus(now) == ShowStatus.live);
    } catch (_) {
      return null;
    }
  }

  String _dayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}
