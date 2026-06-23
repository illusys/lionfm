import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestType { song, showPitch, shoutout }

enum RequestStatus { pending, acknowledged, played, skipped }

class RequestModel {
  final String id;
  final RequestType type;
  final String? songTitle;
  final String? artistName;
  final String? dedicatedTo;
  final String requesterName;
  final String? requestedShow;
  final String? message;
  final String? showConceptName;
  final String? department;
  final String? preferredSlot;
  final String? format;
  final String? contactInfo;
  final DateTime submittedAt;
  final RequestStatus status;
  final bool isPremium;
  final String? userId;
  final String? moderationNotes;
  final String? assignedTo;
  final DateTime? updatedAt;

  const RequestModel({
    required this.id,
    required this.type,
    this.songTitle,
    this.artistName,
    this.dedicatedTo,
    required this.requesterName,
    this.requestedShow,
    this.message,
    this.showConceptName,
    this.department,
    this.preferredSlot,
    this.format,
    this.contactInfo,
    required this.submittedAt,
    this.status = RequestStatus.pending,
    this.isPremium = false,
    this.userId,
    this.moderationNotes,
    this.assignedTo,
    this.updatedAt,
  });

  RequestModel copyWith({
    String? id,
    RequestType? type,
    String? songTitle,
    String? artistName,
    String? dedicatedTo,
    String? requesterName,
    String? requestedShow,
    String? message,
    String? showConceptName,
    String? department,
    String? preferredSlot,
    String? format,
    String? contactInfo,
    DateTime? submittedAt,
    RequestStatus? status,
    bool? isPremium,
    String? userId,
    String? moderationNotes,
    String? assignedTo,
    DateTime? updatedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      type: type ?? this.type,
      songTitle: songTitle ?? this.songTitle,
      artistName: artistName ?? this.artistName,
      dedicatedTo: dedicatedTo ?? this.dedicatedTo,
      requesterName: requesterName ?? this.requesterName,
      requestedShow: requestedShow ?? this.requestedShow,
      message: message ?? this.message,
      showConceptName: showConceptName ?? this.showConceptName,
      department: department ?? this.department,
      preferredSlot: preferredSlot ?? this.preferredSlot,
      format: format ?? this.format,
      contactInfo: contactInfo ?? this.contactInfo,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      userId: userId ?? this.userId,
      moderationNotes: moderationNotes ?? this.moderationNotes,
      assignedTo: assignedTo ?? this.assignedTo,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RequestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data()!;
    final ts = json['submittedAt'];
    DateTime submitted;
    if (ts is Timestamp) {
      submitted = ts.toDate();
    } else if (ts is String) {
      submitted = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      submitted = DateTime.now();
    }
    return RequestModel(
      id: doc.id,
      type: _typeFromString(json['type'] as String?),
      songTitle: json['songTitle'] as String?,
      artistName: json['artistName'] as String?,
      dedicatedTo: json['dedicatedTo'] as String?,
      requesterName: json['requesterName'] as String? ?? 'Anonymous',
      requestedShow: json['requestedShow'] as String?,
      message: json['message'] as String?,
      showConceptName: json['showConceptName'] as String?,
      department: json['department'] as String?,
      preferredSlot: json['preferredSlot'] as String?,
      format: json['format'] as String?,
      contactInfo: json['contactInfo'] as String?,
      submittedAt: submitted,
      status: _statusFromString(json['status'] as String?),
      isPremium: json['isPremium'] as bool? ?? false,
      userId: json['userId'] as String?,
      moderationNotes: json['moderationNotes'] as String?,
      assignedTo: json['assignedTo'] as String?,
      updatedAt: _dateFrom(json['updatedAt']),
    );
  }

  factory RequestModel.fromJson(Map<String, dynamic> json) => RequestModel(
        id: json['id'] as String,
        type: _typeFromString(json['type'] as String?),
        songTitle: json['songTitle'] as String?,
        artistName: json['artistName'] as String?,
        dedicatedTo: json['dedicatedTo'] as String?,
        requesterName: json['requesterName'] as String? ?? 'Anonymous',
        requestedShow: json['requestedShow'] as String?,
        message: json['message'] as String?,
        showConceptName: json['showConceptName'] as String?,
        department: json['department'] as String?,
        preferredSlot: json['preferredSlot'] as String?,
        format: json['format'] as String?,
        contactInfo: json['contactInfo'] as String?,
        submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ?? DateTime.now(),
        status: _statusFromString(json['status'] as String?),
        isPremium: json['isPremium'] as bool? ?? false,
        userId: json['userId'] as String?,
        moderationNotes: json['moderationNotes'] as String?,
        assignedTo: json['assignedTo'] as String?,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'songTitle': songTitle,
        'artistName': artistName,
        'dedicatedTo': dedicatedTo,
        'requesterName': requesterName,
        'requestedShow': requestedShow,
        'message': message,
        'showConceptName': showConceptName,
        'department': department,
        'preferredSlot': preferredSlot,
        'format': format,
        'contactInfo': contactInfo,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status.name,
        'isPremium': isPremium,
        'userId': userId,
        'moderationNotes': moderationNotes,
        'assignedTo': assignedTo,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> toFirestoreCreate({String? userId}) => {
        'type': type.name,
        'songTitle': songTitle,
        'artistName': artistName,
        'dedicatedTo': dedicatedTo,
        'requesterName': requesterName,
        'requestedShow': requestedShow,
        'message': message,
        'showConceptName': showConceptName,
        'department': department,
        'preferredSlot': preferredSlot,
        'format': format,
        'contactInfo': contactInfo,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': RequestStatus.pending.name,
        'isPremium': isPremium,
        if (userId != null) 'userId': userId,
      };

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static RequestType _typeFromString(String? s) {
    switch (s) {
      case 'showPitch':
        return RequestType.showPitch;
      case 'shoutout':
        return RequestType.shoutout;
      default:
        return RequestType.song;
    }
  }

  static RequestStatus _statusFromString(String? s) {
    switch (s) {
      case 'acknowledged':
        return RequestStatus.acknowledged;
      case 'played':
        return RequestStatus.played;
      case 'skipped':
        return RequestStatus.skipped;
      default:
        return RequestStatus.pending;
    }
  }
}
