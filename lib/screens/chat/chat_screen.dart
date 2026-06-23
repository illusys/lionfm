import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../data/models/chat_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/lion_fm_app_bar.dart';
import '../../widgets/common/login_prompt_sheet.dart';
import 'widgets/chat_inactive_view.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/pinned_message_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  ChatMessageType _pendingType = ChatMessageType.chat;
  bool _isSending = false;
  DateTime? _lastSentAt;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _setQuickAction(ChatMessageType type) {
    setState(() {
      if (_pendingType == type) {
        _pendingType = ChatMessageType.chat;
        _ctrl.clear();
      } else {
        _pendingType = type;
        _ctrl.clear();
      }
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      // Focus is handled by the TextField itself
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    // Rate-limit: 1 message per 3 seconds
    final now = DateTime.now();
    if (_lastSentAt != null &&
        now.difference(_lastSentAt!).inSeconds < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait a moment before sending another message.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      await LoginPromptSheet.show(context,
          reason: 'Sign in to chat with other listeners.');
      return;
    }

    final isBanned =
        ref.read(bannedStatusProvider(user.uid)).valueOrNull ?? false;
    if (isBanned) return;

    setState(() => _isSending = true);
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            uid: user.uid,
            displayName:
                user.displayName ?? user.email?.split('@').first ?? 'Listener',
            text: text,
            type: _pendingType,
          );
      _lastSentAt = DateTime.now();
      _ctrl.clear();
      setState(() => _pendingType = ChatMessageType.chat);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(chatConfigProvider);
    final messagesAsync = ref.watch(chatMessagesProvider);
    final pinnedMessage = ref.watch(pinnedMessageProvider);
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final isSignedIn = currentUser != null;
    final isBanned = isSignedIn
        ? (ref.watch(bannedStatusProvider(currentUser.uid)).valueOrNull ?? false)
        : false;

    // Auto-scroll when new messages arrive
    ref.listen(chatMessagesProvider, (_, __) {
      _scrollToBottom();
    });

    final config = configAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: LionFmAppBar(
        title: 'Live Chat',
        extra: [
          if (config?.isActive == true)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.liveRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: AppColors.liveRed.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.liveRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      config?.activeLabel?.isNotEmpty == true
                          ? config!.activeLabel!
                          : 'LIVE',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.liveRed,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: configAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.lionGreen)),
        error: (e, _) => Center(
          child: Text('Error loading chat: $e',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
        ),
        data: (cfg) {
          if (!cfg.isActive) {
            return ChatInactiveView(nextSessionNote: cfg.nextSessionNote);
          }

          return Column(
            children: [
              // Pinned message bar
              if (pinnedMessage != null)
                PinnedMessageBar(message: pinnedMessage),

              // Message list
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.lionGreen)),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary)),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.textMuted,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Be the first to say something!',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return ChatMessageBubble(
                          message: msg,
                          isOwn: currentUser != null &&
                              msg.uid == currentUser.uid,
                        );
                      },
                    );
                  },
                ),
              ),

              // Input bar
              ChatInputBar(
                controller: _ctrl,
                pendingType: _pendingType,
                isSignedIn: isSignedIn,
                isBanned: isBanned,
                isSending: _isSending,
                onSongRequest: () =>
                    _setQuickAction(ChatMessageType.songRequest),
                onPitch: () => _setQuickAction(ChatMessageType.pitch),
                onSend: _send,
                onSignInPrompt: () => LoginPromptSheet.show(context,
                    reason: 'Sign in to join the live chat.'),
                onClearType: () =>
                    setState(() => _pendingType = ChatMessageType.chat),
              ),
            ],
          );
        },
      ),
    );
  }
}
