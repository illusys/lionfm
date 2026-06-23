import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  await for (final firebaseUser in authStream) {
    if (firebaseUser == null) {
      yield null;
      continue;
    }

    try {
      // Small delay to let Firestore rules propagate after sign-in
      await Future.delayed(const Duration(milliseconds: 300));

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        // Check if any superAdmin exists — if none, signal first-time setup.
        // Wrapped separately so a permission error here doesn't prevent login.
        try {
          final result = await FirebaseFunctions.instance
              .httpsCallable('getAdminBootstrapStatus')
              .call<Map<Object?, Object?>>();
          final data = Map<String, dynamic>.from(result.data);
          ref.read(needsFirstTimeSetupProvider.notifier).state =
              data['needsFirstTimeSetup'] == true;
        } catch (e) {
          debugPrint('AdminAuth bootstrap status error: $e');
        }
        yield null;
        continue;
      }

      final data = doc.data();
      if (data == null) {
        yield null;
        continue;
      }

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
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName:
            data['displayName'] as String? ?? firebaseUser.displayName ?? '',
        role: role,
        isActive: isActive,
      );
    } on FirebaseException catch (e) {
      debugPrint('AdminAuth FirebaseException: ${e.code} — ${e.message}');
      yield null;
    } catch (e) {
      debugPrint('AdminAuth unexpected error: $e');
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
      .map((snap) => snap.docs
          .map<Map<String, dynamic>>(
            (d) => <String, dynamic>{'id': d.id, ...d.data()},
          )
          .toList());
});
