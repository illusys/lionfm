import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Wraps a deferred Dart library so dart2js only downloads that JS chunk
/// the first time this widget is mounted. Pass `() => myLib.loadLibrary()`
/// as [loader] (always use a lambda, never a tear-off — DDC requires the
/// direct call-site to correctly mark the library as loaded) and a
/// synchronous builder as [builder].
///
/// Usage in GoRouter pageBuilder:
/// ```dart
/// import '../../screens/admin/analytics_screen.dart' deferred as analyticsScreen;
///
/// GoRoute(
///   path: '/admin/analytics',
///   pageBuilder: (_, __) => NoTransitionPage(
///     child: DeferredWidget(
///       loader: () => analyticsScreen.loadLibrary(),
///       builder: (_) => analyticsScreen.AnalyticsScreen(),
///     ),
///   ),
/// ),
/// ```
class DeferredWidget extends StatefulWidget {
  /// Pass `() => someLib.loadLibrary()` — dart2js triggers the chunk download.
  /// Always use a lambda, never a tear-off (`someLib.loadLibrary` without `()`).
  final Future<void> Function() loader;

  /// Called once [loader] resolves. Build your screen here.
  final WidgetBuilder builder;

  /// Shown while the chunk is in flight. Defaults to a centred green spinner.
  final Widget? placeholder;

  const DeferredWidget({
    super.key,
    required this.loader,
    required this.builder,
    this.placeholder,
  });

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  bool _loaded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    widget.loader().then(
      (_) {
        if (mounted) setState(() { _loaded = true; _error = null; });
      },
      onError: (Object e, StackTrace _) {
        if (mounted) setState(() => _error = e);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.errorRed, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Failed to load. Check your connection.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() { _error = null; _loaded = false; });
                _load();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_loaded) {
      return widget.placeholder ??
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.lionGreen,
              strokeWidth: 2,
            ),
          );
    }

    return widget.builder(context);
  }
}
