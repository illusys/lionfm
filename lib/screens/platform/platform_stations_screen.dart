import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../models/station.dart';
import '../../providers/station_provider.dart';

enum _FilterType { all, active, trialing, suspended, free, starter, pro, enterprise }

class PlatformStationsScreen extends ConsumerStatefulWidget {
  const PlatformStationsScreen({super.key});

  @override
  ConsumerState<PlatformStationsScreen> createState() =>
      _PlatformStationsScreenState();
}

class _PlatformStationsScreenState
    extends ConsumerState<PlatformStationsScreen> {
  final _searchCtrl = TextEditingController();
  _FilterType _filter = _FilterType.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (_searchCtrl.text != _query) {
        setState(() => _query = _searchCtrl.text.toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Station> _applyFilters(List<Station> all) {
    var list = all;
    // Status / plan filter
    list = switch (_filter) {
      _FilterType.all => list,
      _FilterType.active =>
        list.where((s) => s.planStatus == StationPlanStatus.active).toList(),
      _FilterType.trialing =>
        list.where((s) => s.planStatus == StationPlanStatus.trialing).toList(),
      _FilterType.suspended =>
        list.where((s) => s.planStatus == StationPlanStatus.suspended).toList(),
      _FilterType.free =>
        list.where((s) => s.plan == StationPlan.free).toList(),
      _FilterType.starter =>
        list.where((s) => s.plan == StationPlan.starter).toList(),
      _FilterType.pro =>
        list.where((s) => s.plan == StationPlan.pro).toList(),
      _FilterType.enterprise =>
        list.where((s) => s.plan == StationPlan.enterprise).toList(),
    };
    // Search
    if (_query.isNotEmpty) {
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(_query) ||
              s.slug.toLowerCase().contains(_query) ||
              s.contactEmail.toLowerCase().contains(_query) ||
              s.frequency.toLowerCase().contains(_query))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(allStationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        title: Text('Stations', style: AppTextStyles.h2),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.p16),
            child: stationsAsync.whenOrNull(
              data: (s) => Text('${s.length} total',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.p16,
                AppDimensions.p12, AppDimensions.p16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search by name, slug, email, frequency…',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bg2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                  borderSide: const BorderSide(color: AppColors.border1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                  borderSide: const BorderSide(color: AppColors.border1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.p10),
              ),
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppDimensions.p16,
                AppDimensions.p8, AppDimensions.p16, AppDimensions.p8),
            child: Row(
              children: _FilterType.values
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: _filterLabel(f),
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // List
          Expanded(
            child: stationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.errorRed)),
              ),
              data: (stations) {
                final filtered = _applyFilters(stations);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isNotEmpty || _filter != _FilterType.all
                          ? 'No stations match your filter.'
                          : 'No stations yet.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.p8),
                  itemBuilder: (_, i) => _StationRow(
                    station: filtered[i],
                    onEditPlan: () => _showEditPlanDialog(filtered[i]),
                    onSuspend: () => _setStatus(filtered[i],
                        StationPlanStatus.suspended),
                    onReactivate: () =>
                        _setStatus(filtered[i], StationPlanStatus.active),
                    onDelete: () => _deleteStation(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(_FilterType f) => switch (f) {
        _FilterType.all => 'All',
        _FilterType.active => 'Active',
        _FilterType.trialing => 'Trialing',
        _FilterType.suspended => 'Suspended',
        _FilterType.free => 'Free',
        _FilterType.starter => 'Starter',
        _FilterType.pro => 'Pro',
        _FilterType.enterprise => 'Enterprise',
      };

  Future<void> _setStatus(Station s, StationPlanStatus status) async {
    final label = status == StationPlanStatus.suspended ? 'suspend' : 'reactivate';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg3,
        title: Text('${label[0].toUpperCase()}${label.substring(1)} "${s.name}"?',
            style: AppTextStyles.h3),
        content: Text(
          status == StationPlanStatus.suspended
              ? 'The station will be suspended and lose access to the admin panel.'
              : 'The station will regain full access.',
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == StationPlanStatus.suspended
                  ? AppColors.errorRed
                  : AppColors.successGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(label[0].toUpperCase() + label.substring(1)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final isActive = status != StationPlanStatus.suspended;
    await FirebaseFirestore.instance.collection('stations').doc(s.stationId).update({
      'planStatus': _serializeStatus(status),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteStation(Station s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg3,
        title: Text('Delete "${s.name}"?', style: AppTextStyles.h3),
        content: Text(
          'This will soft-delete the station (isActive = false). Data is retained.',
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseFirestore.instance.collection('stations').doc(s.stationId).update({
      'isActive': false,
      'planStatus': 'suspended',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showEditPlanDialog(Station s) {
    showDialog(
      context: context,
      builder: (_) => _EditPlanDialog(station: s),
    );
  }

  static String _serializeStatus(StationPlanStatus status) => switch (status) {
        StationPlanStatus.trialing => 'trialing',
        StationPlanStatus.pastDue => 'past_due',
        StationPlanStatus.suspended => 'suspended',
        StationPlanStatus.active => 'active',
      };
}

// ── Station Row ──────────────────────────────────────────────────────────────

class _StationRow extends ConsumerWidget {
  final Station station;
  final VoidCallback onEditPlan;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;

  const _StationRow({
    required this.station,
    required this.onEditPlan,
    required this.onSuspend,
    required this.onReactivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuspended =
        station.planStatus == StationPlanStatus.suspended;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.p16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: AppColors.border1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: station.isActive
                  ? AppColors.successGreen
                  : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.name,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${station.slug} · ${station.frequency}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
                if (station.contactEmail.isNotEmpty)
                  Text(station.contactEmail,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.p12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PlanBadge(plan: station.plan),
              const SizedBox(height: 4),
              _StatusBadge(status: station.planStatus),
            ],
          ),
          const SizedBox(width: AppDimensions.p8),
          PopupMenuButton<String>(
            color: AppColors.bg3,
            icon: Icon(Icons.more_vert,
                color: AppColors.textMuted, size: 20),
            onSelected: (v) {
              if (v == 'view') {
                context.push('/platform/station/${station.stationId}');
              } else if (v == 'edit') {
                onEditPlan();
              } else if (v == 'suspend') {
                onSuspend();
              } else if (v == 'reactivate') {
                onReactivate();
              } else if (v == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new_rounded,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text('View', style: AppTextStyles.body),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text('Edit Plan', style: AppTextStyles.body),
                  ],
                ),
              ),
              PopupMenuDivider(),
              if (isSuspended)
                PopupMenuItem(
                  value: 'reactivate',
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_rounded,
                          size: 16, color: AppColors.successGreen),
                      const SizedBox(width: 8),
                      Text('Reactivate',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.successGreen)),
                    ],
                  ),
                )
              else
                PopupMenuItem(
                  value: 'suspend',
                  child: Row(
                    children: [
                      Icon(Icons.pause_circle_rounded,
                          size: 16, color: AppColors.warningGold),
                      const SizedBox(width: 8),
                      Text('Suspend',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.warningGold)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded,
                        size: 16, color: AppColors.errorRed),
                    const SizedBox(width: 8),
                    Text('Delete',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.errorRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Edit Plan Dialog ──────────────────────────────────────────────────────────

class _EditPlanDialog extends StatefulWidget {
  final Station station;
  const _EditPlanDialog({required this.station});

  @override
  State<_EditPlanDialog> createState() => _EditPlanDialogState();
}

class _EditPlanDialogState extends State<_EditPlanDialog> {
  late StationPlan _plan;
  late StationPlanStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.station.plan;
    _status = widget.station.planStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg3,
      title: Text('Edit Plan — ${widget.station.name}',
          style: AppTextStyles.h3),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            DropdownButtonFormField<StationPlan>(
              initialValue: _plan,
              dropdownColor: AppColors.bg4,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg4,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                  borderSide: const BorderSide(color: AppColors.border1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                  borderSide: const BorderSide(color: AppColors.border1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.p12, vertical: AppDimensions.p10),
              ),
              items: StationPlan.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(_planLabel(p), style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _plan = v!),
            ),
            const SizedBox(height: AppDimensions.p12),
            Text('Status', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            DropdownButtonFormField<StationPlanStatus>(
              initialValue: _status,
              dropdownColor: AppColors.bg4,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg4,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                  borderSide: const BorderSide(color: AppColors.border1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                  borderSide: const BorderSide(color: AppColors.border1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.p12, vertical: AppDimensions.p10),
              ),
              items: StationPlanStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_statusLabel(s), style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lionGold,
            foregroundColor: AppColors.bg0,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(widget.station.stationId)
          .update({
        'plan': _serializePlan(_plan),
        'planStatus': _serializeStatus(_status),
        'isActive': _status != StationPlanStatus.suspended,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _planLabel(StationPlan p) => switch (p) {
        StationPlan.free => 'Free',
        StationPlan.starter => 'Starter',
        StationPlan.pro => 'Pro',
        StationPlan.enterprise => 'Enterprise',
      };

  static String _statusLabel(StationPlanStatus s) => switch (s) {
        StationPlanStatus.active => 'Active',
        StationPlanStatus.trialing => 'Trialing',
        StationPlanStatus.pastDue => 'Past Due',
        StationPlanStatus.suspended => 'Suspended',
      };

  static String _serializePlan(StationPlan p) => switch (p) {
        StationPlan.free => 'free',
        StationPlan.starter => 'starter',
        StationPlan.pro => 'pro',
        StationPlan.enterprise => 'enterprise',
      };

  static String _serializeStatus(StationPlanStatus s) => switch (s) {
        StationPlanStatus.trialing => 'trialing',
        StationPlanStatus.pastDue => 'past_due',
        StationPlanStatus.suspended => 'suspended',
        StationPlanStatus.active => 'active',
      };
}

// ── Shared badges / chips ────────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  final StationPlan plan;
  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (plan) {
      StationPlan.enterprise => ('Enterprise', AppColors.lionGold),
      StationPlan.pro => ('Pro', AppColors.electricTeal),
      StationPlan.starter => ('Starter', AppColors.lionGreen),
      StationPlan.free => ('Free', AppColors.textMuted),
    };
    return _Badge(label: label, color: color);
  }
}

class _StatusBadge extends StatelessWidget {
  final StationPlanStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      StationPlanStatus.active => ('Active', AppColors.successGreen),
      StationPlanStatus.trialing => ('Trial', AppColors.warningGold),
      StationPlanStatus.pastDue => ('Past Due', AppColors.liveRed),
      StationPlanStatus.suspended => ('Suspended', AppColors.errorRed),
    };
    return _Badge(label: label, color: color);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color, fontSize: 10)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.lionGold : AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.rFull),
          border: Border.all(
              color: selected ? AppColors.lionGold : AppColors.border2),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.bg0 : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
