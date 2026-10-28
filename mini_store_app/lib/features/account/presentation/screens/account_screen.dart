import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

/// Profile tab driven entirely by the persisted session.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will need to sign in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('account-logout-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    await context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final session = state is AuthAuthenticated ? state.session : null;

        return AppScaffold(
          appBar: const AppAppBar(title: 'Account', subtitle: 'Your profile'),
          body: session == null
              ? const Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: AppEmptyView(
                      title: 'No account signed in',
                      message: 'Sign in to see your profile details.',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileCard(user: session.user),
                            const SizedBox(height: AppSpacing.lg),
                            _DetailsCard(user: session.user),
                            const SizedBox(height: AppSpacing.lg),
                            OutlinedButton.icon(
                              key: const ValueKey('account-logout'),
                              onPressed: () => _confirmLogout(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Sign out'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            _ProfileAvatar(imageUrl: user.image),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: AppTypography.headlineSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '@${user.username}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    return ClipOval(
      child: Container(
        width: 88,
        height: 88,
        color: AppColors.imageBackground,
        child: url.isEmpty
            ? const _AvatarPlaceholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const _AvatarPlaceholder();
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.person_rounded,
      size: 44,
      color: AppColors.textSecondary,
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.alternate_email_rounded,
            label: 'Username',
            value: user.username,
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: _valueOrFallback(user.email),
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.wc_rounded,
            label: 'Gender',
            value: _capitalize(_valueOrFallback(user.gender)),
          ),
        ],
      ),
    );
  }

  static String _valueOrFallback(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Not provided' : trimmed;
  }

  static String _capitalize(String value) {
    if (value.isEmpty || value == 'Not provided') {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxs,
      ),
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(value, style: AppTypography.bodyMedium),
    );
  }
}
