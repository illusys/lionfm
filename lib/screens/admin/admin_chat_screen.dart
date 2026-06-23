import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_participant_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat/widgets/chat_index_building_view.dart';

// ── Providers local to this screen ──────────────────────────────────────────

enum _MsgFilter { all, special }

final _filterProvider = StateProvider<_MsgFilter>((ref) => _MsgFilter.all);

final _filteredAdminMsgsProvider =
    Provider<AsyncValue<List<ChatMessageModel>>>((ref) {
  final all = ref.watch(adminChatMessagesProvider);
  final filter = ref.watch(_filterProvider);
  return all.whenData((msgs) {
    if (filter == _MsgFilter.all) return msgs;
    return msgs
        .where((m) =>
            m.type == ChatMessageType.songRequest ||
            m.type == ChatMessageType.pitch)
        .toList();
  });
});

final _participantCountProvider = Provider<int>((ref) {
  final msgs = ref.watch(adminChatMessagesProvider).valueOrNull ?? [];
  return msgs.map((m) => m.uid).toSet().length;
});

// ── Screen ───────────────────────────────────────────────────────────────────

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final _labelCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isTogglingChat = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleChat(bool currentlyActive) async {
    if (currentlyActive) {
      setState(() => _isTogglingChat = true);
      try {
        await ref.read(chatRepositoryProvider).deactivateChat();
      } finally {
        if (mounted) setState(() => _isTogglingChat = false);
      }
      return;
    }

    // Turning ON — prompt for label
    _labelCtrl.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Start Live Chat', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optional: give this session a label (e.g. "Morning Vibes call-in").',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              style: AppTextStyles.body,
              maxLength: 60,
              decoration: const InputDecoration(
                hintText: 'Session label (optional)',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Go Live'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isTogglingChat = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .activateChat(activeLabel: _labelCtrl.text.trim());
    } finally {
      if (mounted) setState(() => _isTogglingChat = false);
    }
  }

  Future<void> _saveNote() async {
    await ref
        .read(chatRepositoryProvider)
        .setNextSessionNote(_noteCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Next session note saved.'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _pinToggle(ChatMessageModel msg) async {
    await ref
        .read(chatRepositoryProvider)
        .setPin(msg.id, pinned: !msg.isPinned);
  }

  Future<void> _hide(ChatMessageModel msg) async {
    final ok = await _confirm(
        'Hide this message from listeners?', 'Hide', AppColors.warningGold);
    if (ok) await ref.read(chatRepositoryProvider).hideMessage(msg.id);
  }

  Future<void> _delete(ChatMessageModel msg) async {
    final ok = await _confirm(
        'Permanently delete this message?', 'Delete', AppColors.errorRed);
    if (ok) await ref.read(chatRepositoryProvider).deleteMessage(msg.id);
  }

  Future<void> _banUser(ChatMessageModel msg) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Ban ${msg.displayName}?', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter a reason for the ban:',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              style: AppTextStyles.body,
              maxLength: 200,
              decoration: const InputDecoration(
                  hintText: 'Reason…', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed),
            child: const Text('Ban User'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final adminUser = ref.read(adminUserProvider).valueOrNull;
    await ref.read(chatRepositoryProvider).banUser(
          uid: msg.uid,
          bannedBy: adminUser?.displayName ?? 'admin',
          reason: reasonCtrl.text.trim(),
        );
    reasonCtrl.dispose();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${msg.displayName} has been banned.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _unbanUser(String uid, String displayName) async {
    final ok = await _confirm(
        'Unban $displayName?', 'Unban', AppColors.lionGreen);
    if (ok) await ref.read(chatRepositoryProvider).unbanUser(uid);
  }

  void _showParticipantsReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ParticipantsReportSheet(ref: ref),
    );
  }

  Future<bool> _confirm(String message, String action, Color color) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: color),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(chatConfigProvider);
    final msgsAsync = ref.watch(_filteredAdminMsgsProvider);
    final allMsgs = ref.watch(adminChatMessagesProvider).valueOrNull ?? [];
    final participants = ref.watch(_participantCountProvider);
    final filter = ref.watch(_filterProvider);

    final isActive = configAsync.valueOrNull?.isActive ?? false;

    // Pre-fill note field from Firestore
    final savedNote = configAsync.valueOrNull?.nextSessionNote ?? '';
    if (_noteCtrl.text.isEmpty && savedNote.isNotEmpty) {
      _noteCtrl.text = savedNote;
    }

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Live Chat'),
        automaticallyImplyLeading: false,
        actions: [
          // Stats
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatChip(
                    icon: Icons.message_rounded,
                    value: allMsgs.length,
                    color: AppColors.electricTeal),
                const SizedBox(width: 8),
                _StatChip(
                    icon: Icons.people_rounded,
                    value: participants,
                    color: AppColors.warningGold),
              ],
            ),
          ),
          // Participants report
          IconButton(
            icon: const Icon(Icons.contact_mail_rounded, size: 20),
            tooltip: 'User Report',
            onPressed: () => _showParticipantsReport(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Toggle card ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(AppDimensions.p16),
            padding: const EdgeInsets.all(AppDimensions.p16),
            decoration: BoxDecoration(
              color: AppColors.bg1,
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              border: Border.all(
                color: isActive ? AppColors.borderGreen : AppColors.border1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isActive ? 'Chat is LIVE' : 'Chat is OFF',
                            style: AppTextStyles.h3.copyWith(
                              color: isActive
                                  ? AppColors.lionGreen
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (isActive &&
                              configAsync.valueOrNull?.activeLabel != null)
                            Text(
                              configAsync.valueOrNull!.activeLabel!,
                              style: AppTextStyles.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    _isTogglingChat
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                                color: AppColors.lionGreen, strokeWidth: 2),
                          )
                        : GestureDetector(
                            onTap: () => _toggleChat(isActive),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 56,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.lionGreen
                                    : AppColors.bg3,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.rFull),
                                border: Border.all(
                                    color: isActive
                                        ? AppColors.lionGreen
                                        : AppColors.border1),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                alignment: isActive
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary,
                                    borderRadius: BorderRadius.circular(
                                        AppDimensions.rFull),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),

                // Next session note
                if (!isActive) ...[
                  const SizedBox(height: AppDimensions.p12),
                  const Divider(color: AppColors.border1, height: 1),
                  const SizedBox(height: AppDimensions.p12),
                  Text('Next session note',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteCtrl,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textPrimary),
                          maxLength: 200,
                          decoration: const InputDecoration(
                            hintText:
                                'Shown to listeners when chat is closed…',
                            counterText: '',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _saveNote,
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.lionGreen),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Filter row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _FilterPill(
                  label: 'All Messages',
                  selected: filter == _MsgFilter.all,
                  onTap: () => ref.read(_filterProvider.notifier).state =
                      _MsgFilter.all,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: '🎵 Requests & Pitches',
                  selected: filter == _MsgFilter.special,
                  onTap: () => ref.read(_filterProvider.notifier).state =
                      _MsgFilter.special,
                ),
              ],
            ),
          ),

          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: msgsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.lionGreen)),
              error: (e, _) {
                if (isChatIndexBuilding(e)) {
                  return const ChatIndexBuildingView();
                }
                return Center(
                  child: Text('Error: $e',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                );
              },
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Text(
                      filter == _MsgFilter.special
                          ? 'No song requests or pitches yet.'
                          : 'No messages yet.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: msgs.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: AppColors.border1),
                  itemBuilder: (context, i) =>
                      _AdminMessageTile(
                        message: msgs[i],
                        onPin: () => _pinToggle(msgs[i]),
                        onHide: () => _hide(msgs[i]),
                        onDelete: () => _delete(msgs[i]),
                        onBan: () => _banUser(msgs[i]),
                        onUnban: () =>
                            _unbanUser(msgs[i].uid, msgs[i].displayName),
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  const _StatChip(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.rFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: AppTextStyles.caption.copyWith(
                color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lionGreen.withValues(alpha: 0.15)
              : AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.rFull),
          border: Border.all(
            color: selected ? AppColors.borderGreen : AppColors.border1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color:
                selected ? AppColors.lionGreen : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AdminMessageTile extends ConsumerWidget {
  final ChatMessageModel message;
  final VoidCallback onPin;
  final VoidCallback onHide;
  final VoidCallback onDelete;
  final VoidCallback onBan;
  final VoidCallback onUnban;

  const _AdminMessageTile({
    required this.message,
    required this.onPin,
    required this.onHide,
    required this.onDelete,
    required this.onBan,
    required this.onUnban,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBanned =
        ref.watch(bannedStatusProvider(message.uid)).valueOrNull ?? false;

    Color? bgColor;
    if (message.isHidden) bgColor = AppColors.errorRed.withValues(alpha: 0.06);
    if (message.isPinned) bgColor = AppColors.lionGreen.withValues(alpha: 0.06);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _avatarColor(message.uid),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              message.displayName.isNotEmpty
                  ? message.displayName[0].toUpperCase()
                  : '?',
              style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.bg0),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    if (message.type == ChatMessageType.songRequest)
                      _badge('SONG', AppColors.electricTeal)
                    else if (message.type == ChatMessageType.pitch)
                      _badge('PITCH', AppColors.warningGold),
                    if (message.isPinned) ...[
                      const SizedBox(width: 4),
                      _badge('PINNED', AppColors.lionGreen),
                    ],
                    if (message.isHidden) ...[
                      const SizedBox(width: 4),
                      _badge('HIDDEN', AppColors.errorRed),
                    ],
                    if (isBanned) ...[
                      const SizedBox(width: 4),
                      _badge('BANNED', AppColors.errorRed),
                    ],
                    const Spacer(),
                    Text(
                      DateFormat('HH:mm').format(message.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(message.text, style: AppTextStyles.body),
                const SizedBox(height: 6),

                // Action row
                Wrap(
                  spacing: 6,
                  children: [
                    _ActionBtn(
                      label: message.isPinned ? 'Unpin' : 'Pin',
                      icon: Icons.push_pin_rounded,
                      color: AppColors.lionGreen,
                      onTap: onPin,
                    ),
                    if (!message.isHidden)
                      _ActionBtn(
                        label: 'Hide',
                        icon: Icons.visibility_off_rounded,
                        color: AppColors.warningGold,
                        onTap: onHide,
                      ),
                    _ActionBtn(
                      label: 'Delete',
                      icon: Icons.delete_rounded,
                      color: AppColors.errorRed,
                      onTap: onDelete,
                    ),
                    if (isBanned)
                      _ActionBtn(
                        label: 'Unban',
                        icon: Icons.lock_open_rounded,
                        color: AppColors.electricTeal,
                        onTap: onUnban,
                      )
                    else
                      _ActionBtn(
                        label: 'Ban',
                        icon: Icons.block_rounded,
                        color: AppColors.errorRed,
                        onTap: onBan,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 8,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Color _avatarColor(String uid) {
    final colors = [
      AppColors.lionGreen,
      AppColors.electricTeal,
      AppColors.warningGold,
      AppColors.deepOrange,
      AppColors.unnDeepBlue,
    ];
    final idx = uid.isNotEmpty ? uid.codeUnitAt(0) % colors.length : 0;
    return colors[idx];
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Participants Report ────────────────────────────────────────────────────────

class _ParticipantsReportSheet extends ConsumerWidget {
  final WidgetRef ref;
  const _ParticipantsReportSheet({required this.ref});

  String _buildCsv(List<ChatParticipantModel> list) {
    final buf = StringBuffer();
    buf.writeln('Name,Email,Last Active,Messages Sent');
    for (final p in list) {
      String esc(String s) => '"${s.replaceAll('"', '""')}"';
      buf.writeln([
        esc(p.displayName),
        esc(p.email),
        esc(DateFormat('yyyy-MM-dd HH:mm').format(p.lastChatAt)),
        p.messageCount,
      ].join(','));
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef watchRef) {
    final participantsAsync = watchRef.watch(chatParticipantsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border1,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  const Icon(Icons.contact_mail_rounded,
                      color: AppColors.lionGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Chat Users Report',
                        style: AppTextStyles.h3),
                  ),
                  participantsAsync.whenOrNull(
                    data: (list) => TextButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy CSV'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.lionGreen,
                          textStyle: AppTextStyles.bodySmall),
                      onPressed: () async {
                        final csv = _buildCsv(list);
                        await Clipboard.setData(ClipboardData(text: csv));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'CSV copied — ${list.length} users',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ) ?? const SizedBox.shrink(),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border1),

            // Column headers
            participantsAsync.whenOrNull(data: (list) => list.isNotEmpty
                ? Container(
                    color: AppColors.bg2,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 36),
                        Expanded(
                          flex: 3,
                          child: Text('Name / Email',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Last Active',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text('Msgs',
                              textAlign: TextAlign.right,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  )
                : null) ?? const SizedBox.shrink(),

            // List
            Expanded(
              child: participantsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.lionGreen)),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary))),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded,
                              color: AppColors.textMuted, size: 40),
                          const SizedBox(height: 12),
                          Text('No chat users yet.',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Text(
                            'Users appear here after they send\ntheir first message.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border1),
                    itemBuilder: (_, i) =>
                        _ParticipantRow(participant: list[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final ChatParticipantModel participant;
  const _ParticipantRow({required this.participant});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.lionGreen,
      AppColors.electricTeal,
      AppColors.warningGold,
      AppColors.deepOrange,
      AppColors.unnDeepBlue,
    ];
    final avatarColor = participant.uid.isNotEmpty
        ? colors[participant.uid.codeUnitAt(0) % colors.length]
        : AppColors.lionGreen;

    final initial = participant.displayName.isNotEmpty
        ? participant.displayName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.bg0)),
          ),
          const SizedBox(width: 12),

          // Name + email
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName.isNotEmpty
                      ? participant.displayName
                      : 'Unknown',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(
                        ClipboardData(text: participant.email));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${participant.email} copied'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    participant.email.isNotEmpty
                        ? participant.email
                        : '—',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Last active
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM d, HH:mm').format(participant.lastChatAt),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),

          // Message count
          SizedBox(
            width: 48,
            child: Text(
              '${participant.messageCount}',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.electricTeal,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
