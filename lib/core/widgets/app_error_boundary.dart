import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/glow_card.dart';

/// Error boundary widget that catches build and rendering exceptions in its subtree,
/// preventing full-app crashes and displaying an in-theme ChemBuddy recovery interface.
class AppErrorBoundary extends StatefulWidget {
  const AppErrorBoundary({
    super.key,
    required this.child,
    this.screenName,
    this.onRetry,
  });

  final Widget child;
  final String? screenName;
  final VoidCallback? onRetry;

  /// Global builder for [ErrorWidget.builder] to replace Flutter's default
  /// red/grey crash screen with a friendly ChemBuddy branded error card.
  static Widget errorWidgetBuilder(FlutterErrorDetails details) {
    return _ErrorFallbackCard(
      title: 'Render Hiccup Encountered',
      message: 'A visual element could not be displayed properly. Your session and data are safe.',
      details: kDebugMode ? details.exceptionAsString() : null,
    );
  }

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void didUpdateWidget(AppErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error if child changes
    if (widget.child != oldWidget.child && _error != null) {
      setState(() {
        _error = null;
        _stackTrace = null;
      });
    }
  }

  void _reset() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorFallbackCard(
        title: widget.screenName != null ? 'Unable to load ${widget.screenName}' : 'Something went wrong',
        message: 'An unexpected issue occurred while displaying this section. Your progress and study notes are safe.',
        details: kDebugMode ? '$_error\n$_stackTrace' : null,
        onRetry: _reset,
        canPop: Navigator.of(context).canPop(),
        onBack: () => Navigator.of(context).pop(),
      );
    }

    return widget.child;
  }
}

class _ErrorFallbackCard extends StatefulWidget {
  const _ErrorFallbackCard({
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
    this.canPop = false,
    this.onBack,
  });

  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final bool canPop;
  final VoidCallback? onBack;

  @override
  State<_ErrorFallbackCard> createState() => _ErrorFallbackCardState();
}

class _ErrorFallbackCardState extends State<_ErrorFallbackCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GlowCard(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    size: 36,
                    color: AppColors.brandBright,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (widget.details != null && widget.details!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _showDetails = !_showDetails),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showDetails ? 'Hide technical details' : 'Show details',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        Icon(
                          _showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  if (_showDetails) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.details!,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.canPop && widget.onBack != null) ...[
                      OutlinedButton.icon(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Go Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (widget.onRetry != null)
                      ElevatedButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
