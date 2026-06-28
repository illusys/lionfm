import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum StationPlan { free, starter, pro, enterprise }

enum StationPlanStatus { trialing, active, pastDue, suspended }

class StationBrandColors {
  final String primary;
  final String secondary;
  final String accent;
  final String background;

  const StationBrandColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
  });

  static const StationBrandColors lionDefaults = StationBrandColors(
    primary: '#1E9B43',
    secondary: '#28D7D2',
    accent: '#C89A29',
    background: '#0A0A0A',
  );

  factory StationBrandColors.fromMap(Map<String, dynamic> map) {
    return StationBrandColors(
      primary: map['primary'] as String? ?? '#1E9B43',
      secondary: map['secondary'] as String? ?? '#28D7D2',
      accent: map['accent'] as String? ?? '#C89A29',
      background: map['background'] as String? ?? '#0A0A0A',
    );
  }

  Map<String, dynamic> toMap() => {
        'primary': primary,
        'secondary': secondary,
        'accent': accent,
        'background': background,
      };

  Color get primaryColor => _hex(primary);
  Color get secondaryColor => _hex(secondary);
  Color get accentColor => _hex(accent);
  Color get backgroundColor => _hex(background);

  static Color _hex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'ff$h' : h, radix: 16));
  }

  StationBrandColors copyWith({
    String? primary,
    String? secondary,
    String? accent,
    String? background,
  }) =>
      StationBrandColors(
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        accent: accent ?? this.accent,
        background: background ?? this.background,
      );
}

class Station {
  final String stationId;
  final String name;
  final String slug;
  final String frequency;
  final String tagline;
  final String logoUrl;
  final String faviconUrl;
  final StationBrandColors brandColors;
  final String streamUrl;
  final String streamType;
  final StationPlan plan;
  final StationPlanStatus planStatus;
  final DateTime? trialEndsAt;
  final String ownerUid;
  final String contactEmail;
  final String? customDomain;
  final bool isActive;
  final bool isFeatured;
  final int listenerCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Station({
    required this.stationId,
    required this.name,
    required this.slug,
    required this.frequency,
    required this.tagline,
    required this.logoUrl,
    required this.faviconUrl,
    required this.brandColors,
    required this.streamUrl,
    required this.streamType,
    required this.plan,
    required this.planStatus,
    this.trialEndsAt,
    required this.ownerUid,
    required this.contactEmail,
    this.customDomain,
    required this.isActive,
    required this.isFeatured,
    required this.listenerCount,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSuspended => planStatus == StationPlanStatus.suspended;
  bool get isTrialing => planStatus == StationPlanStatus.trialing;
  bool get isPastDue => planStatus == StationPlanStatus.pastDue;

  static StationPlan _parsePlan(String? s) => switch (s) {
        'starter' => StationPlan.starter,
        'pro' => StationPlan.pro,
        'enterprise' => StationPlan.enterprise,
        _ => StationPlan.free,
      };

  static String _serializePlan(StationPlan p) => switch (p) {
        StationPlan.starter => 'starter',
        StationPlan.pro => 'pro',
        StationPlan.enterprise => 'enterprise',
        StationPlan.free => 'free',
      };

  static StationPlanStatus _parseStatus(String? s) => switch (s) {
        'trialing' => StationPlanStatus.trialing,
        'past_due' => StationPlanStatus.pastDue,
        'suspended' => StationPlanStatus.suspended,
        _ => StationPlanStatus.active,
      };

  static String _serializeStatus(StationPlanStatus s) => switch (s) {
        StationPlanStatus.trialing => 'trialing',
        StationPlanStatus.pastDue => 'past_due',
        StationPlanStatus.suspended => 'suspended',
        StationPlanStatus.active => 'active',
      };

  factory Station.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Station(
      stationId: doc.id,
      name: d['name'] as String? ?? '',
      slug: d['slug'] as String? ?? doc.id,
      frequency: d['frequency'] as String? ?? '',
      tagline: d['tagline'] as String? ?? '',
      logoUrl: d['logoUrl'] as String? ?? '',
      faviconUrl: d['faviconUrl'] as String? ?? '',
      brandColors: StationBrandColors.fromMap(
        Map<String, dynamic>.from(d['brandColors'] as Map? ?? {}),
      ),
      streamUrl: d['streamUrl'] as String? ?? '',
      streamType: d['streamType'] as String? ?? 'byo',
      plan: _parsePlan(d['plan'] as String?),
      planStatus: _parseStatus(d['planStatus'] as String?),
      trialEndsAt: (d['trialEndsAt'] as Timestamp?)?.toDate(),
      ownerUid: d['ownerUid'] as String? ?? '',
      contactEmail: d['contactEmail'] as String? ?? '',
      customDomain: d['customDomain'] as String?,
      isActive: d['isActive'] as bool? ?? true,
      isFeatured: d['isFeatured'] as bool? ?? false,
      listenerCount: d['listenerCount'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'stationId': stationId,
        'name': name,
        'slug': slug,
        'frequency': frequency,
        'tagline': tagline,
        'logoUrl': logoUrl,
        'faviconUrl': faviconUrl,
        'brandColors': brandColors.toMap(),
        'streamUrl': streamUrl,
        'streamType': streamType,
        'plan': _serializePlan(plan),
        'planStatus': _serializeStatus(planStatus),
        'trialEndsAt':
            trialEndsAt != null ? Timestamp.fromDate(trialEndsAt!) : null,
        'ownerUid': ownerUid,
        'contactEmail': contactEmail,
        'customDomain': customDomain,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'listenerCount': listenerCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  Station copyWith({
    String? stationId,
    String? name,
    String? slug,
    String? frequency,
    String? tagline,
    String? logoUrl,
    String? faviconUrl,
    StationBrandColors? brandColors,
    String? streamUrl,
    String? streamType,
    StationPlan? plan,
    StationPlanStatus? planStatus,
    DateTime? trialEndsAt,
    String? ownerUid,
    String? contactEmail,
    String? customDomain,
    bool? isActive,
    bool? isFeatured,
    int? listenerCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Station(
        stationId: stationId ?? this.stationId,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        frequency: frequency ?? this.frequency,
        tagline: tagline ?? this.tagline,
        logoUrl: logoUrl ?? this.logoUrl,
        faviconUrl: faviconUrl ?? this.faviconUrl,
        brandColors: brandColors ?? this.brandColors,
        streamUrl: streamUrl ?? this.streamUrl,
        streamType: streamType ?? this.streamType,
        plan: plan ?? this.plan,
        planStatus: planStatus ?? this.planStatus,
        trialEndsAt: trialEndsAt ?? this.trialEndsAt,
        ownerUid: ownerUid ?? this.ownerUid,
        contactEmail: contactEmail ?? this.contactEmail,
        customDomain: customDomain ?? this.customDomain,
        isActive: isActive ?? this.isActive,
        isFeatured: isFeatured ?? this.isFeatured,
        listenerCount: listenerCount ?? this.listenerCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
