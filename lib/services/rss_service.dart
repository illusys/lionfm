import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

class RssEpisode {
  final String title;
  final String description;
  final String? audioUrl;
  final DateTime? pubDate;
  final String? duration;
  final String? imageUrl;
  final String feedUrl;
  final String? feedName;

  const RssEpisode({
    required this.title,
    required this.description,
    this.audioUrl,
    this.pubDate,
    this.duration,
    this.imageUrl,
    required this.feedUrl,
    this.feedName,
  });
}

class RssService {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    responseType: ResponseType.plain,
  ));

  Future<List<RssEpisode>> fetchFeed(String feedUrl, {String? feedName}) async {
    try {
      final response = await _dio.get<String>(feedUrl);
      if (response.data == null) return [];

      final document = XmlDocument.parse(response.data!);
      final channelImageUrl = document
          .findAllElements('image')
          .firstOrNull
          ?.getElement('url')
          ?.innerText;

      return document.findAllElements('item').map((item) {
        final enclosure = item.getElement('enclosure');
        final itunesImage = item
            .findAllElements('itunes:image')
            .firstOrNull
            ?.getAttribute('href');

        return RssEpisode(
          title: item.getElement('title')?.innerText.trim() ?? '',
          description: item.getElement('description')?.innerText.trim() ?? '',
          audioUrl: enclosure?.getAttribute('url'),
          pubDate: _parseDate(item.getElement('pubDate')?.innerText),
          duration: item.findAllElements('itunes:duration').firstOrNull?.innerText,
          imageUrl: itunesImage ?? channelImageUrl,
          feedUrl: feedUrl,
          feedName: feedName,
        );
      }).where((e) => e.audioUrl != null && e.title.isNotEmpty).toList();
    } catch (e) {
      debugPrint('RssService fetch error ($feedUrl): $e');
      return [];
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {}
    // RFC 2822: "Mon, 22 Jan 2024 10:00:00 +0000"
    try {
      final parts = s.trim().split(RegExp(r'\s+'));
      if (parts.length >= 5) {
        const months = {
          'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
          'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
          'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
        };
        final day = parts[1].padLeft(2, '0');
        final month = months[parts[2]] ?? '01';
        final year = parts[3];
        final time = parts[4].split('+')[0].split('-')[0];
        return DateTime.parse('$year-$month-${day}T$time');
      }
    } catch (_) {}
    return null;
  }
}
