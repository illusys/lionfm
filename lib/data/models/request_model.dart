enum RequestType { song, showPitch }

enum RequestStatus { pending, acknowledged, played }

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
    );
  }

  factory RequestModel.fromJson(Map<String, dynamic> json) => RequestModel(
        id: json['id'] as String,
        type: RequestType.values.byName(json['type'] as String),
        songTitle: json['songTitle'] as String?,
        artistName: json['artistName'] as String?,
        dedicatedTo: json['dedicatedTo'] as String?,
        requesterName: json['requesterName'] as String,
        requestedShow: json['requestedShow'] as String?,
        message: json['message'] as String?,
        showConceptName: json['showConceptName'] as String?,
        department: json['department'] as String?,
        preferredSlot: json['preferredSlot'] as String?,
        format: json['format'] as String?,
        contactInfo: json['contactInfo'] as String?,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        status: RequestStatus.values.byName(json['status'] as String? ?? 'pending'),
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
      };
}
