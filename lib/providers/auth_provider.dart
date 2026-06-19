import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final isGuestModeProvider = StateProvider<bool>((ref) => false);

final isAuthenticatedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authStateProvider);
  final isGuest = ref.watch(isGuestModeProvider);
  return isGuest || auth.valueOrNull != null;
});
