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
  static const _teal = Color(0xFF15E0B4);
  static const _btnText = Color(0xFF06112B);
  static const _slate = Color(0xFF5A6B86);

  bool _showStationSignIn = false;
  final _slugCtrl = TextEditingController();

  @override
  void dispose() {
    _slugCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToStation() async {
    final slug = _slugCtrl.text.trim().toLowerCase();
    if (slug.isEmpty) return;
    final url = Uri.parse('https://$slug.fmstream.online/#/admin-login');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
                  // "I already have a station" expandable section
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showStationSignIn = !_showStationSignIn),
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
                          _showStationSignIn
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  if (_showStationSignIn) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _slugCtrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'your-station-slug',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _teal),
                              ),
                              suffixText: '.fmstream.online',
                              suffixStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 12,
                              ),
                            ),
                            onSubmitted: (_) => _goToStation(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _goToStation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal.withValues(alpha: 0.15),
                              foregroundColor: _teal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: _teal.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Go →',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Platform admin login — very subtle, for Benedict only
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/admin-login'),
                      child: const Text(
                        'Platform admin login',
                        style: TextStyle(
                          color: _slate,
                          fontSize: 13,
                        ),
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
}
