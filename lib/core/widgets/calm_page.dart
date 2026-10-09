import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Standard screen frame: safe area, readable max width, scrollable body,
/// and a pinned bottom area for the screen's single primary action.
class CalmPage extends StatelessWidget {
  const CalmPage({
    super.key,
    required this.body,
    this.bottom,
    this.appBar,
    this.centerBody = false,
  });

  final Widget body;
  final Widget? bottom;
  final PreferredSizeWidget? appBar;
  final bool centerBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - AppSpacing.md * 2).clamp(0.0, double.infinity),
                        ),
                        child: centerBody ? Center(child: body) : body,
                      ),
                    ),
                  ),
                ),
                if (bottom != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
                    child: bottom,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
