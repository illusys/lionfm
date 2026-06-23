import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType { chat, songRequest, pitch }

class ChatMessageModel {
  final String id;
  final String uid;
  final String displayName;
  final String text;
  final ChatMessageType type;
  final DateTime createdAt;
  final bool isPinned;
  final bool isHidden;

  const ChatMessageModel({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.text,
    required this.type,
    required this.createdAt,
    this.isPinned = false,
    this.isHidden = false,
  });

  ChatMessageModel copyWith({
    bool? isPinned,
    bool? isHidden,
  }) =>
      ChatMessageModel(
        id: id,
        uid: uid,
        displayName: displayName,
        text: text,
        type: type,
        createdAt: createdAt,
        isPinned: isPinned ?? this.isPinned,
        isHidden: isHidden ?? this.isHidden,
      );

  factory ChatMessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['createdAt'];
    final created = ts is Timestamp ? ts.toDate() : DateTime.now();
    return ChatMessageModel(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      displayName: d['displayName'] as String? ?? 'Listener',
      text: d['text'] as String? ?? '',
      type: _typeFromString(d['type'] as String?),
      createdAt: created,
      isPinned: d['isPinned'] as bool? ?? false,
      isHidden: d['isHidden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
        'uid': uid,
        'displayName': displayName,
        'text': text,
        'type': _typeToString(type),
        'createdAt': FieldValue.serverTimestamp(),
        'isPinned': false,
        'isHidden': false,
      };

  static String _typeToString(ChatMessageType t) {
    switch (t) {
      case ChatMessageType.songRequest:
        return 'song_request';
      case ChatMessageType.pitch:
        return 'pitch';
      case ChatMessageType.chat:
        return 'chat';
    }
  }

  static ChatMessageType _typeFromString(String? s) {
    switch (s) {
      case 'song_request':
        return ChatMessageType.songRequest;
      case 'pitch':
        return ChatMessageType.pitch;
      default:
        return ChatMessageType.chat;
    }
  }
}
