import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConfigModel {
  final bool isActive;
  final DateTime? activeSince;
  final String? activeLabel;
  final String? nextSessionNote;

  const ChatConfigModel({
    required this.isActive,
    this.activeSince,
    this.activeLabel,
    this.nextSessionNote,
  });

  static const empty = ChatConfigModel(isActive: false);

  factory ChatConfigModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatConfigModel(
      isActive: d['isActive'] as bool? ?? false,
      activeSince: _tsToDate(d['activeSince']),
      activeLabel: d['activeLabel'] as String?,
      nextSessionNote: d['nextSessionNote'] as String?,
    );
  }

  static DateTime? _tsToDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
