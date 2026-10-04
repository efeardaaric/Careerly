import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/session/session_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/careerly_identity.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool existingAccount}) async {
    await ref.read(sessionProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.auth);
  }

  void _next() {
    if (_index >= 2) {
      _finish(existingAccount: false);
      return;
    }
    _pageController.nextPage(
      duration: AppMotion.normal,
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_index == 0) return;
    _pageController.previousPage(
      duration: AppMotion.fast,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pages = [
      _OnboardingPageData(
        number: '01',
        kicker: l10n.onboardingKicker1.toUpperCase(),
        headline: l10n.onboardingHeadline1,
        body: l10n.onboardingBody1,
        tone: CareerlySurfaceTone.ice,
        graphic: _KnowGraphic(),
      ),
      _OnboardingPageData(
        number: '02',
        kicker: l10n.onboardingKicker2.toUpperCase(),
        headline: l10n.onboardingHeadline2,
        body: l10n.onboardingBody2,
        tone: CareerlySurfaceTone.cream,
        graphic: _MatchGraphic(),
      ),
      _OnboardingPageData(
        number: '03',
        kicker: l10n.onboardingKicker3.toUpperCase(),
        headline: l10n.onboardingHeadline3,
        body: l10n.onboardingBody3,
        tone: CareerlySurfaceTone.mint,
        graphic: _BuildGraphic(),
      ),
    ];
    final isLast = _index == pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  if (_index > 0)
                    IconButton(
                      tooltip: l10n.back,
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: AppSizes.minTouch),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _finish(existingAccount: false),
                    child: Text(l10n.skip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, i) {
                  final p = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          p.number,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 48,
                            color: AppColors.cobalt,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        CareerlySectionLabel(p.kicker, color: AppColors.inkNavy),
                        const SizedBox(height: AppSpacing.sm),
                        Text(p.headline, style: theme.textTheme.displayMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(p.body, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.xl),
                        Expanded(
                          child: CareerlyColorSection(
                            tone: p.tone,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Center(child: p.graphic),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Row(
                    children: List.generate(pages.length, (i) {
                      final active = i == _index;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          height: 3,
                          margin: EdgeInsets.only(
                            right: i < pages.length - 1 ? AppSpacing.xs : 0,
                          ),
                          color: active ? AppColors.cobalt : AppColors.border,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: isLast ? l10n.getStarted : l10n.next,
                    onPressed: _next,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    label: l10n.alreadyHaveAccount,
                    variant: AppButtonVariant.ghost,
                    onPressed: () => _finish(existingAccount: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.number,
    required this.kicker,
    required this.headline,
    required this.body,
    required this.tone,
    required this.graphic,
  });

  final String number;
  final String kicker;
  final String headline;
  final String body;
  final CareerlySurfaceTone tone;
  final Widget graphic;
}

/// Abstract document with highlighted structure blocks.
class _KnowGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inkNavy.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 6, width: 48, color: AppColors.cobalt),
              const SizedBox(height: 12),
              Container(height: 18, color: AppColors.iceBlue),
              const SizedBox(height: 8),
              Container(height: 18, color: AppColors.softCoral),
              const SizedBox(height: 8),
              Container(height: 18, color: AppColors.lavender),
              const Spacer(),
              for (var i = 0; i < 3; i++) ...[
                Container(
                  height: 3,
                  width: double.infinity,
                  color: AppColors.inkNavy.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Two document structures connected by thin alignment lines.
class _MatchGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget doc({required Color accent}) => Container(
          width: 88,
          height: 120,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inkNavy.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 4, width: 36, color: accent),
              const SizedBox(height: 10),
              for (var i = 0; i < 4; i++) ...[
                Container(
                  height: 3,
                  width: i.isEven ? 54 : 40,
                  color: AppColors.inkNavy.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        doc(accent: AppColors.cobalt),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (i) => Container(
                width: 28,
                height: 1.5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: i == 1 || i == 2
                    ? AppColors.cobalt
                    : AppColors.border,
              ),
            ),
          ),
        ),
        doc(accent: AppColors.coral),
      ],
    );
  }
}

/// Document assembling into a clean page.
class _BuildGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(-28, 12),
          child: Container(
            width: 100,
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.inkNavy.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
        Container(
          width: 110,
          height: 146,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inkNavy.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 5, width: 44, color: AppColors.mint),
              const SizedBox(height: 14),
              for (var i = 0; i < 5; i++) ...[
                Container(
                  height: 3,
                  width: i == 4 ? 40 : 70,
                  color: AppColors.inkNavy.withValues(alpha: 0.14),
                ),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              Row(
                children: [
                  const CareerlyStatusMarker(
                    color: AppColors.mint,
                    shape: CareerlyMarkerShape.circle,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 3,
                    width: 36,
                    color: AppColors.mint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
