import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/info_widgets.dart';
import '../../core/data/offline_cache_store.dart';
import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/theme_providers.dart';

/// App settings: appearance (light / dark / system), the signed-in account,
/// and data-source information.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = context.responsive(mobile: 16.0, desktop: 28.0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PREFERENCES', style: AppTextStyles.overline),
              const SizedBox(height: 4),
              Text('Settings', style: AppTextStyles.displayLarge),
              const SizedBox(height: 24),
              const _AppearanceCard(),
              const SizedBox(height: 16),
              const _AccountCard(),
              const SizedBox(height: 16),
              const _OfflineCard(),
              const SizedBox(height: 16),
              const _AboutCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Appearance'),
          Text(
            'Choose how F1 Vision looks. System follows your device setting.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_rounded, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_rounded, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.settings_suggest_rounded, size: 16),
              ),
            ],
            selected: {theme.mode},
            onSelectionChanged: (selection) => ref
                .read(themeControllerProvider.notifier)
                .setMode(selection.first),
            style: ButtonStyle(
              side: WidgetStatePropertyAll(
                BorderSide(color: AppColors.surfaceStroke),
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.accent.withValues(alpha: 0.16)
                    : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Account'),
          if (!firebaseReady)
            Text(
              'Sign-in is not configured in this build. Add your Firebase '
              'project (see docs/FIREBASE_SETUP.md in the repository) to '
              'enable e-mail and Google authentication.',
              style: AppTextStyles.body,
            )
          else
            const _AccountBody(),
        ],
      ),
    );
  }
}

class _AccountBody extends ConsumerWidget {
  const _AccountBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).valueOrNull;

    if (user == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You are browsing as a guest.', style: AppTextStyles.body),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: () =>
                ref.read(guestModeProvider.notifier).state = false,
            child: const Text('Sign in / Create account'),
          ),
        ],
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          foregroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: Text(user.initials,
              style:
                  AppTextStyles.titleSmall.copyWith(color: AppColors.accentSoft)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName.isNotEmpty ? user.displayName : 'F1 fan',
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(user.email, style: AppTextStyles.label),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authRepositoryProvider).signOut();
            ref.read(guestModeProvider.notifier).state = false;
          },
          icon: const Icon(Icons.logout_rounded, size: 16),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.negative,
            side: BorderSide(
                color: AppColors.negative.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }
}

/// Offline cache status and a manual purge.
class _OfflineCard extends ConsumerStatefulWidget {
  const _OfflineCard();

  @override
  ConsumerState<_OfflineCard> createState() => _OfflineCardState();
}

class _OfflineCardState extends ConsumerState<_OfflineCard> {
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(cacheStoreProvider);
    final offline = store is OfflineCacheStore ? store : null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Offline data'),
          Text(
            offline == null
                ? 'Responses are cached in memory for this session only. '
                    'Persistent caching is unavailable on this platform.'
                : 'Race, standings and analytics responses are stored on this '
                    'device, so screens you have opened before still work '
                    'without a connection.',
            style: AppTextStyles.body,
          ),
          if (offline != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.storage_rounded,
                    size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Text('${offline.entryCount} cached responses',
                    style: AppTextStyles.label),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    offline.clear();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offline cache cleared.')),
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.surfaceStroke),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'About'),
          Text(
            'F1 Vision · live data from OpenF1, historical data from Jolpica '
            '(Ergast-compatible). This is an unofficial fan project and is not '
            'associated with Formula 1.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 12),
          Text('VERSION 0.6.0', style: AppTextStyles.overline),
        ],
      ),
    );
  }
}
