import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/careerly_identity.dart';
import '../../application/builder_controller.dart';
import '../../domain/resume_document.dart';

Future<void> showAiRewriteSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String original,
  required String sectionKey,
  required String locale,
  required void Function(String accepted) onAccept,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.lavender,
    builder: (_) => _AiRewriteSheet(
      original: original,
      sectionKey: sectionKey,
      locale: locale,
      onAccept: onAccept,
    ),
  );
}

class _AiRewriteSheet extends ConsumerStatefulWidget {
  const _AiRewriteSheet({
    required this.original,
    required this.sectionKey,
    required this.locale,
    required this.onAccept,
  });

  final String original;
  final String sectionKey;
  final String locale;
  final void Function(String accepted) onAccept;

  @override
  ConsumerState<_AiRewriteSheet> createState() => _AiRewriteSheetState();
}

class _AiRewriteSheetState extends ConsumerState<_AiRewriteSheet> {
  String _mode = 'improve';
  RewriteSuggestion? _suggestion;
  late final TextEditingController _edit;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _edit = TextEditingController(text: widget.original);
    _run();
  }

  @override
  void dispose() {
    _edit.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    final s = await ref
        .read(builderControllerProvider.notifier)
        .requestRewrite(
          mode: _mode,
          text: widget.original,
          locale: widget.locale,
          sectionKey: widget.sectionKey,
        );
    if (!mounted) return;
    setState(() {
      _suggestion = s;
      if (s != null) {
        _edit.text = s.suggested;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = _suggestion;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.page,
        right: AppSpacing.page,
        top: AppSpacing.sm,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '✦',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.inkNavy,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.builderAiImprove,
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _ModeChip(
                  label: l10n.builderAiModeImprove,
                  selected: _mode == 'improve',
                  onTap: () {
                    setState(() => _mode = 'improve');
                    _run();
                  },
                ),
                _ModeChip(
                  label: l10n.builderAiModeConcise,
                  selected: _mode == 'concise',
                  onTap: () {
                    setState(() => _mode = 'concise');
                    _run();
                  },
                ),
                _ModeChip(
                  label: l10n.builderAiModeProfessional,
                  selected: _mode == 'professional',
                  onTap: () {
                    setState(() => _mode = 'professional');
                    _run();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CareerlyProgressRow(height: 3),
              )
            else if (s != null) ...[
              CareerlySectionLabel(l10n.builderAiOriginal),
              const SizedBox(height: AppSpacing.xs),
              Text(
                s.original,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CareerlySectionLabel(l10n.builderAiSuggested),
              const SizedBox(height: AppSpacing.xs),
              CareerlyColorSection(
                tone: CareerlySurfaceTone.neutral,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppTextField(
                  controller: _edit,
                  label: l10n.builderAiSuggested,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (s.needsUserFact && s.missingFactPrompt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  s.missingFactPrompt!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              CareerlySectionLabel(l10n.labelWhyStronger),
              const SizedBox(height: AppSpacing.xs),
              Text(s.why, style: theme.textTheme.bodyMedium),
              if (s.needsUserFact) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.builderAiNeedsFact,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.builderAiAccept,
                onPressed:
                    s.needsUserFact && _edit.text.trim() == s.original.trim()
                        ? null
                        : () {
                            widget.onAccept(_edit.text.trim());
                            Navigator.pop(context);
                          },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: l10n.builderAiTryAgain,
                      variant: AppButtonVariant.secondary,
                      onPressed: _run,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: l10n.builderCancel,
                      variant: AppButtonVariant.ghost,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.inkNavy : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.inkNavy,
                  letterSpacing: 0.4,
                ),
          ),
        ),
      ),
    );
  }
}
