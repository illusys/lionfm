import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

final _showsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('shows')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs
          .map<Map<String, dynamic>>(
            (d) => <String, dynamic>{'id': d.id, ...d.data()},
          )
          .toList());
});

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dayCodes = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

class ScheduleManagerScreen extends ConsumerStatefulWidget {
  const ScheduleManagerScreen({super.key});

  @override
  ConsumerState<ScheduleManagerScreen> createState() =>
      _ScheduleManagerScreenState();
}

class _ScheduleManagerScreenState
    extends ConsumerState<ScheduleManagerScreen> {
  int _selectedDay = DateTime.now().weekday - 1;

  @override
  Widget build(BuildContext context) {
    final showsAsync = ref.watch(_showsStreamProvider);
    final now = DateTime.now();
    final nowTimeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Schedule Manager'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddShowSheet(context),
        backgroundColor: AppColors.lionGreen,
        foregroundColor: AppColors.bg0,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Day filter tabs
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.p16, vertical: 8),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _dayLabels.length,
              itemBuilder: (_, i) {
                final isSelected = i == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.greenTealGradient : null,
                      color: isSelected ? null : AppColors.bg2,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.rFull),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.border1,
                      ),
                    ),
                    child: Text(
                      _dayLabels[i],
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.bg0
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border1),
          Expanded(
            child: showsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTextStyles.body),
              ),
              data: (shows) {
                final dayCode = _dayCodes[_selectedDay];
                final filtered = shows.where((s) {
                  final days = s['days'] as List<dynamic>? ?? [];
                  return days.contains(dayCode);
                }).toList()
                  ..sort((a, b) =>
                      (a['startTime'] as String? ?? '')
                          .compareTo(b['startTime'] as String? ?? ''));

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 16),
                        Text('No shows on ${_dayLabels[_selectedDay]}',
                            style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _showAddShowSheet(context),
                          child: const Text('Add a show'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final show = filtered[i];
                    final startStr = show['startTime'] as String? ?? '';
                    final endStr = show['endTime'] as String? ?? '';
                    final isLiveNow = startStr.isNotEmpty &&
                        endStr.isNotEmpty &&
                        nowTimeStr.compareTo(startStr) >= 0 &&
                        nowTimeStr.compareTo(endStr) < 0 &&
                        _selectedDay == DateTime.now().weekday - 1;

                    return _ShowCard(
                      show: show,
                      isLiveNow: isLiveNow,
                      onDelete: () =>
                          _deleteShow(show['id'] as String),
                      onDuplicate: () =>
                          _showDuplicateSheet(context, show),
                      onToggleSpecial: () =>
                          _toggleSpecial(show['id'] as String,
                              show['isSpecial'] as bool? ?? false),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShow(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Remove Show'),
        content: const Text('Remove this show from the schedule?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('shows')
          .doc(id)
          .update({'isActive': false});
    }
  }

  Future<void> _toggleSpecial(String id, bool current) async {
    await FirebaseFirestore.instance
        .collection('shows')
        .doc(id)
        .update({'isSpecial': !current});
  }

  void _showDuplicateSheet(
      BuildContext context, Map<String, dynamic> show) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DuplicateSheet(show: show),
    );
  }

  void _showAddShowSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddShowSheet(),
    );
  }
}

// ─── Show Card ────────────────────────────────────────────────────────────────

class _ShowCard extends StatelessWidget {
  final Map<String, dynamic> show;
  final bool isLiveNow;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleSpecial;

  const _ShowCard({
    required this.show,
    required this.isLiveNow,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleSpecial,
  });

  @override
  Widget build(BuildContext context) {
    final title = show['title'] as String? ?? '—';
    final host = show['host'] as String? ?? '';
    final start = show['startTime'] as String? ?? '';
    final end = show['endTime'] as String? ?? '';
    final category = show['category'] as String? ?? '';
    final isSpecial = show['isSpecial'] as bool? ?? false;
    final days = (show['days'] as List<dynamic>? ?? [])
        .map((d) => _dayLabel(d as String))
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.p8),
      padding: const EdgeInsets.all(AppDimensions.p12),
      decoration: BoxDecoration(
        color: isLiveNow
            ? AppColors.liveRed.withValues(alpha: 0.07)
            : AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(
          color: isLiveNow
              ? AppColors.liveRed.withValues(alpha: 0.4)
              : AppColors.border1,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(start,
                  style: AppTextStyles.mono
                      .copyWith(color: AppColors.lionGreen)),
              Text(end,
                  style: AppTextStyles.mono
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isLiveNow)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.liveRed,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.rFull),
                        ),
                        child: Text('● LIVE',
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white, fontSize: 9)),
                      ),
                    if (isSpecial)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningGold
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.rFull),
                        ),
                        child: Text('SPECIAL',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.warningGold,
                                fontSize: 9)),
                      ),
                    Flexible(
                      child: Text(title, style: AppTextStyles.bodyMedium,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (host.isNotEmpty)
                  Text(host, style: AppTextStyles.caption),
                if (days.isNotEmpty || category.isNotEmpty)
                  Text(
                    [if (days.isNotEmpty) days, if (category.isNotEmpty) category]
                        .join(' · '),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.electricTeal),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.bg3,
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textMuted, size: 20),
            onSelected: (action) {
              switch (action) {
                case 'duplicate':
                  onDuplicate();
                  break;
                case 'special':
                  onToggleSpecial();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(children: [
                    Icon(Icons.copy_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Duplicate to day'),
                  ])),
              PopupMenuItem(
                  value: 'special',
                  child: Row(children: [
                    Icon(Icons.star_outline_rounded,
                        size: 16,
                        color: isSpecial ? AppColors.warningGold : null),
                    const SizedBox(width: 8),
                    Text(isSpecial ? 'Remove Special' : 'Mark as Special'),
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.errorRed),
                    SizedBox(width: 8),
                    Text('Remove',
                        style: TextStyle(color: AppColors.errorRed)),
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  String _dayLabel(String code) {
    final idx = _dayCodes.indexOf(code);
    return idx >= 0 ? _dayLabels[idx] : code;
  }
}

// ─── Duplicate Sheet ──────────────────────────────────────────────────────────

class _DuplicateSheet extends StatefulWidget {
  final Map<String, dynamic> show;
  const _DuplicateSheet({required this.show});

  @override
  State<_DuplicateSheet> createState() => _DuplicateSheetState();
}

class _DuplicateSheetState extends State<_DuplicateSheet> {
  final Set<String> _selectedDays = {};
  bool _saving = false;

  Future<void> _duplicate() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one day')));
      return;
    }
    setState(() => _saving = true);
    try {
      final existing = List<String>.from(
          (widget.show['days'] as List<dynamic>?)?.cast<String>() ?? []);
      final merged = {...existing, ..._selectedDays}.toList();
      await FirebaseFirestore.instance
          .collection('shows')
          .doc(widget.show['id'] as String)
          .update({'days': merged});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Show duplicated to selected days'),
          backgroundColor: AppColors.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Duplicate "${widget.show['title']}"',
              style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Add to additional days:',
              style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(_dayLabels.length, (i) {
              final code = _dayCodes[i];
              final existing =
                  (widget.show['days'] as List<dynamic>?)?.contains(code) ??
                      false;
              final isSelected = _selectedDays.contains(code);
              return FilterChip(
                label: Text(_dayLabels[i]),
                selected: isSelected,
                onSelected: existing
                    ? null
                    : (on) => setState(() {
                          if (on) {
                            _selectedDays.add(code);
                          } else {
                            _selectedDays.remove(code);
                          }
                        }),
                selectedColor:
                    AppColors.lionGreen.withValues(alpha: 0.25),
                checkmarkColor: AppColors.lionGreen,
                backgroundColor:
                    existing ? AppColors.bg3.withValues(alpha: 0.4) : AppColors.bg3,
                side: BorderSide(
                  color: isSelected ? AppColors.lionGreen : AppColors.border1,
                ),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: existing
                      ? AppColors.textMuted
                      : isSelected
                          ? AppColors.lionGreen
                          : AppColors.textSecondary,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _duplicate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lionGreen,
              foregroundColor: AppColors.bg0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bg0))
                : const Text('Duplicate'),
          ),
        ],
      ),
    );
  }
}

// ─── Add Show Sheet ───────────────────────────────────────────────────────────

class _AddShowSheet extends ConsumerStatefulWidget {
  const _AddShowSheet();

  @override
  ConsumerState<_AddShowSheet> createState() => _AddShowSheetState();
}

class _AddShowSheetState extends ConsumerState<_AddShowSheet> {
  final _titleCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _presenterCtrl = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final Set<String> _selectedDays = {};
  String _category = 'Music';
  bool _saving = false;

  static const _categories = [
    'Music',
    'News',
    'Sports',
    'Campus Life',
    'Talk',
    'Entertainment',
    'Health',
    'Tech',
    'Devotion',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hostCtrl.dispose();
    _presenterCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay? t) {
    if (t == null) return 'Tap to set';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? TimeOfDay.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lionGreen,
            surface: AppColors.bg2,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.bg2),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _err('Show title is required');
      return;
    }
    if (_startTime == null || _endTime == null) {
      _err('Start and end time are required');
      return;
    }
    final startMins = _startTime!.hour * 60 + _startTime!.minute;
    final endMins = _endTime!.hour * 60 + _endTime!.minute;
    if (endMins <= startMins) {
      _err('End time must be after start time');
      return;
    }
    if (_selectedDays.isEmpty) {
      _err('Select at least one day');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('shows').add({
        'title': _titleCtrl.text.trim(),
        'host': _hostCtrl.text.trim(),
        'presenter': _presenterCtrl.text.trim(),
        'startTime': _fmt(_startTime),
        'endTime': _fmt(_endTime),
        'days': _selectedDays.toList(),
        'category': _category,
        'isActive': true,
        'isSpecial': false,
        'isRecurring': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _err('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.errorRed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Show', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: 'Show Title',
              filled: true,
              fillColor: AppColors.bg3,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hostCtrl,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: 'Host Name',
              filled: true,
              fillColor: AppColors.bg3,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _presenterCtrl,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: 'Presenter / Profile Link (optional)',
              filled: true,
              fillColor: AppColors.bg3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _TimePicker(
                      label: 'Start Time',
                      value: _fmt(_startTime),
                      onTap: () => _pickTime(true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _TimePicker(
                      label: 'End Time',
                      value: _fmt(_endTime),
                      onTap: () => _pickTime(false))),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            dropdownColor: AppColors.bg3,
            decoration: const InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: AppColors.bg3,
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          Text('Days', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(_dayLabels.length, (i) {
              final code = _dayCodes[i];
              final isSelected = _selectedDays.contains(code);
              return FilterChip(
                label: Text(_dayLabels[i]),
                selected: isSelected,
                onSelected: (on) => setState(() {
                  if (on) {
                    _selectedDays.add(code);
                  } else {
                    _selectedDays.remove(code);
                  }
                }),
                selectedColor:
                    AppColors.lionGreen.withValues(alpha: 0.25),
                checkmarkColor: AppColors.lionGreen,
                backgroundColor: AppColors.bg3,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.lionGreen
                      : AppColors.border1,
                ),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.lionGreen
                      : AppColors.textSecondary,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lionGreen,
              foregroundColor: AppColors.bg0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bg0))
                : const Text('Add Show'),
          ),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimePicker(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSet = value != 'Tap to set';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(color: AppColors.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSet
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.access_time_rounded,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
