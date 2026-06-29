import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../data/repositories/station_repository.dart';
import '../../models/station.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/current_station_provider.dart';

// ─── Teal accent used throughout ──────────────────────────────────────────────
const _kTeal = Color(0xFF15E0B4);

enum _StreamTest { idle, testing, ok, fail }

// ─────────────────────────────────────────────────────────────────────────────
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  // ── S1: Station Identity ─────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  String _logoUrl = '';
  bool _uploadingLogo = false;

  // Brand colors (hex strings)
  final _primaryCtrl = TextEditingController();
  final _accentCtrl = TextEditingController();
  final _bgCtrl = TextEditingController();
  String _secondaryColor = '#28D7D2'; // preserved; not exposed in UI

  // ── S2: Stream ───────────────────────────────────────────────────────────
  final _streamUrlCtrl = TextEditingController();
  _StreamTest _streamTest = _StreamTest.idle;

  // ── S3: Monetisation ─────────────────────────────────────────────────────
  final _premiumPriceCtrl = TextEditingController();
  final _adRateCPMCtrl = TextEditingController();

  // ── S5: Custom Domain ────────────────────────────────────────────────────
  final _domainCtrl = TextEditingController();
  bool _savingDomain = false;

  // ── S7: Revenue Split ────────────────────────────────────────────────────
  final _lionFmPctCtrl = TextEditingController();
  final _illusysPctCtrl = TextEditingController();
  final _unnPctCtrl = TextEditingController();
  String? _revSplitError;
  bool _savingRevSplit = false;

  // ── Loaded station state ─────────────────────────────────────────────────
  StationPlan _plan = StationPlan.starter;
  StationPlanStatus _planStatus = StationPlanStatus.active;
  DateTime? _trialEndsAt;
  String _stationSlug = '';

  // ── UI flags ─────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;

  // ── Migration (kept from original, platformOwner only) ───────────────────
  bool _seedingStation = false;
  String? _seedStatus;
  bool _stampingDocs = false;
  String? _stampStatus;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _primaryCtrl.addListener(() => setState(() {}));
    _accentCtrl.addListener(() => setState(() {}));
    _bgCtrl.addListener(() => setState(() {}));
    _loadSettings();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _freqCtrl.dispose();
    _taglineCtrl.dispose();
    _contactEmailCtrl.dispose();
    _primaryCtrl.dispose();
    _accentCtrl.dispose();
    _bgCtrl.dispose();
    _streamUrlCtrl.dispose();
    _premiumPriceCtrl.dispose();
    _adRateCPMCtrl.dispose();
    _domainCtrl.dispose();
    _lionFmPctCtrl.dispose();
    _illusysPctCtrl.dispose();
    _unnPctCtrl.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  String get _stationId => ref.read(currentStationIdProvider) ?? 'lion';
  String get _streamDocId => _stationId == 'lion' ? 'current' : _stationId;

  Future<void> _loadSettings() async {
    final sid = _stationId;
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('stations').doc(sid).get(),
        FirebaseFirestore.instance
            .collection('stream_config')
            .doc(_streamDocId)
            .get(),
        FirebaseFirestore.instance
            .collection('admin_config')
            .doc('revenue')
            .get(),
      ]);

      final stDoc = results[0];
      final streamDoc = results[1];
      final revDoc = results[2];

      if (stDoc.exists) {
        final d = stDoc.data()!;
        final colors = Map<String, dynamic>.from(d['brandColors'] as Map? ?? {});
        _nameCtrl.text = d['name'] as String? ?? '';
        _freqCtrl.text = d['frequency'] as String? ?? '';
        _taglineCtrl.text = d['tagline'] as String? ?? '';
        _contactEmailCtrl.text = d['contactEmail'] as String? ?? '';
        _logoUrl = d['logoUrl'] as String? ?? '';
        _primaryCtrl.text = colors['primary'] as String? ?? '#15E0B4';
        _accentCtrl.text = colors['accent'] as String? ?? '#F5A623';
        _bgCtrl.text = colors['background'] as String? ?? '#0A0A0A';
        _secondaryColor = colors['secondary'] as String? ?? '#28D7D2';
        _stationSlug = d['slug'] as String? ?? sid;
        _plan = _parsePlan(d['plan'] as String?);
        _planStatus = _parseStatus(d['planStatus'] as String?);
        _trialEndsAt =
            (d['trialEndsAt'] as Timestamp?)?.toDate();
        _premiumPriceCtrl.text =
            (d['premiumPrice'] ?? '').toString();
        _adRateCPMCtrl.text = (d['adRateCPM'] ?? '').toString();
        _domainCtrl.text = d['customDomain'] as String? ?? '';
      }

      _streamUrlCtrl.text =
          streamDoc.data()?['streamUrl'] as String? ?? '';

      final rev = revDoc.data();
      _lionFmPctCtrl.text = (rev?['lionFmPct'] ?? 45).toString();
      _illusysPctCtrl.text = (rev?['illusysPct'] ?? 40).toString();
      _unnPctCtrl.text = (rev?['unnPct'] ?? 15).toString();
    } catch (_) {
      _lionFmPctCtrl.text = '45';
      _illusysPctCtrl.text = '40';
      _unnPctCtrl.text = '15';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  StationPlan _parsePlan(String? s) => switch (s) {
        'starter' => StationPlan.starter,
        'pro' => StationPlan.pro,
        'enterprise' => StationPlan.enterprise,
        _ => StationPlan.free,
      };

  StationPlanStatus _parseStatus(String? s) => switch (s) {
        'trialing' => StationPlanStatus.trialing,
        'past_due' => StationPlanStatus.pastDue,
        'suspended' => StationPlanStatus.suspended,
        _ => StationPlanStatus.active,
      };

  // ── Save main (S1 + S2 + S3) ─────────────────────────────────────────────

  Future<void> _saveMain() async {
    final sid = _stationId;
    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final stationData = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'frequency': _freqCtrl.text.trim(),
        'tagline': _taglineCtrl.text.trim(),
        'contactEmail': _contactEmailCtrl.text.trim(),
        'logoUrl': _logoUrl,
        'brandColors': {
          'primary': _primaryCtrl.text.trim(),
          'secondary': _secondaryColor,
          'accent': _accentCtrl.text.trim(),
          'background': _bgCtrl.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (_plan == StationPlan.pro || _plan == StationPlan.enterprise) {
        stationData['premiumPrice'] =
            int.tryParse(_premiumPriceCtrl.text.trim()) ?? 0;
      }
      if (_plan == StationPlan.enterprise) {
        stationData['adRateCPM'] =
            int.tryParse(_adRateCPMCtrl.text.trim()) ?? 0;
      }

      batch.set(db.collection('stations').doc(sid), stationData,
          SetOptions(merge: true));

      batch.set(
        db.collection('stream_config').doc(_streamDocId),
        {
          'streamUrl': _streamUrlCtrl.text.trim(),
          'stationId': sid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      _showSnack('Settings saved');
    } catch (e) {
      _showSnack('Error saving: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Logo upload ───────────────────────────────────────────────────────────

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    if (file.size > 2 * 1024 * 1024) {
      _showSnack('Logo must be under 2 MB', isError: true);
      return;
    }

    setState(() => _uploadingLogo = true);
    try {
      final ext = file.extension ?? 'png';
      final ref = FirebaseStorage.instance
          .ref()
          .child('station-assets/${_stationId}/logo.$ext');
      await ref.putData(
          file.bytes!,
          SettableMetadata(
              contentType: 'image/$ext',
              customMetadata: {'stationId': _stationId}));
      final url = await ref.getDownloadURL();
      setState(() => _logoUrl = url);
      _showSnack('Logo uploaded — save settings to apply');
    } catch (e) {
      _showSnack('Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  // ── Custom domain save ────────────────────────────────────────────────────

  Future<void> _saveCustomDomain() async {
    setState(() => _savingDomain = true);
    try {
      final domain = _domainCtrl.text.trim();
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(_stationId)
          .set({'customDomain': domain.isEmpty ? null : domain},
              SetOptions(merge: true));
      _showSnack('Custom domain saved');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingDomain = false);
    }
  }

  // ── Revenue split save ────────────────────────────────────────────────────

  Future<void> _saveRevenueSplit() async {
    final a = int.tryParse(_lionFmPctCtrl.text.trim()) ?? 0;
    final b = int.tryParse(_illusysPctCtrl.text.trim()) ?? 0;
    final c = int.tryParse(_unnPctCtrl.text.trim()) ?? 0;
    if (a + b + c != 100) {
      setState(() => _revSplitError =
          'Values must sum to 100 (currently ${a + b + c})');
      return;
    }
    setState(() {
      _revSplitError = null;
      _savingRevSplit = true;
    });
    try {
      final adminUser = ref.read(adminUserProvider).valueOrNull;
      await FirebaseFirestore.instance
          .collection('admin_config')
          .doc('revenue')
          .set({
        'stationId': _stationId,
        'lionFmPct': a,
        'illusysPct': b,
        'unnPct': c,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUser?.uid ?? '',
      }, SetOptions(merge: true));
      _showSnack('Revenue split saved');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingRevSplit = false);
    }
  }

  // ── Stream test ───────────────────────────────────────────────────────────

  Future<void> _testStream() async {
    final url = _streamUrlCtrl.text.trim();
    if (url.isEmpty) {
      _showSnack('Enter a stream URL first');
      return;
    }
    setState(() => _streamTest = _StreamTest.testing);
    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player
          .setUrl(url, preload: true)
          .timeout(const Duration(seconds: 10));
      if (mounted) setState(() => _streamTest = _StreamTest.ok);
    } catch (_) {
      if (mounted) setState(() => _streamTest = _StreamTest.fail);
    } finally {
      await player?.dispose();
    }
  }

  Future<void> _loadTestStream() async {
    const testUrl = 'https://stream.radioparadise.com/aac-128';
    try {
      await FirebaseFirestore.instance
          .collection('stream_config')
          .doc(_streamDocId)
          .set({'streamUrl': testUrl}, SetOptions(merge: true));
      setState(() {
        _streamUrlCtrl.text = testUrl;
        _streamTest = _StreamTest.idle;
      });
      _showSnack('Test stream URL loaded');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  // ── Danger zone ───────────────────────────────────────────────────────────

  Future<void> _clearDoneRequests() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Clear Request Queue'),
        content: const Text(
            'Delete all requests with status "played" or "skipped"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final sid = _stationId;
      final snaps = await Future.wait([
        FirebaseFirestore.instance
            .collection('requests')
            .where('stationId', isEqualTo: sid)
            .where('status', isEqualTo: 'played')
            .get(),
        FirebaseFirestore.instance
            .collection('requests')
            .where('stationId', isEqualTo: sid)
            .where('status', isEqualTo: 'skipped')
            .get(),
      ]);
      final batch = FirebaseFirestore.instance.batch();
      int count = 0;
      for (final snap in snaps) {
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
          count++;
        }
      }
      await batch.commit();
      _showSnack('Deleted $count completed requests');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _exportData() async {
    try {
      final sid = _stationId;
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('shows')
            .where('stationId', isEqualTo: sid)
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .where('stationId', isEqualTo: sid)
            .get(),
      ]);
      final rows = <List<dynamic>>[
        ['--- SHOWS ---'],
        ['Title', 'Host', 'Days', 'Start', 'End'],
        ...results[0].docs.map((d) => [
              d['title'] ?? '',
              d['host'] ?? '',
              (d['days'] as List?)?.join(',') ?? '',
              d['startTime'] ?? '',
              d['endTime'] ?? '',
            ]),
        [],
        ['--- USERS ---'],
        ['Name', 'Email', 'Role'],
        ...results[1].docs.map((d) => [
              d['displayName'] ?? '',
              d['email'] ?? '',
              d['role'] ?? '',
            ]),
      ];
      final csv = const ListToCsvConverter().convert(rows);
      await Clipboard.setData(ClipboardData(text: csv));
      _showSnack('CSV copied to clipboard');
    } catch (e) {
      _showSnack('Export failed: $e', isError: true);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/admin-login');
  }

  // ── Migration helpers (kept for platformOwner) ────────────────────────────

  Future<void> _seedLionFmStation() async {
    setState(() {
      _seedingStation = true;
      _seedStatus = null;
    });
    try {
      final msg = await StationRepository().seedLionFmStation();
      if (mounted) setState(() => _seedStatus = msg ?? 'Lion FM seeded.');
    } catch (e) {
      if (mounted) setState(() => _seedStatus = 'Error: $e');
    } finally {
      if (mounted) setState(() => _seedingStation = false);
    }
  }

  Future<void> _stampTenantDocs() async {
    setState(() {
      _stampingDocs = true;
      _stampStatus = null;
    });
    try {
      final result = await StationRepository().stampTenantDocs();
      if (mounted) setState(() => _stampStatus = result);
    } catch (e) {
      if (mounted) setState(() => _stampStatus = 'Error: $e');
    } finally {
      if (mounted) setState(() => _stampingDocs = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? AppColors.errorRed : AppColors.successGreen,
    ));
  }

  Color? _hexColor(String hex) {
    final h = hex.replaceAll('#', '').trim();
    if (h.length != 6) return null;
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return null;
    }
  }

  bool get _isPro =>
      _plan == StationPlan.pro || _plan == StationPlan.enterprise;
  bool get _isEnterprise => _plan == StationPlan.enterprise;

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final adminUser = ref.watch(adminUserProvider).valueOrNull;
    final isSuperAdmin = adminUser?.isSuperAdmin == true;
    final isPlatformOwner = adminUser?.isPlatformOwner == true;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(child: CircularProgressIndicator(color: _kTeal)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveMain,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kTeal))
                : const Text('Save',
                    style: TextStyle(color: _kTeal)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          _buildSection1Identity(),
          const SizedBox(height: AppDimensions.p24),
          _buildSection2Stream(isSuperAdmin),
          const SizedBox(height: AppDimensions.p24),
          _buildSection3Monetisation(),
          const SizedBox(height: AppDimensions.p24),
          _buildSection4Billing(),
          const SizedBox(height: AppDimensions.p24),
          _buildSection5Domain(),
          const SizedBox(height: AppDimensions.p24),
          if (isSuperAdmin) ...[
            _buildSection6Firebase(),
            const SizedBox(height: AppDimensions.p24),
          ],
          if (isPlatformOwner) ...[
            _buildSection7RevenueSplit(),
            const SizedBox(height: AppDimensions.p24),
          ],
          _buildSection8DangerZone(isSuperAdmin, isPlatformOwner),
          const SizedBox(height: AppDimensions.p32),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 1 — STATION IDENTITY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection1Identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Station Identity'),
        const SizedBox(height: AppDimensions.p12),
        _card(children: [
          _field(_nameCtrl, 'Station Name',
              hint: 'e.g. Wash FM'),
          const SizedBox(height: AppDimensions.p12),
          _field(_freqCtrl, 'Frequency',
              hint: 'e.g. 94.9 MHz'),
          const SizedBox(height: AppDimensions.p12),
          _field(_taglineCtrl, 'Tagline',
              hint: 'Up to 60 characters',
              maxLength: 60),
          const SizedBox(height: AppDimensions.p12),
          _field(_contactEmailCtrl, 'Contact Email',
              hint: 'station@example.com',
              keyboardType: TextInputType.emailAddress),
        ]),
        const SizedBox(height: AppDimensions.p16),

        // Logo
        const _SectionHeader(title: 'Station Logo'),
        const SizedBox(height: AppDimensions.p12),
        _card(children: [
          Row(
            children: [
              if (_logoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_logoUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _logoPlaceholder()),
                )
              else
                _logoPlaceholder(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PNG or JPG, square format, max 2 MB',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed:
                          _uploadingLogo ? null : _pickLogo,
                      icon: _uploadingLogo
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _kTeal))
                          : const Icon(Icons.upload_rounded,
                              size: 16),
                      label: Text(_uploadingLogo
                          ? 'Uploading…'
                          : 'Change logo'),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _kTeal),
                          foregroundColor: _kTeal),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
        const SizedBox(height: AppDimensions.p16),

        // Brand Colors
        const _SectionHeader(title: 'Brand Colors'),
        const SizedBox(height: AppDimensions.p12),
        _card(children: [
          _colorField(_primaryCtrl, 'Primary color'),
          const SizedBox(height: AppDimensions.p12),
          _colorField(_accentCtrl, 'Accent color'),
          const SizedBox(height: AppDimensions.p12),
          _colorField(_bgCtrl, 'Background color'),
          const SizedBox(height: 8),
          Text('Changes apply after saving.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted)),
        ]),
      ],
    );
  }

  Widget _logoPlaceholder() => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border1),
        ),
        child: const Icon(Icons.radio_rounded,
            color: AppColors.textMuted, size: 28),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 2 — STREAM CONFIGURATION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection2Stream(bool isSuperAdmin) {
    final testIcon = switch (_streamTest) {
      _StreamTest.idle => const Icon(Icons.wifi_tethering_rounded, size: 16),
      _StreamTest.testing => const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kTeal)),
      _StreamTest.ok => const Icon(Icons.check_circle_rounded,
          size: 16, color: AppColors.successGreen),
      _StreamTest.fail =>
        const Icon(Icons.error_rounded, size: 16, color: AppColors.errorRed),
    };
    final testLabel = switch (_streamTest) {
      _StreamTest.idle => 'Test',
      _StreamTest.testing => 'Testing…',
      _StreamTest.ok => 'OK',
      _StreamTest.fail => 'Failed',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Stream Configuration'),
        const SizedBox(height: AppDimensions.p12),
        _card(children: [
          _field(_streamUrlCtrl, 'Stream URL',
              hint: 'https://stream.example.com/live',
              keyboardType: TextInputType.url),
          const SizedBox(height: AppDimensions.p12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _streamTest == _StreamTest.testing
                    ? null
                    : _testStream,
                icon: testIcon,
                label: Text(testLabel),
                style: OutlinedButton.styleFrom(
                    foregroundColor: _kTeal,
                    side: const BorderSide(color: _kTeal)),
              ),
              if (isSuperAdmin) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _loadTestStream,
                  icon: const Icon(Icons.science_rounded, size: 16),
                  label: const Text('Load test'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side:
                          const BorderSide(color: AppColors.border1)),
                ),
              ],
            ],
          ),
        ]),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 3 — MONETISATION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection3Monetisation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionHeader(title: 'Monetisation'),
            const SizedBox(width: 8),
            _PlanBadge(_plan),
          ],
        ),
        const SizedBox(height: AppDimensions.p12),
        if (!_isPro) ...[
          // Info card for free/starter
          _card(children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_rounded, color: _kTeal, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Advertising on your station is managed by FMStream. '
                    'You earn a share of ad revenue generated by your listeners. '
                    'Upgrade to Pro to run your own direct ad campaigns.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: AppDimensions.p12),
          _upgradeCard('Upgrade to Pro to unlock direct ads and premium pricing →'),
        ] else ...[
          _card(children: [
            _field(_premiumPriceCtrl, 'Premium listener price (NGN/month)',
                hint: '500',
                keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            if (_isEnterprise) ...[
              const SizedBox(height: AppDimensions.p12),
              _field(_adRateCPMCtrl, 'Direct ad rate (NGN per CPM)',
                  hint: '1500',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              Text(
                'You have full control of advertising on your station.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted),
              ),
            ] else ...[
              Text(
                'Your direct ad campaigns are managed in the Ad Manager section.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ]),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 4 — SUBSCRIPTION & BILLING
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection4Billing() {
    final (planLabel, planColor, planPrice) = switch (_plan) {
      StationPlan.free => ('Free', const Color(0xFF6B7280), 'Free forever'),
      StationPlan.starter =>
        ('Starter', const Color(0xFF4A7BF7), '₦15,000/month'),
      StationPlan.pro => ('Pro', _kTeal, '₦35,000/month'),
      StationPlan.enterprise =>
        ('Enterprise', const Color(0xFFF5A623), '₦100,000/month'),
    };

    final statusLabel = switch (_planStatus) {
      StationPlanStatus.trialing => 'Trial',
      StationPlanStatus.active => 'Active',
      StationPlanStatus.pastDue => 'Past due',
      StationPlanStatus.suspended => 'Suspended',
    };
    final statusColor = switch (_planStatus) {
      StationPlanStatus.active || StationPlanStatus.trialing =>
        AppColors.successGreen,
      StationPlanStatus.pastDue => AppColors.warningGold,
      StationPlanStatus.suspended => AppColors.errorRed,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Subscription & Billing'),
        const SizedBox(height: AppDimensions.p12),
        _card(children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PlanBadge(_plan),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(statusLabel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(planPrice,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: planColor)),
                    if (_planStatus == StationPlanStatus.trialing &&
                        _trialEndsAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Trial ends ${DateFormat('MMM d, y').format(_trialEndsAt!)}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go('/admin/billing'),
                child: const Text('Manage billing →',
                    style: TextStyle(color: _kTeal)),
              ),
            ],
          ),
        ]),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 5 — CUSTOM DOMAIN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection5Domain() {
    final locked = !_isPro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionHeader(title: 'Custom Domain'),
            const SizedBox(width: 8),
            if (locked)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.border1,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Pro+',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.p12),
        if (locked)
          _upgradeCard(
              'Upgrade to Pro to use a custom domain like listen.yourstation.com →')
        else
          _card(children: [
            _field(_domainCtrl, 'Custom domain',
                hint: 'listen.yourstation.com'),
            const SizedBox(height: 8),
            Text(
              'Point your domain\'s CNAME to cname.vercel-dns.com, '
              'then enter it here.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimensions.p12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: _savingDomain ? null : _saveCustomDomain,
                style: OutlinedButton.styleFrom(
                    foregroundColor: _kTeal,
                    side: const BorderSide(color: _kTeal)),
                child: _savingDomain
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kTeal))
                    : const Text('Save domain'),
              ),
            ),
          ]),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 6 — FIREBASE CONFIG (superAdmin only)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection6Firebase() {
    final appDomain = _domainCtrl.text.trim().isNotEmpty
        ? _domainCtrl.text.trim()
        : '$_stationSlug.fmstream.online';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Firebase Configuration'),
        const SizedBox(height: AppDimensions.p12),
        _card(children: [
          const _InfoRow(
              label: 'Firebase Project', value: 'lionfm-unn'),
          const Divider(color: AppColors.border1, height: 16),
          const _InfoRow(
              label: 'Firestore Region',
              value: 'europe-west2 (London)'),
          const Divider(color: AppColors.border1, height: 16),
          const _InfoRow(
              label: 'Auth Domain',
              value: 'lionfm-unn.firebaseapp.com'),
          const Divider(color: AppColors.border1, height: 16),
          _InfoRow(label: 'App Domain', value: appDomain),
        ]),
        const SizedBox(height: AppDimensions.p12),
        OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.bg2,
              title: const Text('Security Rules'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Status', value: 'Active'),
                  SizedBox(height: 8),
                  _InfoRow(label: 'Project', value: 'lionfm-unn'),
                  SizedBox(height: 8),
                  _InfoRow(
                      label: 'Region', value: 'europe-west2 (London)'),
                  SizedBox(height: 8),
                  _InfoRow(
                      label: 'Model',
                      value:
                          'Role-based (platformOwner / superAdmin / stationManager / broadcaster)'),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close')),
              ],
            ),
          ),
          icon: const Icon(Icons.security_rounded, size: 16),
          label: const Text('View Security Rules'),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 7 — REVENUE SPLIT (platformOwner only)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection7RevenueSplit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Revenue Split'),
        const SizedBox(height: AppDimensions.p12),
        _card(children: [
          _RevenueSplitField(
            label: 'Lion FM (UNN)',
            controller: _lionFmPctCtrl,
            color: AppColors.lionGreen,
            onChanged: (_) => setState(() => _revSplitError = null),
          ),
          const SizedBox(height: 10),
          _RevenueSplitField(
            label: 'iLLuSys LTD',
            controller: _illusysPctCtrl,
            color: _kTeal,
            onChanged: (_) => setState(() => _revSplitError = null),
          ),
          const SizedBox(height: 10),
          _RevenueSplitField(
            label: 'Operations (UNN)',
            controller: _unnPctCtrl,
            color: AppColors.warningGold,
            onChanged: (_) => setState(() => _revSplitError = null),
          ),
          if (_revSplitError != null) ...[
            const SizedBox(height: 8),
            Text(_revSplitError!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.errorRed)),
          ],
          const SizedBox(height: 8),
          Text('Values must sum to 100.',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppDimensions.p12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: _savingRevSplit ? null : _saveRevenueSplit,
              style: OutlinedButton.styleFrom(
                  foregroundColor: _kTeal,
                  side: const BorderSide(color: _kTeal)),
              child: _savingRevSplit
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kTeal))
                  : const Text('Save split'),
            ),
          ),
        ]),

        // Migration tools (platformOwner only)
        const SizedBox(height: AppDimensions.p16),
        const _SectionHeader(title: 'FMStream Migration'),
        const SizedBox(height: AppDimensions.p12),
        _card(borderColor: AppColors.borderGold, children: [
          Text(
            'Seed Lion FM as tenant #1 in stations. '
            'Safe to run multiple times — skips if already seeded.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _seedingStation ? null : _seedLionFmStation,
              icon: _seedingStation
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.warningGold))
                  : const Icon(Icons.cloud_upload_rounded, size: 16),
              label: const Text('Seed Lion FM Station'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderGold),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_seedStatus != null) ...[
            const SizedBox(height: 8),
            Text(_seedStatus!,
                style: AppTextStyles.caption.copyWith(
                  color: _seedStatus!.startsWith('Error')
                      ? AppColors.errorRed
                      : AppColors.successGreen,
                )),
          ],
          const SizedBox(height: 16),
          Text(
            'Stamp stationId="lion" on all existing documents missing it.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _stampingDocs ? null : _stampTenantDocs,
              icon: _stampingDocs
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.warningGold))
                  : const Icon(Icons.label_outline_rounded, size: 16),
              label: const Text('Stamp Tenant Docs'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderGold),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_stampStatus != null) ...[
            const SizedBox(height: 8),
            Text(_stampStatus!,
                style: AppTextStyles.caption.copyWith(
                  color: _stampStatus!.startsWith('Error')
                      ? AppColors.errorRed
                      : AppColors.successGreen,
                )),
          ],
        ]),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION 8 — DANGER ZONE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection8DangerZone(
      bool isSuperAdmin, bool isPlatformOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
            title: 'Danger Zone', color: AppColors.errorRed),
        const SizedBox(height: AppDimensions.p12),
        Container(
          padding: const EdgeInsets.all(AppDimensions.p12),
          decoration: BoxDecoration(
            color: AppColors.errorRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.r12),
            border: Border.all(
                color: AppColors.errorRed.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DangerButton(
                label: 'Clear Request Queue',
                subtitle: 'Delete all played/skipped requests',
                onPressed: _clearDoneRequests,
              ),
              const Divider(color: AppColors.border1, height: 24),
              _DangerButton(
                label: 'Export All Data as CSV',
                subtitle: 'Shows, users — copied to clipboard',
                onPressed: _exportData,
                isDestructive: false,
              ),
              const Divider(color: AppColors.border1, height: 24),
              _DangerButton(
                label: 'Sign Out of Admin Portal',
                subtitle: 'Returns to the login screen',
                onPressed: _signOut,
                isDestructive: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Widget helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _card(
          {required List<Widget> children, Color? borderColor}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.p16),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(color: borderColor ?? AppColors.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String hint = '',
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTextStyles.body.copyWith(color: AppColors.textMuted),
            counterText: '',
            filled: true,
            fillColor: AppColors.bg2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide: const BorderSide(color: AppColors.border1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide: const BorderSide(color: AppColors.border1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide:
                  const BorderSide(color: _kTeal, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.p16,
                vertical: AppDimensions.p12),
          ),
        ),
      ],
    );
  }

  Widget _colorField(TextEditingController ctrl, String label) {
    final color = _hexColor(ctrl.text);
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color ?? AppColors.bg3,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _field(ctrl, label, hint: '#RRGGBB'),
        ),
      ],
    );
  }

  Widget _upgradeCard(String message) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.p16),
      decoration: BoxDecoration(
        color: _kTeal.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: _kTeal.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.go('/admin/billing'),
            child: const Text('Upgrade →',
                style: TextStyle(color: _kTeal)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: color ?? AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      );
}

class _PlanBadge extends StatelessWidget {
  final StationPlan plan;
  const _PlanBadge(this.plan);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (plan) {
      StationPlan.free => ('Free', const Color(0xFF6B7280)),
      StationPlan.starter => ('Starter', const Color(0xFF4A7BF7)),
      StationPlan.pro => ('Pro', const Color(0xFF15E0B4)),
      StationPlan.enterprise => ('Enterprise', const Color(0xFFF5A623)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Flexible(
            child: Text(value,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.right),
          ),
        ],
      );
}

class _RevenueSplitField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String>? onChanged;

  const _RevenueSplitField({
    required this.label,
    required this.controller,
    required this.color,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          SizedBox(
            width: 64,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium.copyWith(color: color),
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg3,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: color.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: color.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),
          ),
        ],
      );
}

class _DangerButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _DangerButton({
    required this.label,
    required this.subtitle,
    required this.onPressed,
    this.isDestructive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.errorRed : AppColors.textSecondary;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppDimensions.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          AppTextStyles.bodyMedium.copyWith(color: color)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
