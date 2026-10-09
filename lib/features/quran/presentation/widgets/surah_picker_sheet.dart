import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/surah.dart';

/// Bottom sheet listing surahs; returns the chosen surah id.
Future<int?> showSurahPicker(BuildContext context, {required List<Surah> surahs, int? selectedId}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) {
        final s = context.s;
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(s.chooseSurahTitle, style: context.text.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: surahs.length,
                itemBuilder: (context, i) {
                  final surah = surahs[i];
                  final selected = surah.id == selectedId;
                  return ListTile(
                    selected: selected,
                    minTileHeight: AppSpacing.minTouchTarget + AppSpacing.xs,
                    leading: CircleAvatar(
                      radius: AppSpacing.md,
                      backgroundColor: context.ayahColors.surfaceMuted,
                      child: Text('${surah.id}', style: context.text.labelMedium),
                    ),
                    title: Text(isArabic ? surah.nameArabic : surah.nameTransliterated),
                    subtitle: Text(s.ayahs(surah.ayahCount)),
                    trailing: selected ? const Icon(Icons.check_rounded) : null,
                    onTap: () => Navigator.of(context).pop(surah.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}
