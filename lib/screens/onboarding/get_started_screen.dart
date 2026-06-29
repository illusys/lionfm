import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  static const _bg = Color(0xFF0B1639);
  static const _card = Color(0xFF122150);
  static const _teal = Color(0xFF15E0B4);
  static const _btnText = Color(0xFF06112B);
  static const _slate = Color(0xFF5A6B86);

  bool _showSignIn = false;

  // Sign-in form controllers
  final _slugCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _signingIn = false;
  String? _signInError;

  @override
  void dispose() {
    _slugCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInToStation() async {
    final slug = _slugCtrl.text.trim().toLowerCase();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (slug.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _signInError = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _signingIn = true;
      _signInError = null;
    });

    try {
      // 1. Verify station exists
      final doc = await FirebaseFirestore.instance
          .collection('stations')
          .doc(slug)
          .get();
      if (!doc.exists) {
        setState(() => _signInError = 'No station found with that name.');
        return;
      }

      // 2. Sign in with Firebase Auth
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 3. Navigate to station admin dashboard
      final url = Uri.parse('https://$slug.fmstream.online/#/admin');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _signInError = switch (e.code) {
            'user-not-found' ||
            'wrong-password' ||
            'invalid-credential' ||
            'invalid-email' =>
              'Invalid email or password.',
            'too-many-requests' =>
              'Too many attempts. Try again later.',
            _ => e.message ?? 'Sign in failed.',
          });
    } catch (e) {
      setState(() => _signInError = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FMStream wordmark
                  Center(
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'FM',
                            style: TextStyle(
                              color: _teal,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Stream',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Get your station online',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create your FMStream account and go live in minutes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Primary CTA
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go('/onboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: _btnText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Create your station',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _btnText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // "I already have a station" toggle
                  GestureDetector(
                    onTap: () => setState(() => _showSignIn = !_showSignIn),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'I already have a station',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showSignIn
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),

                  // Inline sign-in panel
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showSignIn
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _buildSignInPanel(),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Platform admin login — subtle, for Benedict only
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/admin-login'),
                      child: const Text(
                        'Platform admin login',
                        style: TextStyle(color: _slate, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Station subdomain field
          _inputField(
            controller: _slugCtrl,
            hint: 'e.g. lion',
            label: 'Your station subdomain',
            keyboardType: TextInputType.url,
            suffixText: '.fmstream.online',
            helperText: _slugCtrl.text.trim().isNotEmpty
                ? '${_slugCtrl.text.trim()}.fmstream.online'
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Email field
          _inputField(
            controller: _emailCtrl,
            hint: 'Email address',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Password field with show/hide
          _inputField(
            controller: _passCtrl,
            hint: 'Password',
            obscureText: _obscurePass,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            onSubmitted: (_) => _signInToStation(),
          ),
          const SizedBox(height: 20),

          // Sign in button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _signingIn ? null : _signInToStation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: _btnText,
                disabledBackgroundColor: _teal.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _signingIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _btnText,
                      ),
                    )
                  : const Text(
                      'Sign in to your station',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _btnText,
                      ),
                    ),
            ),
          ),

          // Error message
          if (_signInError != null) ...[
            const SizedBox(height: 12),
            Text(
              _signInError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    String? label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? suffixText,
    String? helperText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: label ?? hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 14,
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
        ),
        suffixText: suffixText,
        suffixStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 12,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
      ),
    );
  }
}
