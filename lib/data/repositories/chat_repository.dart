import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_config_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_participant_model.dart';
import '../models/request_model.dart';

abstract class ChatRepository {
  Stream<ChatConfigModel> watchConfig();
  Stream<List<ChatMessageModel>> watchMessages();
  Stream<List<ChatMessageModel>> watchAllMessagesForAdmin();
  Stream<List<ChatParticipantModel>> watchParticipants();
  Stream<bool> watchBanStatus(String uid);
  Future<void> sendMessage({
    required String uid,
    required String displayName,
    required String email,
    required String text,
    required ChatMessageType type,
  });
  Future<void> activateChat({String? activeLabel});
  Future<void> deactivateChat();
  Future<void> setNextSessionNote(String note);
  Future<void> setPin(String messageId, {required bool pinned});
  Future<void> hideMessage(String messageId);
  Future<void> deleteMessage(String messageId);
  Future<void> banUser({
    required String uid,
    required String bannedBy,
    required String reason,
  });
  Future<void> unbanUser(String uid);
}

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({required this.stationId, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String stationId;
  final FirebaseFirestore _db;

  @override
  Stream<ChatConfigModel> watchConfig() {
    return _db
        .collection('chat_config')
        .doc('current')
        .snapshots()
        .map((snap) => snap.exists
            ? ChatConfigModel.fromFirestore(snap)
            : ChatConfigModel.empty);
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages() {
    // stationId equality + createdAt orderBy — needs composite index (stationId, createdAt).
    // isHidden filtering is done client-side to avoid a three-field index.
    return _db
        .collection('chat_messages')
        .where('stationId', isEqualTo: stationId)
        .orderBy('createdAt', descending: false)
        .limitToLast(200)
        .snapshots()
        .map((snap) => snap.docs
            .map(ChatMessageModel.fromFirestore)
            .where((m) => !m.isHidden)
            .toList());
  }

  @override
  Stream<List<ChatMessageModel>> watchAllMessagesForAdmin() {
    return _db
        .collection('chat_messages')
        .where('stationId', isEqualTo: stationId)
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ChatMessageModel.fromFirestore).toList());
  }

  @override
  Stream<List<ChatParticipantModel>> watchParticipants() {
    return _db
        .collection('chat_participants')
        .orderBy('lastChatAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ChatParticipantModel.fromFirestore).toList());
  }

  @override
  Stream<bool> watchBanStatus(String uid) {
    return _db
        .collection('banned_users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists);
  }

  @override
  Future<void> sendMessage({
    required String uid,
    required String displayName,
    required String email,
    required String text,
    required ChatMessageType type,
  }) async {
    final msg = ChatMessageModel(
      id: '',
      uid: uid,
      displayName: displayName,
      text: text,
      type: type,
      createdAt: DateTime.now(),
    );

    await Future.wait([
      _db.collection('chat_messages').add({
        ...msg.toFirestoreCreate(),
        'stationId': stationId,
      }),
      _db.collection('chat_participants').doc(uid).set({
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'lastChatAt': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
      }, SetOptions(merge: true)),
    ]);

    if (type == ChatMessageType.songRequest) {
      await _db.collection('requests').add({
        'stationId': stationId,
        'type': RequestType.song.name,
        'requesterName': displayName,
        'message': text,
        'status': RequestStatus.pending.name,
        'submittedAt': FieldValue.serverTimestamp(),
        'userId': uid,
        'isPremium': false,
        'source': 'live_chat',
      });
    }
  }

  @override
  Future<void> activateChat({String? activeLabel}) async {
    await _db.collection('chat_config').doc('current').set({
      'stationId': stationId,
      'isActive': true,
      'activeSince': FieldValue.serverTimestamp(),
      if (activeLabel != null && activeLabel.isNotEmpty)
        'activeLabel': activeLabel,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deactivateChat() async {
    await _db.collection('chat_config').doc('current').set({
      'stationId': stationId,
      'isActive': false,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setNextSessionNote(String note) async {
    await _db.collection('chat_config').doc('current').set({
      'stationId': stationId,
      'nextSessionNote': note.isEmpty ? null : note,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setPin(String messageId, {required bool pinned}) async {
    await _db
        .collection('chat_messages')
        .doc(messageId)
        .update({'isPinned': pinned});
  }

  @override
  Future<void> hideMessage(String messageId) async {
    await _db
        .collection('chat_messages')
        .doc(messageId)
        .update({'isHidden': true});
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _db.collection('chat_messages').doc(messageId).delete();
  }

  @override
  Future<void> banUser({
    required String uid,
    required String bannedBy,
    required String reason,
  }) async {
    await _db.collection('banned_users').doc(uid).set({
      'stationId': stationId,
      'bannedBy': bannedBy,
      'bannedAt': FieldValue.serverTimestamp(),
      'reason': reason,
    });
  }

  @override
  Future<void> unbanUser(String uid) async {
    await _db.collection('banned_users').doc(uid).delete();
  }
}
