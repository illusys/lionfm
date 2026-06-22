import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String? posterUrl;
  final String streamUrl;
  final DateTime startTime;
  final DateTime endTime;
  final int ticketPriceNGN;
  final bool isLive;
  final bool isPremiumFree;
  final String createdBy;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.posterUrl,
    required this.streamUrl,
    required this.startTime,
    required this.endTime,
    required this.ticketPriceNGN,
    this.isLive = false,
    this.isPremiumFree = true,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isUpcoming =>
      startTime.isAfter(DateTime.now()) && !isLive && !isPast;
  bool get isPast => endTime.isBefore(DateTime.now()) && !isLive;
  bool get isFree => ticketPriceNGN == 0;

  factory EventModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return EventModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      posterUrl: d['posterUrl'] as String?,
      streamUrl: d['streamUrl'] as String? ?? '',
      startTime: (d['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (d['endTime'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 2)),
      ticketPriceNGN: d['ticketPriceNGN'] as int? ?? 0,
      isLive: d['isLive'] as bool? ?? false,
      isPremiumFree: d['isPremiumFree'] as bool? ?? true,
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'posterUrl': posterUrl,
        'streamUrl': streamUrl,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'ticketPriceNGN': ticketPriceNGN,
        'isLive': isLive,
        'isPremiumFree': isPremiumFree,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
