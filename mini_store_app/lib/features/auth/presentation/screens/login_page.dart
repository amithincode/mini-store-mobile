import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_brand_mark.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Stateless sign-in screen. All field values, errors, and visibility come
/// from [AuthCubit].
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _submit(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AuthCubit>().submit();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        final form = state.form;
        final isSubmitting = state is AuthSubmitting;
        final message = switch (state) {
          AuthLoginFailure(:final message) => message,
          AuthSignedOut(:final message) => message,
          _ => null,
        };

        return AppScaffold(
          bodyAlignment: Alignment.center,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LoginHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome back',
                                style: AppTypography.headlineSmall,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Sign in to continue to your store.',
                                style: AppTypography.bodySmall,
                              ),
                              if (message != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                _AuthErrorBanner(message: message),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                key: const ValueKey('login-username'),
                                initialValue: form.username,
                                enabled: !isSubmitting,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  errorText: form.usernameError,
                                ),
                                onChanged: cubit.usernameChanged,
                                onTapOutside: (_) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                key: const ValueKey('login-password'),
                                initialValue: form.password,
                                enabled: !isSubmitting,
                                obscureText: form.obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  errorText: form.passwordError,
                                  suffixIcon: IconButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : cubit.togglePasswordVisibility,
                                    tooltip: form.obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    icon: Icon(
                                      form.obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                onChanged: cubit.passwordChanged,
                                onFieldSubmitted: (_) => _submit(context),
                                onTapOutside: (_) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              FilledButton(
                                key: const ValueKey('login-submit'),
                                onPressed: isSubmitting
                                    ? null
                                    : () => _submit(context),
                                child: isSubmitting
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: AppSpacing.sm),
                                          Text('Signing in…'),
                                        ],
                                      )
                                    : const Text('Sign in'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Use your Mini Store account to continue.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppBrandMark(size: 48),
        const SizedBox(width: AppSpacing.sm),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: AppTypography.titleLarge.copyWith(fontSize: 21),
            ),
            Text(
              AppConstants.appTagline,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
