import 'package:cloud_firestore/cloud_firestore.dart';

enum AudioQuality { dataSaver, standard, high }

class UserModel {
  final String id;
  final String name;
  final String email;
  final bool isPremium;
  final DateTime? subscriptionExpiresAt;
  final bool notifyShowAlerts;
  final bool notifyBreakingNews;
  final bool notifyRequestConfirmation;
  final bool notifySpecialEvents;
  final AudioQuality audioQuality;
  final int totalListeningMinutes;
  final int episodesPlayed;
  final String topCategory;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.isPremium = false,
    this.subscriptionExpiresAt,
    this.notifyShowAlerts = true,
    this.notifyBreakingNews = true,
    this.notifyRequestConfirmation = true,
    this.notifySpecialEvents = true,
    this.audioQuality = AudioQuality.standard,
    this.totalListeningMinutes = 0,
    this.episodesPlayed = 0,
    this.topCategory = 'Music',
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    bool? isPremium,
    DateTime? subscriptionExpiresAt,
    bool? notifyShowAlerts,
    bool? notifyBreakingNews,
    bool? notifyRequestConfirmation,
    bool? notifySpecialEvents,
    AudioQuality? audioQuality,
    int? totalListeningMinutes,
    int? episodesPlayed,
    String? topCategory,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      notifyShowAlerts: notifyShowAlerts ?? this.notifyShowAlerts,
      notifyBreakingNews: notifyBreakingNews ?? this.notifyBreakingNews,
      notifyRequestConfirmation: notifyRequestConfirmation ?? this.notifyRequestConfirmation,
      notifySpecialEvents: notifySpecialEvents ?? this.notifySpecialEvents,
      audioQuality: audioQuality ?? this.audioQuality,
      totalListeningMinutes: totalListeningMinutes ?? this.totalListeningMinutes,
      episodesPlayed: episodesPlayed ?? this.episodesPlayed,
      topCategory: topCategory ?? this.topCategory,
    );
  }

  factory UserModel.fromFirestore(
    String id,
    Map<String, dynamic> json, {
    String fallbackName = 'Lion FM Listener',
    String fallbackEmail = '',
  }) {
    final expiry = json['subscriptionExpiresAt'];
    return UserModel(
      id: id,
      name: json['name'] as String? ?? json['displayName'] as String? ?? fallbackName,
      email: json['email'] as String? ?? fallbackEmail,
      isPremium: json['isPremium'] as bool? ?? false,
      subscriptionExpiresAt: expiry is Timestamp
          ? expiry.toDate()
          : DateTime.tryParse(expiry as String? ?? ''),
      notifyShowAlerts: json['notifyShowAlerts'] as bool? ?? true,
      notifyBreakingNews: json['notifyBreakingNews'] as bool? ?? true,
      notifyRequestConfirmation: json['notifyRequestConfirmation'] as bool? ?? true,
      notifySpecialEvents: json['notifySpecialEvents'] as bool? ?? true,
      audioQuality: AudioQuality.values.byName(json['audioQuality'] as String? ?? 'standard'),
      totalListeningMinutes: json['totalListeningMinutes'] as int? ?? 0,
      episodesPlayed: json['episodesPlayed'] as int? ?? 0,
      topCategory: json['topCategory'] as String? ?? 'Music',
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        isPremium: json['isPremium'] as bool? ?? false,
        subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
            ? DateTime.parse(json['subscriptionExpiresAt'] as String)
            : null,
        notifyShowAlerts: json['notifyShowAlerts'] as bool? ?? true,
        notifyBreakingNews: json['notifyBreakingNews'] as bool? ?? true,
        notifyRequestConfirmation: json['notifyRequestConfirmation'] as bool? ?? true,
        notifySpecialEvents: json['notifySpecialEvents'] as bool? ?? true,
        audioQuality: AudioQuality.values.byName(json['audioQuality'] as String? ?? 'standard'),
        totalListeningMinutes: json['totalListeningMinutes'] as int? ?? 0,
        episodesPlayed: json['episodesPlayed'] as int? ?? 0,
        topCategory: json['topCategory'] as String? ?? 'Music',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isPremium': isPremium,
        'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
        'notifyShowAlerts': notifyShowAlerts,
        'notifyBreakingNews': notifyBreakingNews,
        'notifyRequestConfirmation': notifyRequestConfirmation,
        'notifySpecialEvents': notifySpecialEvents,
        'audioQuality': audioQuality.name,
        'totalListeningMinutes': totalListeningMinutes,
        'episodesPlayed': episodesPlayed,
        'topCategory': topCategory,
      };
}
