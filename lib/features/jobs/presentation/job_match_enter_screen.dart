import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../billing/domain/billing_models.dart';
import '../../billing/presentation/billing_gate.dart';
import '../../billing/presentation/paywall_screen.dart';
import '../../billing/presentation/soft_upgrade_banner.dart';
import '../../billing/application/billing_controller.dart';
import '../application/job_match_controller.dart';

class JobMatchEnterScreen extends ConsumerStatefulWidget {
  const JobMatchEnterScreen({super.key});

  @override
  ConsumerState<JobMatchEnterScreen> createState() =>
      _JobMatchEnterScreenState();
}

class _JobMatchEnterScreenState extends ConsumerState<JobMatchEnterScreen> {
  late final TextEditingController _title;
  late final TextEditingController _company;
  late final TextEditingController _url;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    final s = ref.read(jobMatchControllerProvider);
    _title = TextEditingController(text: s.jobTitle);
    _company = TextEditingController(text: s.company);
    _url = TextEditingController(text: s.jobUrl);
    _description = TextEditingController(text: s.jobDescription);
  }

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _url.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(jobMatchControllerProvider);
    final tooShort =
        state.jobDescription.trim().length < 20 &&
        state.jobDescription.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jobsJobInfoTitle),
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(l10n.jobsJobInfoSubtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _title,
              label: l10n.jobsJobTitleLabel,
              hint: l10n.jobsJobTitleHint,
              onChanged: (v) => ref
                  .read(jobMatchControllerProvider.notifier)
                  .updateJobTitle(v),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _company,
              label: l10n.jobsCompanyLabel,
              hint: l10n.jobsCompanyHint,
              onChanged: (v) => ref
                  .read(jobMatchControllerProvider.notifier)
                  .updateCompany(v),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _url,
              label: l10n.jobsUrlLabel,
              hint: l10n.jobsUrlHint,
              keyboardType: TextInputType.url,
              onChanged: (v) =>
                  ref.read(jobMatchControllerProvider.notifier).updateJobUrl(v),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _description,
              label: l10n.jobsDescriptionLabel,
              hint: l10n.jobsDescriptionHint,
              maxLines: 10,
              onChanged: (v) => ref
                  .read(jobMatchControllerProvider.notifier)
                  .updateJobDescription(v),
            ),
            if (tooShort ||
                state.failureMessage == 'job_description_too_short') ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.jobsDescriptionTooShort,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.critical,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SoftUpgradeBanner(
              decision: ref
                  .watch(billingControllerProvider)
                  .decision(FeatureId.jobMatch),
              onUpgrade: () =>
                  showPaywall(context, contextKey: 'job_match_soft'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.jobsAnalyzeCta,
              isLoading: state.isBusy,
              onPressed: state.jobDescription.trim().length < 20
                  ? null
                  : () async {
                      final ok = await ensureFeatureAccess(
                        context,
                        ref,
                        FeatureId.jobMatch,
                        paywallContext: 'job_match_start',
                      );
                      if (!ok || !context.mounted) return;
                      ref.read(jobMatchControllerProvider.notifier).runMatch();
                      context.push(AppRoutes.jobsProcessing);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
