import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/analytics/billing_analytics.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../application/billing_controller.dart';
import '../domain/billing_models.dart';
import '../domain/plan_limits_config.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.contextKey = 'generic'});

  final String contextKey;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selected = PlanLimitsConfig.yearlyProductId;

  @override
  void initState() {
    super.initState();
    BillingAnalytics.paywallViewed(context: widget.contextKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingControllerProvider.notifier).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final billing = ref.watch(billingControllerProvider);
    final products = billing.products.isEmpty
        ? const [
            StoreProduct(
              productId: PlanLimitsConfig.monthlyProductId,
              title: 'Pro Monthly',
              priceLabel: '—',
              period: 'monthly',
            ),
            StoreProduct(
              productId: PlanLimitsConfig.yearlyProductId,
              title: 'Pro Yearly',
              priceLabel: '—',
              period: 'yearly',
            ),
          ]
        : billing.products;

    final busy =
        billing.purchasePhase == PurchasePhase.purchasing ||
        billing.purchasePhase == PurchasePhase.verifying ||
        billing.purchasePhase == PurchasePhase.loadingProducts;

    return Scaffold(
      backgroundColor: AppColors.inkNavy,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy,
        foregroundColor: Colors.white,
        title: Text(
          l10n.paywallTitle,
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          tooltip: l10n.close,
          onPressed: () {
            BillingAnalytics.paywallClosed(context: widget.contextKey);
            context.pop();
          },
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            CareerlySectionLabel('CAREERLY PRO', light: true),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.paywallHeadline,
              style: theme.textTheme.displayMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.paywallBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            CareerlyColorSection(
              tone: CareerlySurfaceTone.cream,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ValueRow(text: l10n.paywallValue1),
                  _ValueRow(text: l10n.paywallValue2),
                  _ValueRow(text: l10n.paywallValue3),
                  _ValueRow(text: l10n.paywallValue4, last: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            CareerlySectionLabel(l10n.paywallChoosePlan, light: true),
            const SizedBox(height: AppSpacing.md),
            ...products.map((p) {
              final selected = _selected == p.productId;
              final planLabel = p.period == 'yearly'
                  ? l10n.paywallYearly
                  : l10n.paywallMonthly;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: selected
                      ? AppColors.cobalt
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    onTap: () => setState(() => _selected = p.productId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                              color: selected
                                  ? AppColors.coral
                                  : Colors.transparent,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              planLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            p.priceLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.paywallPriceNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.paywallCta,
              isLoading: busy,
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await ref
                          .read(billingControllerProvider.notifier)
                          .purchase(_selected);
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.paywallSuccess)),
                        );
                        context.pop(true);
                      }
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await ref
                          .read(billingControllerProvider.notifier)
                          .restore();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? l10n.paywallRestoreSuccess
                                  : l10n.paywallRestoreEmpty,
                            ),
                          ),
                        );
                        if (ok) context.pop(true);
                      }
                    },
              child: Text(
                l10n.paywallRestore,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.paywallLegal,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.left,
            ),
            if (billing.lastError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.paywallError,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.coral,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.text, this.last = false});

  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CareerlyStatusMarker(
            color: AppColors.cobalt,
            shape: CareerlyMarkerShape.diamond,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showPaywall(
  BuildContext context, {
  String contextKey = 'generic',
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PaywallScreen(contextKey: contextKey),
    ),
  );
}
