import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/show_model.dart';
import 'show_detail_sheet.dart';

class ShowListTile extends StatefulWidget {
  final ShowModel show;
  final bool isLast;
  final int index;

  const ShowListTile({
    super.key,
    required this.show,
    this.isLast = false,
    this.index = 0,
  });

  @override
  State<ShowListTile> createState() => _ShowListTileState();
}

class _ShowListTileState extends State<ShowListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 50),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = widget.show.getStatus(now);
    final isLive = status == ShowStatus.live;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: () => ShowDetailSheet.present(context, widget.show),
          child: Container(
            margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.p16, vertical: 2),
            decoration: BoxDecoration(
              color: isLive
                  ? AppColors.liveRed.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.r10),
              border: Border(
                left: BorderSide(
                  color: switch (status) {
                    ShowStatus.live => AppColors.liveRed,
                    ShowStatus.upcoming => AppColors.lionGreen,
                    ShowStatus.done => AppColors.bg4,
                  },
                  width: 2,
                ),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Time column
                  SizedBox(
                    width: AppDimensions.scheduleTimeCol,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      child: Text(
                        _formatTime(widget.show.startTime),
                        style: AppTextStyles.mono
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                  // Dot + line
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _StatusDot(status: status),
                        if (!widget.isLast)
                          Expanded(
                            child: Container(
                              width: 1,
                              color: AppColors.border1,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Show info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.show.title,
                                    style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 2),
                                Text(widget.show.hostName,
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          _ShowStatusBadge(status: status),
                        ],
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

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m\n$p';
  }
}

class _StatusDot extends StatefulWidget {
  final ShowStatus status;
  const _StatusDot({required this.status});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
    if (widget.status == ShowStatus.live) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.status == ShowStatus.live
        ? AppColors.liveRed
        : widget.status == ShowStatus.upcoming
            ? AppColors.border2
            : AppColors.border1;

    if (widget.status == ShowStatus.live) {
      return AnimatedBuilder(
        animation: _opacity,
        builder: (_, __) => Opacity(
          opacity: _opacity.value,
          child: _dot(color),
        ),
      );
    }
    return _dot(color);
  }

  Widget _dot(Color color) => Container(
        width: AppDimensions.scheduleDotSize,
        height: AppDimensions.scheduleDotSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _ShowStatusBadge extends StatelessWidget {
  final ShowStatus status;
  const _ShowStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      ShowStatus.live => (
          'LIVE',
          AppColors.liveRed.withValues(alpha: 0.2),
          AppColors.liveRed
        ),
      ShowStatus.upcoming => (
          'NEXT',
          AppColors.surface3,
          AppColors.textSecondary
        ),
      ShowStatus.done => ('DONE', AppColors.surface3, AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.rFull),
      ),
      child: Text(label,
          style: AppTextStyles.badgeText.copyWith(
            color: textColor,
            fontSize: 10,
          )),
    );
  }
}
