import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole { superAdmin, stationManager, broadcaster, unnAdmin, none }

class AdminUser {
  final String uid;
  final String email;
  final String displayName;
  final AdminRole role;
  final bool isActive;

  const AdminUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
  });

  bool get isSuperAdmin => role == AdminRole.superAdmin;
  bool get canManageSchedule => role != AdminRole.unnAdmin;
  bool get canManageRevenue =>
      role == AdminRole.superAdmin || role == AdminRole.unnAdmin;
  bool get canManageUsers => role == AdminRole.superAdmin;
  bool get canSendNotifications =>
      role == AdminRole.superAdmin || role == AdminRole.stationManager;

  static AdminRole roleFromString(String? s) {
    switch (s) {
      case 'superAdmin':
        return AdminRole.superAdmin;
      case 'stationManager':
        return AdminRole.stationManager;
      case 'broadcaster':
        return AdminRole.broadcaster;
      case 'unnAdmin':
        return AdminRole.unnAdmin;
      default:
        return AdminRole.none;
    }
  }

  static String roleToString(AdminRole r) {
    switch (r) {
      case AdminRole.superAdmin:
        return 'superAdmin';
      case AdminRole.stationManager:
        return 'stationManager';
      case AdminRole.broadcaster:
        return 'broadcaster';
      case AdminRole.unnAdmin:
        return 'unnAdmin';
      case AdminRole.none:
        return 'none';
    }
  }

  static String roleDisplayName(AdminRole r) {
    switch (r) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.stationManager:
        return 'Station Manager';
      case AdminRole.broadcaster:
        return 'Broadcaster';
      case AdminRole.unnAdmin:
        return 'UNN Admin';
      case AdminRole.none:
        return 'No Role';
    }
  }
}

// Signals first-time setup is needed (signed-in but no superAdmin exists)
final needsFirstTimeSetupProvider = StateProvider<bool>((ref) => false);

final adminUserProvider = StreamProvider<AdminUser?>((ref) async* {
  final authStream = FirebaseAuth.instance.authStateChanges();
  await for (final user in authStream) {
    if (user == null) {
      yield null;
      continue;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Check if any superAdmin exists — if none, signal first-time setup
        final superAdminSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'superAdmin')
            .limit(1)
            .get();
        if (superAdminSnap.docs.isEmpty) {
          ref.read(needsFirstTimeSetupProvider.notifier).state = true;
        }
        yield null;
        continue;
      }

      final data = doc.data()!;
      final role = AdminUser.roleFromString(data['role'] as String?);
      if (role == AdminRole.none) {
        yield null;
        continue;
      }
      final isActive = data['isActive'] as bool? ?? true;
      if (!isActive) {
        yield null;
        continue;
      }
      yield AdminUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName:
            data['displayName'] as String? ?? user.displayName ?? '',
        role: role,
        isActive: isActive,
      );
    } catch (e) {
      debugPrint('AdminAuth error: $e');
      yield null;
    }
  }
});

final allAdminUsersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', whereNotIn: ['none'])
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});
