import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Wraps a deferred Dart library so dart2js only downloads that JS chunk
/// the first time this widget is mounted. Pass `myLib.loadLibrary` as
/// [loader] and a synchronous builder as [builder].
///
/// Usage in GoRouter pageBuilder:
/// ```dart
/// import '../../screens/admin/analytics_screen.dart' deferred as analyticsScreen;
///
/// GoRoute(
///   path: '/admin/analytics',
///   pageBuilder: (_, __) => NoTransitionPage(
///     child: DeferredWidget(
///       loader: analyticsScreen.loadLibrary,
///       builder: (_) => analyticsScreen.AnalyticsScreen(),
///     ),
///   ),
/// ),
/// ```
class DeferredWidget extends StatefulWidget {
  /// Pass `someLib.loadLibrary` — dart2js triggers the chunk download here.
  final Future<void> Function() loader;

  /// Called synchronously once [loader] resolves. Build your screen here.
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
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    // loadLibrary() is idempotent — safe to call multiple times;
    // subsequent calls resolve immediately from cache.
    _loadFuture = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
                  onPressed: () => setState(() {
                    _loadFuture = widget.loader();
                  }),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ??
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.lionGreen,
                  strokeWidth: 2,
                ),
              );
        }

        return widget.builder(context);
      },
    );
  }
}
