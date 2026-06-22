import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/constants/app_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // On Web, GIS requires an explicit clientId to initialise.
  // Pass it from AppConfig (injected via --dart-define at build time or
  // read from the <meta name="google-signin-client_id"> tag in index.html).
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb && AppConfig.googleWebClientId.isNotEmpty
        ? AppConfig.googleWebClientId
        : null,
  );

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status != LoginStatus.success) return null;
      final credential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Facebook sign-in error: $e');
      return null;
    }
  }

  /// Apple sign-in (iOS/macOS only; returns null on unsupported platforms).
  Future<UserCredential?> signInWithApple() async {
    try {
      if (!await SignInWithApple.isAvailable()) return null;
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      return await _auth.signInWithCredential(oauthCredential);
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
      FacebookAuth.instance.logOut(),
    ]);
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isGuest => _auth.currentUser == null;
}
