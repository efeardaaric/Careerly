/// Mock authentication — Phase 1 only. Replace with real auth repository later.
/// Do not treat this as production security.
library;

import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/session/session_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/careerly_identity.dart';
import '../../home/presentation/home_shell.dart';
import '../domain/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signUpMode = true;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        createAccount: _signUpMode,
      );
      await ref
          .read(sessionProvider.notifier)
          .signInMock(
            email: result.email,
            displayName: result.displayName,
            accessToken: result.accessToken,
          );
      if (!mounted) return;
      context.go(AppRoutes.personalization);
    } catch (_) {
      setState(() => _error = l10n.authGenericError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _social(String provider) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithProvider(provider);
      await ref
          .read(sessionProvider.notifier)
          .signInMock(
            email: result.email,
            displayName: result.displayName,
            accessToken: result.accessToken,
          );
      if (!mounted) return;
      context.go(AppRoutes.personalization);
    } catch (_) {
      final l10n = AppLocalizations.of(context);
      setState(() => _error = l10n.authGenericError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return CareerlyScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CareerlyEditorialHeader(
                  label: l10n.appName.toUpperCase(),
                  headline: l10n.authWelcomeTitle,
                  supporting: l10n.authWelcomeSubtitle,
                  background: AppColors.iceBlue,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.lg,
                    AppSpacing.page,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                CareerlyColorSection(
                  tone: CareerlySurfaceTone.cream,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const CareerlyStatusMarker(
                        color: AppColors.coral,
                        shape: CareerlyMarkerShape.diamond,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          l10n.authMockBanner,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.navyMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.authContinueWithGoogle,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.account_circle_outlined,
                  onPressed: _loading ? null : () => _social('google'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.authContinueWithApple,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.apple,
                  onPressed: _loading ? null : () => _social('apple'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Expanded(child: CareerlyHairline()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        l10n.authOrEmail,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: CareerlyHairline()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _emailController,
                  label: l10n.authEmailLabel,
                  hint: l10n.authEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
                    return ok ? null : l10n.authEmailRequired;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _passwordController,
                  label: l10n.authPasswordLabel,
                  hint: l10n.authPasswordHint,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submitEmail(),
                  validator: (value) {
                    final v = value ?? '';
                    return v.length >= 8 ? null : l10n.authPasswordRequired;
                  },
                  suffix: IconButton(
                    tooltip: _obscure
                        ? l10n.authShowPassword
                        : l10n.authHidePassword,
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.critical,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: _signUpMode ? l10n.authSignUp : l10n.authSignIn,
                  onPressed: _submitEmail,
                  isLoading: _loading,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: _signUpMode
                      ? l10n.authSwitchToSignIn
                      : l10n.authSwitchToSignUp,
                  variant: AppButtonVariant.ghost,
                  onPressed: _loading
                      ? null
                      : () => setState(() => _signUpMode = !_signUpMode),
                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
