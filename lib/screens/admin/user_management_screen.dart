import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/admin_auth_provider.dart';
import '../../widgets/common/index_building_placeholder.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('User Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddUserSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Admin Users'),
            Tab(text: 'Pending Invites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AdminUsersTab(onAddUser: () => _showAddUserSheet(context)),
          const _PendingInvitesTab(),
        ],
      ),
    );
  }

  void _showAddUserSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddUserSheet(),
    );
  }
}

class _AdminUsersTab extends ConsumerWidget {
  final VoidCallback onAddUser;
  const _AdminUsersTab({required this.onAddUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allAdminUsersProvider);

    return usersAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: AppTextStyles.bodySmall),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline_rounded,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                Text('No admin users yet.',
                    style: AppTextStyles.bodyMedium),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onAddUser,
                  child: const Text('Add your first admin'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.p16),
          itemCount: users.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.p8),
          itemBuilder: (context, i) =>
              _UserCard(userData: users[i]),
        );
      },
    );
  }
}

class _UserCard extends ConsumerWidget {
  final Map<String, dynamic> userData;
  const _UserCard({required this.userData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = userData['displayName'] as String? ?? '?';
    final email = userData['email'] as String? ?? '';
    final roleStr = userData['role'] as String? ?? 'none';
    final role = AdminUser.roleFromString(roleStr);
    final isActive = userData['isActive'] as bool? ?? true;
    final uid = (userData['id'] as String?) ?? '';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.p12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Row(
        children: [
          _InitialsAvatar(name: name, role: role),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis),
                Text(email,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                _RoleBadge(role: role),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isActive,
            activeThumbColor: AppColors.lionGreen,
            onChanged: (val) async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'isActive': val});
            },
          ),
          PopupMenuButton<String>(
            color: AppColors.bg3,
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textMuted),
            onSelected: (action) =>
                _handleAction(context, ref, action, uid, name, email),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit Role')),
              PopupMenuItem(
                  value: 'reset', child: Text('Reset Password')),
              PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove Access',
                      style: TextStyle(color: AppColors.errorRed))),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action,
      String uid, String name, String email) {
    switch (action) {
      case 'edit':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.bg1,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _EditRoleSheet(uid: uid, name: name,
              currentRole: AdminUser.roleFromString(userData['role'] as String? ?? 'none')),
        );
        break;
      case 'reset':
        _resetPassword(context, email);
        break;
      case 'remove':
        _confirmRemove(context, uid, name);
        break;
    }
  }

  Future<void> _resetPassword(BuildContext context, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: AppColors.successGreen,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }

  Future<void> _confirmRemove(
      BuildContext context, String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Remove Access'),
        content: Text(
            'Remove admin access for $name? Their account will be deactivated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': 'none',
        'isActive': false,
      });
    }
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final AdminRole role;
  const _InitialsAvatar({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final initials =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
    final color = _roleColor(role);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.h3.copyWith(color: color),
      ),
    );
  }

  Color _roleColor(AdminRole r) {
    switch (r) {
      case AdminRole.platformOwner: return AppColors.lionGold;
      case AdminRole.superAdmin:
        return AppColors.lionGreen;
      case AdminRole.stationManager:
        return AppColors.electricTeal;
      case AdminRole.broadcaster:
        return AppColors.warningGold;
      case AdminRole.unnAdmin:
        return AppColors.unnDeepBlue;
      case AdminRole.none:
        return AppColors.textMuted;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final AdminRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = AdminUser.roleDisplayName(role);
    final color = _roleColor(role);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius:
            BorderRadius.circular(AppDimensions.rFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }

  Color _roleColor(AdminRole r) {
    switch (r) {
      case AdminRole.platformOwner: return AppColors.lionGold;
      case AdminRole.superAdmin:
        return AppColors.lionGreen;
      case AdminRole.stationManager:
        return AppColors.electricTeal;
      case AdminRole.broadcaster:
        return AppColors.warningGold;
      case AdminRole.unnAdmin:
        return const Color(0xFF4B8EFF);
      case AdminRole.none:
        return AppColors.textMuted;
    }
  }
}

class _EditRoleSheet extends ConsumerStatefulWidget {
  final String uid;
  final String name;
  final AdminRole currentRole;
  const _EditRoleSheet(
      {required this.uid, required this.name, required this.currentRole});

  @override
  ConsumerState<_EditRoleSheet> createState() => _EditRoleSheetState();
}

class _EditRoleSheetState extends ConsumerState<_EditRoleSheet> {
  late AdminRole _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentRole == AdminRole.none
        ? AdminRole.stationManager
        : widget.currentRole;
  }

  @override
  Widget build(BuildContext context) {
    final roles = [
      AdminRole.superAdmin,
      AdminRole.stationManager,
      AdminRole.broadcaster,
      AdminRole.unnAdmin,
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Role — ${widget.name}', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          ...roles.map((r) {
                final isSelected = r == _selected;
                return InkWell(
                  onTap: () => setState(() => _selected = r),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.lionGreen.withValues(alpha: 0.15)
                          : AppColors.bg2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.lionGreen
                            : AppColors.border1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? AppColors.lionGreen
                              : AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(AdminUser.roleDisplayName(r),
                            style: AppTextStyles.body.copyWith(
                              color: isSelected
                                  ? AppColors.lionGreen
                                  : AppColors.textPrimary,
                            )),
                      ],
                    ),
                  ),
                );
              }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lionGreen,
              foregroundColor: AppColors.bg0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bg0))
                : const Text('Save Role'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'role': AdminUser.roleToString(_selected)});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AddUserSheet extends ConsumerStatefulWidget {
  const _AddUserSheet();

  @override
  ConsumerState<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends ConsumerState<_AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  AdminRole _role = AdminRole.stationManager;
  bool _saving = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createInvite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final roleStr = AdminUser.roleToString(_role);
    final currentUser = ref.read(adminUserProvider).valueOrNull;

    try {
      // Use email as doc ID so the Cloud Function and accept_invite_screen
      // can look it up directly without a query.
      await FirebaseFirestore.instance
          .collection('admin_invites')
          .doc(email)
          .set({
        'email': email,
        'displayName': name,
        'role': roleStr,
        'invitedBy': currentUser?.uid ?? '',
        'invitedByName': currentUser?.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Trigger email via Firebase "Trigger Email from Firestore" extension
      final acceptUrl =
          'https://app.fmstream.online/#/admin-accept-invite?email=${Uri.encodeComponent(email)}';
      await FirebaseFirestore.instance.collection('mail').add({
        'to': [email],
        'message': {
          'subject': "You've been invited to FMStream Admin",
          'html': '''
<div style="font-family:sans-serif;max-width:560px;margin:0 auto;padding:32px;background:#0B1639;color:#fff;border-radius:12px;">
  <div style="text-align:center;margin-bottom:24px;">
    <span style="font-size:32px;font-weight:800;color:#15E0B4;">FM</span><span style="font-size:32px;font-weight:800;color:#fff;">Stream</span>
  </div>
  <h2 style="color:#15E0B4;">You\'re invited!</h2>
  <p>Hi $name,</p>
  <p>${currentUser?.displayName ?? 'An FMStream Admin'} has invited you to join FMStream as <strong style="color:#15E0B4;">${AdminUser.roleDisplayName(_role)}</strong>.</p>
  <p>Click the button below to set your password and activate your account:</p>
  <div style="text-align:center;margin:32px 0;">
    <a href="$acceptUrl" style="background:#15E0B4;color:#06112B;padding:14px 32px;border-radius:8px;text-decoration:none;font-weight:600;font-size:16px;">
      Accept Invitation
    </a>
  </div>
  <p style="color:#888;font-size:13px;">This link is personal — do not share it with others.</p>
  <hr style="border:none;border-top:1px solid #1E2D4A;margin:24px 0;"/>
  <p style="color:#666;font-size:12px;text-align:center;">
    FMStream · app.fmstream.online<br/>
    If you did not expect this invitation, please ignore this email.
  </p>
</div>''',
        },
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Invite email sent to $email'),
          backgroundColor: AppColors.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignableRoles = [
      AdminRole.stationManager,
      AdminRole.broadcaster,
      AdminRole.unnAdmin,
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Admin User', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Email address',
                filled: true,
                fillColor: AppColors.bg2,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Display name',
                filled: true,
                fillColor: AppColors.bg2,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AdminRole>(
              initialValue: _role,
              dropdownColor: AppColors.bg3,
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.bg2,
                labelText: 'Role',
              ),
              items: assignableRoles
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(AdminUser.roleDisplayName(r),
                            style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (r) => setState(() => _role = r!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _createInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lionGreen,
                foregroundColor: AppColors.bg0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.bg0))
                  : const Text('Send Invite Email'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingInvitesTab extends StatelessWidget {
  const _PendingInvitesTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('admin_invites')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return isIndexBuildingError(snap.error!)
              ? const IndexBuildingPlaceholder()
              : Center(
                  child: Text('Error: ${snap.error}',
                      style: const TextStyle(color: AppColors.errorRed)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline_rounded,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                Text('No pending invites', style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.p16),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.p8),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final name = data['displayName'] as String? ?? '';
            final email = data['email'] as String? ?? '';
            final roleStr = data['role'] as String? ?? '';

            return Container(
              padding: const EdgeInsets.all(AppDimensions.p12),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.borderGold),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warningGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.schedule_rounded,
                        color: AppColors.warningGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.bodyMedium),
                        Text(email, style: AppTextStyles.caption),
                        Text(roleStr,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.warningGold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => docs[i].reference.delete(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
