import 'package:cloud_firestore/cloud_firestore.dart';

class ChatParticipantModel {
  final String uid;
  final String displayName;
  final String email;
  final DateTime lastChatAt;
  final int messageCount;

  const ChatParticipantModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.lastChatAt,
    required this.messageCount,
  });

  factory ChatParticipantModel.fromFirestore(DocumentSnapshot snap) {
    final d = snap.data() as Map<String, dynamic>;
    return ChatParticipantModel(
      uid: d['uid'] as String? ?? snap.id,
      displayName: d['displayName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      lastChatAt:
          (d['lastChatAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      messageCount: (d['messageCount'] as num?)?.toInt() ?? 0,
    );
  }
}
