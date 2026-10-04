import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/motion/careerly_motion.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../optimization/data/cv_version_store.dart';
import '../../optimization/domain/cv_version.dart';
import '../application/applications_controller.dart';
import '../domain/job_application.dart';

String applicationStatusLabel(AppLocalizations l10n, ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.saved => l10n.appsStatusSaved,
    ApplicationStatus.preparing => l10n.appsStatusPreparing,
    ApplicationStatus.applied => l10n.appsStatusApplied,
    ApplicationStatus.interview => l10n.appsStatusInterview,
    ApplicationStatus.offer => l10n.appsStatusOffer,
    ApplicationStatus.rejected => l10n.appsStatusRejected,
  };
}

class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  ApplicationStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final all = ref.watch(applicationsControllerProvider);
    final items = _filter == null
        ? all
        : all.where((a) => a.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showApplicationSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.appsAdd),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.hero + AppSpacing.xl,
        ),
        children: [
          Text(l10n.appsIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.appsAll,
                  count: all.length,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final status in ApplicationStatus.values)
                  _FilterChip(
                    label: applicationStatusLabel(l10n, status),
                    count: all.where((a) => a.status == status).length,
                    selected: _filter == status,
                    onTap: () => setState(() => _filter = status),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (items.isEmpty)
            Text(l10n.appsEmpty, style: theme.textTheme.bodyLarge)
          else
            for (final item in items) ...[
              _ApplicationCard(
                application: item,
                onTap: () => showApplicationSheet(context, ref, existing: item),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(count == 0 ? label : '$label · $count'),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.application, required this.onTap});

  final JobApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = application;
    final locale = Localizations.localeOf(context).languageCode;
    final version = ref.read(cvVersionStoreProvider).byId(a.cvVersionId);
    final meta = [
      if (a.company != null) a.company!,
      if (a.matchScore != null) l10n.appsMatch(a.matchScore!),
      if (a.appliedAt != null)
        l10n.appsAppliedOn(DateFormat.yMMMd(locale).format(a.appliedAt!)),
    ];
    return CareerlyPressable(
      child: CareerlyColorSection(
        tone: CareerlySurfaceTone.neutral,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(a.jobTitle, style: theme.textTheme.titleMedium),
                ),
                const SizedBox(width: AppSpacing.xs),
                _StatusPill(status: a.status),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(meta.join(' · '), style: theme.textTheme.bodySmall),
            ],
            if (version != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${l10n.appsFieldCv}: ${version.label}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (a.nextAction.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '→ ${a.nextAction}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkNavy,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (bg, fg) = switch (status) {
      ApplicationStatus.saved => (AppColors.background, AppColors.secondaryText),
      ApplicationStatus.preparing => (AppColors.cream, AppColors.inkNavy),
      ApplicationStatus.applied => (AppColors.iceBlue, AppColors.cobalt),
      ApplicationStatus.interview => (AppColors.lavender, AppColors.inkNavy),
      ApplicationStatus.offer => (
        AppColors.mint.withValues(alpha: 0.3),
        AppColors.inkNavy,
      ),
      ApplicationStatus.rejected => (AppColors.softCoral, AppColors.inkNavy),
    };
    return AnimatedContainer(
      duration: AppMotion.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        applicationStatusLabel(l10n, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

/// Add or edit an application. Prefills come from a real job match only.
Future<void> showApplicationSheet(
  BuildContext context,
  WidgetRef ref, {
  JobApplication? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ApplicationSheet(existing: existing),
  );
}

class _ApplicationSheet extends ConsumerStatefulWidget {
  const _ApplicationSheet({this.existing});

  final JobApplication? existing;

  @override
  ConsumerState<_ApplicationSheet> createState() => _ApplicationSheetState();
}

class _ApplicationSheetState extends ConsumerState<_ApplicationSheet> {
  late final _role = TextEditingController(text: widget.existing?.jobTitle);
  late final _company = TextEditingController(text: widget.existing?.company);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late final _next = TextEditingController(text: widget.existing?.nextAction);
  late ApplicationStatus _status =
      widget.existing?.status ?? ApplicationStatus.saved;
  late String? _versionId = widget.existing?.cvVersionId;

  @override
  void dispose() {
    _role.dispose();
    _company.dispose();
    _notes.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_role.text.trim().isEmpty) return;
    final ctrl = ref.read(applicationsControllerProvider.notifier);
    final existing = widget.existing;
    if (existing == null) {
      final created = await ctrl.create(
        jobTitle: _role.text,
        company: _company.text,
        cvVersionId: _versionId,
        status: _status,
      );
      await ctrl.update(
        created.copyWith(notes: _notes.text.trim(), nextAction: _next.text.trim()),
      );
    } else {
      await ctrl.update(
        existing.copyWith(
          jobTitle: _role.text.trim(),
          company: _company.text.trim(),
          status: _status,
          cvVersionId: _versionId,
          clearCvVersion: _versionId == null,
          notes: _notes.text.trim(),
          nextAction: _next.text.trim(),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final versions = ref.read(cvVersionStoreProvider).read().reversed.toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _role,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.appsFieldRole),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.appsFieldCompany),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<ApplicationStatus>(
              initialValue: _status,
              decoration: InputDecoration(labelText: l10n.appsFieldStatus),
              items: [
                for (final status in ApplicationStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(applicationStatusLabel(l10n, status)),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String?>(
              initialValue: versions.any((v) => v.id == _versionId)
                  ? _versionId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.appsFieldCv),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.appsFieldCvCurrent),
                ),
                for (final version in versions)
                  DropdownMenuItem<String?>(
                    value: version.id,
                    child: Text(
                      '${version.type == CvVersionType.original ? l10n.optimizeVersionOriginal : l10n.optimizeVersionOptimized} · ${version.label}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _versionId = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _next,
              decoration: InputDecoration(labelText: l10n.appsFieldNext),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: l10n.appsFieldNotes),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: l10n.appsSave, onPressed: _save),
            if (widget.existing != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: l10n.appsDelete,
                variant: AppButtonVariant.destructive,
                onPressed: () async {
                  await ref
                      .read(applicationsControllerProvider.notifier)
                      .delete(widget.existing!.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
