import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repository.dart';
import 'success_confirmation.dart';

class ShowPitchForm extends StatefulWidget {
  const ShowPitchForm({super.key});

  @override
  State<ShowPitchForm> createState() => _ShowPitchFormState();
}

class _ShowPitchFormState extends State<ShowPitchForm> {
  final _formKey = GlobalKey<FormState>();
  final _conceptCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String? _selectedSlot;
  String? _selectedFormat;
  bool _submitting = false;
  bool _submitted = false;
  final _repo = FirestoreRequestRepository();

  static const _slots = [
    'Weekdays 6-8AM',
    'Weekdays 12-2PM',
    'Weekends 10AM-12PM',
    'Flexible',
  ];

  static const _formats = [
    'Talk Show',
    'Interview Programme',
    'Music Show',
    'Educational',
    'News & Affairs',
  ];

  @override
  void dispose() {
    _conceptCtrl.dispose();
    _deptCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await _repo.submitRequest(RequestModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RequestType.showPitch,
      requesterName: _deptCtrl.text,
      showConceptName: _conceptCtrl.text,
      department: _deptCtrl.text,
      preferredSlot: _selectedSlot,
      format: _selectedFormat,
      message: _descCtrl.text,
      contactInfo: _contactCtrl.text,
      submittedAt: DateTime.now(),
    ), userId: FirebaseAuth.instance.currentUser?.uid);
    if (mounted) setState(() { _submitting = false; _submitted = true; });
  }

  void _reset() {
    _formKey.currentState?.reset();
    _conceptCtrl.clear();
    _deptCtrl.clear();
    _descCtrl.clear();
    _contactCtrl.clear();
    setState(() { _selectedSlot = null; _selectedFormat = null; _submitted = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return SuccessConfirmation(
        isSongRequest: false,
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
            _field(_conceptCtrl, AppStrings.showConcept, required: true),
            const SizedBox(height: AppDimensions.p12),
            _field(_deptCtrl, AppStrings.department,
                hint: AppStrings.departmentHint, required: true),
            const SizedBox(height: AppDimensions.p12),
            _dropdown(_slots, _selectedSlot, AppStrings.preferredSlot,
                (v) => setState(() => _selectedSlot = v)),
            const SizedBox(height: AppDimensions.p12),
            _dropdown(_formats, _selectedFormat, AppStrings.format,
                (v) => setState(() => _selectedFormat = v)),
            const SizedBox(height: AppDimensions.p12),
            _field(_descCtrl, AppStrings.briefDescription,
                required: true, maxLines: 4, maxLength: 500),
            const SizedBox(height: AppDimensions.p12),
            _field(_contactCtrl, AppStrings.contactInfo, required: true),
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
                    : const Text(AppStrings.submitPitch),
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

  Widget _dropdown(
    List<String> items,
    String? value,
    String label,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.surface2,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null ? AppStrings.fieldRequired : null,
      onChanged: onChanged,
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
    );
  }
}
