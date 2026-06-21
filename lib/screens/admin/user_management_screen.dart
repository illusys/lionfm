import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/admin_auth_provider.dart';

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
    final uid = userData['id'] as String;

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

  String _generatePassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#\$';
    final rng = Random.secure();
    return List.generate(12, (_) => chars[rng.nextInt(chars.length)])
        .join();
  }

  Future<void> _createInvite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tempPassword = _generatePassword();
    final currentUser = ref.read(adminUserProvider).valueOrNull;

    try {
      await FirebaseFirestore.instance.collection('admin_invites').add({
        'email': _emailCtrl.text.trim(),
        'displayName': _nameCtrl.text.trim(),
        'role': AdminUser.roleToString(_role),
        'createdBy': currentUser?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'tempPassword': tempPassword,
      });

      if (mounted) {
        Navigator.pop(context);
        _showCredentialsDialog(
          context,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: tempPassword,
        );
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

  void _showCredentialsDialog(
      BuildContext context,
      {required String name,
      required String email,
      required String password}) {
    final credentials = 'Email: $email\nTemporary Password: $password';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Invite Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share these credentials with $name:',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: $email', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Temporary Password: $password',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.lionGreen)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
                'They must change their password on first login. '
                'Create their Firebase Auth account in the Firebase Console '
                'and set the Firestore user document manually.',
                style: AppTextStyles.caption),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: credentials));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Credentials copied to clipboard')));
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
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
                  : const Text('Send Invite & Create Account'),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_invites')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
            final data = docs[i].data() as Map<String, dynamic>;
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
