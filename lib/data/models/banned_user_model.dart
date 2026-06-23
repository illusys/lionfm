import 'package:cloud_firestore/cloud_firestore.dart';

class BannedUserModel {
  final String uid;
  final String bannedBy;
  final DateTime bannedAt;
  final String reason;

  const BannedUserModel({
    required this.uid,
    required this.bannedBy,
    required this.bannedAt,
    required this.reason,
  });

  factory BannedUserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['bannedAt'];
    return BannedUserModel(
      uid: doc.id,
      bannedBy: d['bannedBy'] as String? ?? '',
      bannedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      reason: d['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'bannedBy': bannedBy,
        'bannedAt': FieldValue.serverTimestamp(),
        'reason': reason,
      };
}
