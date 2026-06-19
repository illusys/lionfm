import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';

class SuccessConfirmation extends StatefulWidget {
  final bool isSongRequest;
  final VoidCallback onSendAnother;
  final VoidCallback onBackHome;

  const SuccessConfirmation({
    super.key,
    required this.isSongRequest,
    required this.onSendAnother,
    required this.onBackHome,
  });

  @override
  State<SuccessConfirmation> createState() => _SuccessConfirmationState();
}

class _SuccessConfirmationState extends State<SuccessConfirmation>
    with TickerProviderStateMixin {
  late AnimationController _emojiCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _emojiScale;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _emojiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _emojiScale = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _emojiCtrl, curve: Curves.elasticOut));
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(_textCtrl);

    _emojiCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _textCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _emojiCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.isSongRequest ? '🎵' : '🎙';
    final title = widget.isSongRequest ? 'Request Sent!' : 'Pitch Received!';
    final message = widget.isSongRequest
        ? 'Your song request has been received by the Lion FM studio team. Listen out for your dedication on air!'
        : 'Your show pitch has been received! The Lion FM programming team will review it and be in touch.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _emojiScale,
              child: Text(emoji, style: const TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: AppDimensions.p20),
            FadeTransition(
              opacity: _textOpacity,
              child: Column(
                children: [
                  Text(title, style: AppTextStyles.h1),
                  const SizedBox(height: AppDimensions.p12),
                  Text(
                    message,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.p32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.onSendAnother,
                      child: const Text('Send Another →'),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p12),
                  TextButton(
                    onPressed: widget.onBackHome,
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
