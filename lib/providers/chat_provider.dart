import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat_config_model.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/chat_participant_model.dart';
import '../data/repositories/chat_repository.dart';
import 'current_station_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepository(
      stationId: ref.watch(currentStationIdProvider) ?? 'lion');
});

final chatConfigProvider = StreamProvider<ChatConfigModel>((ref) {
  return ref.watch(chatRepositoryProvider).watchConfig();
});

final chatMessagesProvider = StreamProvider<List<ChatMessageModel>>((ref) {
  return ref.watch(chatRepositoryProvider).watchMessages();
});

final adminChatMessagesProvider =
    StreamProvider<List<ChatMessageModel>>((ref) {
  return ref.watch(chatRepositoryProvider).watchAllMessagesForAdmin();
});

final bannedStatusProvider =
    StreamProvider.family<bool, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(false);
  return ref.watch(chatRepositoryProvider).watchBanStatus(uid);
});

final chatParticipantsProvider =
    StreamProvider<List<ChatParticipantModel>>((ref) {
  return ref.watch(chatRepositoryProvider).watchParticipants();
});

final pinnedMessageProvider = Provider<ChatMessageModel?>((ref) {
  final msgs = ref.watch(chatMessagesProvider).valueOrNull ?? [];
  try {
    return msgs.lastWhere((m) => m.isPinned);
  } catch (_) {
    return null;
  }
});
