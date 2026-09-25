import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/analysis_models.dart';

class SelectedCvCard extends StatelessWidget {
  const SelectedCvCard({
    super.key,
    required this.file,
    required this.onChange,
    required this.onRemove,
  });

  final SelectedCvFile file;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sizeLabel = file.sizeBytes >= 1024 * 1024
        ? '${file.sizeMb.toStringAsFixed(1)} MB'
        : '${(file.sizeBytes / 1024).toStringAsFixed(0)} KB';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.minTouch,
                height: AppSizes.minTouch,
                decoration: BoxDecoration(
                  color: AppColors.actionBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Icon(
                  file.extension == 'pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  color: AppColors.actionBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${file.typeLabel} · $sizeLabel',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.analyzeChangeFile,
                  variant: AppButtonVariant.secondary,
                  onPressed: onChange,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: l10n.analyzeRemoveFile,
                  variant: AppButtonVariant.ghost,
                  onPressed: onRemove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
