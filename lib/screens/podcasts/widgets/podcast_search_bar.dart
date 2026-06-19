import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/podcast_provider.dart';

class PodcastSearchBar extends ConsumerStatefulWidget {
  const PodcastSearchBar({super.key});

  @override
  ConsumerState<PodcastSearchBar> createState() => _PodcastSearchBarState();
}

class _PodcastSearchBarState extends ConsumerState<PodcastSearchBar> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).state = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.p16,
        AppDimensions.p12,
        AppDimensions.p16,
        AppDimensions.p8,
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: _onChanged,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search episodes…',
          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                  onPressed: () {
                    _ctrl.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
        ),
      ),
    );
  }
}
