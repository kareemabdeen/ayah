import 'package:flutter/material.dart';

import '../errors/failures.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Centered title + body. Used for supportive moments ("That's okay"),
/// completion ("Masha'Allah") and empty states.
class SupportiveMessage extends StatelessWidget {
  const SupportiveMessage({super.key, required this.title, this.body, this.icon, this.extra});

  final String title;
  final String? body;
  final IconData? icon;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.xxl, color: context.colors.primary),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(title, textAlign: TextAlign.center, style: context.text.headlineMedium),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: context.text.titleMedium?.copyWith(color: context.ayahColors.inkMuted, height: 1.6),
            ),
          ],
          if (extra != null) ...[const SizedBox(height: AppSpacing.lg), extra!],
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

/// Friendly error with retry. Never shows raw error text.
class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isOffline = failure is NetworkFailure;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SupportiveMessage(
          icon: isOffline ? Icons.wifi_off_rounded : Icons.refresh_rounded,
          title: isOffline ? s.offlineFirstTime : s.genericProblem,
          extra: OutlinedButton(onPressed: onRetry, child: Text(s.retry)),
        ),
      ),
    );
  }
}
