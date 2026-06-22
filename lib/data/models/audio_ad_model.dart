import 'package:cloud_firestore/cloud_firestore.dart';

class AudioAdModel {
  final String id;
  final String advertiserName;
  final int durationSec;
  final String audioUrl;
  final String? companionImageUrl;
  final String? clickUrl;
  final String placement; // 'preroll' | 'midroll' | 'liveBreak'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int impressions;
  final int completions;

  const AudioAdModel({
    required this.id,
    required this.advertiserName,
    required this.durationSec,
    required this.audioUrl,
    this.companionImageUrl,
    this.clickUrl,
    required this.placement,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.impressions = 0,
    this.completions = 0,
  });

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  factory AudioAdModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AudioAdModel(
      id: doc.id,
      advertiserName: d['advertiserName'] as String? ?? '',
      durationSec: d['durationSec'] as int? ?? 30,
      audioUrl: d['audioUrl'] as String? ?? '',
      companionImageUrl: d['companionImageUrl'] as String?,
      clickUrl: d['clickUrl'] as String?,
      placement: d['placement'] as String? ?? 'preroll',
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (d['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: d['isActive'] as bool? ?? true,
      impressions: d['impressions'] as int? ?? 0,
      completions: d['completions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': 'audio_instream',
        'advertiserName': advertiserName,
        'durationSec': durationSec,
        'audioUrl': audioUrl,
        'companionImageUrl': companionImageUrl,
        'clickUrl': clickUrl,
        'placement': placement,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'isActive': isActive,
        'impressions': impressions,
        'completions': completions,
      };
}
