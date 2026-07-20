import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/telemetry.dart';
import '../../../providers/telemetry_providers.dart';
import 'gauge_dial.dart';

/// Speed + RPM dials. Each watches only its own scalar through `select`, so a
/// new telemetry frame repaints the gauges without touching the charts.
class GaugesCluster extends StatelessWidget {
  const GaugesCluster({super.key, required this.args});

  final TelemetryArgs args;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SpeedGauge(args: args)),
        const SizedBox(width: 16),
        Expanded(child: _RpmGauge(args: args)),
      ],
    );
  }
}

class _SpeedGauge extends ConsumerWidget {
  const _SpeedGauge({required this.args});
  final TelemetryArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(
      telemetryStreamProvider(args).select((s) => s.latest?.speed ?? 0),
    );
    return GaugeDial(
      value: speed.toDouble(),
      max: TelemetrySample.speedScale,
      label: 'KM/H',
      color: AppColors.info,
    );
  }
}

class _RpmGauge extends ConsumerWidget {
  const _RpmGauge({required this.args});
  final TelemetryArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rpm = ref.watch(
      telemetryStreamProvider(args).select((s) => s.latest?.rpm ?? 0),
    );
    return GaugeDial(
      value: rpm.toDouble(),
      max: TelemetrySample.rpmScale,
      label: 'RPM',
      color: AppColors.accentSoft,
      redlineFraction: 0.80,
    );
  }
}
