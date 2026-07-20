import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/live_badge.dart';
import '../../models/driver.dart';
import '../../models/session.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/telemetry_providers.dart';
import 'widgets/charts_panel.dart';
import 'widgets/driver_selector.dart';
import 'widgets/gauges_cluster.dart';
import 'widgets/status_rail.dart';

/// The flagship telemetry dashboard: animated gauges, an engineer cursor
/// read-out, and synchronized speed / RPM / pedal traces streamed live from
/// OpenF1 `/car_data`. Layout collapses from a two-column desktop cockpit to a
/// single scrolling column on mobile.
class TelemetryScreen extends ConsumerWidget {
  const TelemetryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(latestSessionProvider);
    final pad = context.responsive(mobile: 16.0, desktop: 28.0);

    return Padding(
      padding: EdgeInsets.all(pad),
      child: sessionAsync.when(
        loading: () => const _Centered(child: CircularProgressIndicator()),
        error: (e, _) => _Centered(child: _Message(text: '$e')),
        data: (result) => result.when(
          success: (session) => _TelemetryBody(session: session),
          failure: (f) => _Centered(child: _Message(text: f.message)),
        ),
      ),
    );
  }
}

class _TelemetryBody extends ConsumerWidget {
  const _TelemetryBody({required this.session});
  final F1Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(telemetryDriversProvider(session.sessionKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(session: session),
        const SizedBox(height: 20),
        Expanded(
          child: driversAsync.when(
            loading: () => const _Centered(child: CircularProgressIndicator()),
            error: (e, _) => _Centered(child: _Message(text: '$e')),
            data: (result) => result.when(
              success: (drivers) => _Loaded(session: session, drivers: drivers),
              failure: (f) => _Centered(child: _Message(text: f.message)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.session, required this.drivers});
  final F1Session session;
  final List<F1Driver> drivers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session.dateStart == null) {
      return const _Centered(
        child: _Message(
          text: 'This session has no published start time, so its telemetry '
              'window can’t be located yet. Try again once timing is available.',
        ),
      );
    }
    if (drivers.isEmpty) {
      return const _Centered(
        child: _Message(text: 'No drivers are entered for this session yet.'),
      );
    }

    final selected = ref.watch(selectedDriverProvider);
    final hasSelected =
        selected != null && drivers.any((d) => d.driverNumber == selected);
    final effective = hasSelected ? selected! : drivers.first.driverNumber;

    final args = TelemetryArgs(
      sessionKey: session.sessionKey,
      driverNumber: effective,
      sessionStart: session.dateStart!,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DriverSelector(drivers: drivers, selected: effective),
            ),
            const SizedBox(width: 12),
            _StreamControls(args: args),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: context.isDesktop
              ? _DesktopLayout(args: args)
              : _MobileLayout(args: args),
        ),
      ],
    );
  }
}

/// Pause/resume and restart controls for the telemetry replay.
class _StreamControls extends ConsumerWidget {
  const _StreamControls({required this.args});
  final TelemetryArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = ref.watch(
      telemetryStreamProvider(args).select((s) => s.paused),
    );
    final notifier = ref.read(telemetryStreamProvider(args).notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          highlight: paused,
          onTap: notifier.togglePause,
        ),
        const SizedBox(width: 8),
        _ControlButton(
          icon: Icons.restart_alt_rounded,
          onTap: notifier.restart,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? AppColors.accent : AppColors.surfaceStroke,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: highlight ? AppColors.accentSoft : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Two-column cockpit: instruments on the left, scrolling traces on the right.
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.args});
  final TelemetryArgs args;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GlassCard(child: GaugesCluster(args: args)),
                const SizedBox(height: 16),
                GlassCard(child: StatusRail(args: args)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SingleChildScrollView(child: ChartsPanel(args: args)),
        ),
      ],
    );
  }
}

/// Single scrolling column for mobile / tablet.
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.args});
  final TelemetryArgs args;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(child: GaugesCluster(args: args)),
          const SizedBox(height: 16),
          GlassCard(child: StatusRail(args: args)),
          const SizedBox(height: 16),
          ChartsPanel(args: args),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session});
  final F1Session session;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (session.location.isNotEmpty) session.location,
      if (session.sessionName.isNotEmpty) session.sessionName,
    ].join('  ·  ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CAR TELEMETRY', style: AppTextStyles.overline),
              const SizedBox(height: 4),
              Text('Telemetry', style: AppTextStyles.displayLarge),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.body),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: LiveBadge(label: 'STREAM'),
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(child: child);
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
