import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/login_prompt_sheet.dart';
import 'success_confirmation.dart';

class SongRequestForm extends ConsumerStatefulWidget {
  const SongRequestForm({super.key});

  @override
  ConsumerState<SongRequestForm> createState() => _SongRequestFormState();
}

class _SongRequestFormState extends ConsumerState<SongRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _songCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _dedicateCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String? _selectedShow;
  bool _submitting = false;
  bool _submitted = false;
  final _repo = MockRequestRepository();

  static const _shows = [
    'Afternoon Drive (4PM)',
    'Morning Glory (6AM)',
    'Night Owls (8PM)',
  ];

  @override
  void dispose() {
    _songCtrl.dispose();
    _artistCtrl.dispose();
    _dedicateCtrl.dispose();
    _nameCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isGuest = ref.read(isGuestModeProvider);
    final isSignedIn = ref.read(authStateProvider).valueOrNull != null;
    if (isGuest && !isSignedIn) {
      await LoginPromptSheet.show(
        context,
        reason: 'Sign in to send a song request to Lion FM.',
      );
      return;
    }
    setState(() => _submitting = true);
    await _repo.submitRequest(RequestModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RequestType.song,
      songTitle: _songCtrl.text,
      artistName: _artistCtrl.text,
      dedicatedTo: _dedicateCtrl.text.isEmpty ? null : _dedicateCtrl.text,
      requesterName: _nameCtrl.text,
      requestedShow: _selectedShow,
      message: _messageCtrl.text.isEmpty ? null : _messageCtrl.text,
      submittedAt: DateTime.now(),
    ));
    if (mounted) setState(() { _submitting = false; _submitted = true; });
  }

  void _reset() {
    _formKey.currentState?.reset();
    _songCtrl.clear();
    _artistCtrl.clear();
    _dedicateCtrl.clear();
    _nameCtrl.clear();
    _messageCtrl.clear();
    setState(() { _selectedShow = null; _submitted = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return SuccessConfirmation(
        isSongRequest: true,
        onSendAnother: _reset,
        onBackHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.p16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _field(_songCtrl, AppStrings.songTitle, required: true, maxLength: 100),
            const SizedBox(height: AppDimensions.p12),
            _field(_artistCtrl, AppStrings.artistName, required: true),
            const SizedBox(height: AppDimensions.p12),
            _field(_dedicateCtrl, AppStrings.dedicateTo,
                hint: AppStrings.dedicateHint),
            const SizedBox(height: AppDimensions.p12),
            _field(_nameCtrl, AppStrings.yourName, required: true),
            const SizedBox(height: AppDimensions.p12),
            DropdownButtonFormField<String>(
              initialValue: _selectedShow,
              dropdownColor: AppColors.surface2,
              decoration: const InputDecoration(labelText: AppStrings.showToPlayOn),
              validator: (v) => v == null ? AppStrings.fieldRequired : null,
              onChanged: (v) => setState(() => _selectedShow = v),
              items: _shows
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
            ),
            const SizedBox(height: AppDimensions.p12),
            _field(_messageCtrl, AppStrings.message,
                hint: AppStrings.messageHint, maxLines: 3, maxLength: 500),
            const SizedBox(height: AppDimensions.p24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.appBackground),
                      )
                    : const Text(AppStrings.sendRequest),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    String? hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? AppStrings.fieldRequired : null
          : null,
    );
  }
}
