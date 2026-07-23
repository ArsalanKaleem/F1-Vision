import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import 'widgets/about_sections.dart';
import 'widgets/developer_hero.dart';

/// The About page: who built the app, how to get help, and what it stands on.
///
/// Everything shown here is configured in `core/constants/app_info.dart` —
/// name, links and store URLs — so forking the project means editing one file.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = context.responsive(
      mobile: AppSpacing.pagePadMobile,
      desktop: AppSpacing.pagePadDesktop,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: AppSpacing.xl),
              DeveloperHero(onOpen: (url, label) => _open(context, url, label)),
              const SizedBox(height: AppSpacing.panelGap),
              const _Sections(),
              const AboutFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────

  static Future<void> _open(
    BuildContext context, String url, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('No $label link has been configured yet.')),
      );
      return;
    }
    try {
      final uri = Uri.parse(trimmed);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: Text('Couldn’t open $label.')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Couldn’t open $label.')),
      );
    }
  }

  /// Store listing for the current platform, falling back to the repository so
  /// "Rate App" always does something useful before release.
  static String get _rateUrl {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          AppInfo.androidStoreUrl.isNotEmpty) {
        return AppInfo.androidStoreUrl;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          AppInfo.iosStoreUrl.isNotEmpty) {
        return AppInfo.iosStoreUrl;
      }
    }
    return AppInfo.repoUrl;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ABOUT', style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs),
        Text(AppInfo.appName, style: AppTextStyles.displayLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(AppInfo.appTagline, style: AppTextStyles.body),
      ],
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections();

  @override
  Widget build(BuildContext context) {
    const support = _SupportSection();
    const openSource = _OpenSourceSection();

    if (context.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: support),
          const SizedBox(width: AppSpacing.panelGap),
          Expanded(child: openSource),
        ],
      ).animate().fadeIn(delay: 120.ms, duration: 380.ms);
    }

    return Column(
      children: [
        support,
        const SizedBox(height: AppSpacing.panelGap),
        openSource,
      ],
    ).animate().fadeIn(delay: 120.ms, duration: 380.ms);
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return AboutSection(
      title: 'Support',
      subtitle: 'Feedback, issues and the legal bits',
      icon: Icons.support_agent_rounded,
      child: Column(
        children: [
          AboutTile(
            icon: Icons.star_rounded,
            label: 'Rate App',
            description: 'Leave a rating or star the repository',
            accent: AppColors.warning,
            onTap: () =>
                AboutScreen._open(context, AboutScreen._rateUrl, 'the store'),
          ),
          const TileDivider(),
          AboutTile(
            icon: Icons.bug_report_rounded,
            label: 'Report a Bug',
            description: 'Open a pre-labelled issue on GitHub',
            accent: AppColors.negative,
            onTap: () => AboutScreen._open(
                context, AppInfo.bugReportUrl, 'the bug tracker'),
          ),
          const TileDivider(),
          AboutTile(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Request a Feature',
            description: 'Suggest something for a future release',
            accent: AppColors.positive,
            onTap: () => AboutScreen._open(
                context, AppInfo.featureRequestUrl, 'the issue tracker'),
          ),
          const TileDivider(),
          AboutTile(
            icon: Icons.shield_outlined,
            label: 'Privacy Policy',
            description: 'What is stored, and where',
            accent: AppColors.info,
            trailingIcon: Icons.chevron_right_rounded,
            onTap: () => _legal(
              context,
              title: 'Privacy Policy',
              body: LegalText.privacy,
              url: AppInfo.privacyPolicyUrl,
            ),
          ),
          const TileDivider(),
          AboutTile(
            icon: Icons.gavel_rounded,
            label: 'Terms & Conditions',
            description: 'Fan project, data accuracy, licence',
            accent: const Color(0xFF9B59B6),
            trailingIcon: Icons.chevron_right_rounded,
            onTap: () => _legal(
              context,
              title: 'Terms & Conditions',
              body: LegalText.terms,
              url: AppInfo.termsUrl,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the hosted page when one is configured, otherwise shows the
  /// bundled text — so these entries never dead-end.
  void _legal(
    BuildContext context, {
    required String title,
    required String body,
    required String url,
  }) {
    if (url.trim().isNotEmpty) {
      AboutScreen._open(context, url, title);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: ListView(
            controller: controller,
            children: [
              Text(title, style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Last updated ${AppInfo.copyrightYear}',
                  style: AppTextStyles.overline),
              const SizedBox(height: AppSpacing.xl),
              Text(
                body.trim(),
                style: AppTextStyles.body.copyWith(height: 1.7),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenSourceSection extends StatelessWidget {
  const _OpenSourceSection();

  static const _tech = <({String label, Color color, IconData icon})>[
    (label: 'Flutter', color: Color(0xFF42A5F5), icon: Icons.flutter_dash),
    (label: 'Dart', color: Color(0xFF0175C2), icon: Icons.code_rounded),
    (
      label: 'Riverpod',
      color: Color(0xFF2ECC71),
      icon: Icons.account_tree_outlined
    ),
    (label: 'Isar', color: Color(0xFF9B59B6), icon: Icons.storage_rounded),
    (label: 'Firebase', color: Color(0xFFF5A623), icon: Icons.lock_outline),
    (label: 'OpenF1', color: Color(0xFFE10600), icon: Icons.sensors_rounded),
    (label: 'Jolpica', color: Color(0xFF00BCD4), icon: Icons.history_rounded),
  ];

  static const _packages = <({String name, String purpose, String licence})>[
    (
      name: 'flutter_riverpod',
      purpose: 'State management & dependency injection',
      licence: 'MIT'
    ),
    (name: 'go_router', purpose: 'Declarative routing', licence: 'BSD-3'),
    (name: 'dio', purpose: 'HTTP client with retry & caching', licence: 'MIT'),
    (name: 'fl_chart', purpose: 'Line, bar, radar & scatter charts', licence: 'MIT'),
    (name: 'isar', purpose: 'On-device offline cache', licence: 'Apache-2.0'),
    (
      name: 'firebase_auth',
      purpose: 'Email & Google authentication',
      licence: 'BSD-3'
    ),
    (name: 'google_fonts', purpose: 'Sora & Inter typefaces', licence: 'Apache-2.0'),
    (name: 'flutter_animate', purpose: 'Entrance & micro-animations', licence: 'MIT'),
    (name: 'shimmer', purpose: 'Skeleton loading states', licence: 'BSD-3'),
    (
      name: 'cached_network_image',
      purpose: 'Image caching',
      licence: 'MIT'
    ),
    (
      name: 'font_awesome_flutter',
      purpose: 'Social brand iconography',
      licence: 'CC BY 4.0'
    ),
    (name: 'url_launcher', purpose: 'Opening external links', licence: 'BSD-3'),
  ];

  @override
  Widget build(BuildContext context) {
    return AboutSection(
      title: 'Open Source',
      subtitle: 'Built on the shoulders of giants',
      icon: Icons.hub_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('TECHNOLOGIES USED', style: AppTextStyles.overline),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in _tech)
                TechChip(label: t.label, color: t.color, icon: t.icon),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('FRAMEWORKS & LIBRARIES', style: AppTextStyles.overline),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _packages.length; i++) ...[
            if (i > 0) const TileDivider(),
            PackageRow(
              name: _packages[i].name,
              purpose: _packages[i].purpose,
              licence: _packages[i].licence,
              onTap: () => AboutScreen._open(
                context,
                'https://pub.dev/packages/${_packages[i].name}',
                _packages[i].name,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AboutTile(
            icon: Icons.article_outlined,
            label: 'Licenses',
            description: 'Full third-party licence texts',
            accent: AppColors.info,
            trailingIcon: Icons.chevron_right_rounded,
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppInfo.appName,
              applicationVersion: 'v${AppInfo.version}',
              applicationLegalese:
                  '© ${AppInfo.copyrightYear} ${AppInfo.developerName}',
            ),
          ),
          const TileDivider(),
          AboutTile(
            icon: Icons.code_rounded,
            label: 'Source Code',
            description: 'MIT licensed on GitHub',
            accent: AppColors.positive,
            onTap: () =>
                AboutScreen._open(context, AppInfo.repoUrl, 'the repository'),
          ),
        ],
      ),
    );
  }
}
