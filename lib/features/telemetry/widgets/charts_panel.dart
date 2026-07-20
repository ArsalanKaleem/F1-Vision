import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/telemetry.dart';
import '../../../providers/telemetry_providers.dart';
import 'telemetry_channel_chart.dart';
import 'viewport_navigator.dart';

/// Hosts the synchronized telemetry charts. Owns the crosshair + viewport
/// interaction state locally so dragging the cursor or zooming repaints only
/// this subtree — the gauges and status rail (separate `ConsumerWidget`s) are
/// untouched. Telemetry samples are read with a `select` so the panel rebuilds
/// only when the buffer itself changes.
class ChartsPanel extends ConsumerStatefulWidget {
  const ChartsPanel({super.key, required this.args});

  final TelemetryArgs args;

  @override
  ConsumerState<ChartsPanel> createState() => _ChartsPanelState();
}

class _ChartsPanelState extends ConsumerState<ChartsPanel> {
  double? _manualStart;
  double? _manualEnd;
  bool _following = true;
  double? _hover;

  void _onViewport(double start, double end) {
    setState(() {
      _manualStart = start;
      _manualEnd = end;
      _following = false;
    });
  }

  void _onFollow() {
    setState(() {
      _following = true;
      _manualStart = null;
      _manualEnd = null;
    });
  }

  void _onHover(double? x) => setState(() => _hover = x);

  @override
  Widget build(BuildContext context) {
    final samples = ref.watch(
      telemetryStreamProvider(widget.args).select((s) => s.samples),
    );
    final n = samples.length;

    if (n < 2) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text('Buffering telemetry…',
              style: TextStyle(color: AppColors.textTertiary)),
        ),
      );
    }

    final maxX = (n - 1).toDouble();
    final double start = _following || _manualStart == null
        ? 0.0
        : _manualStart!.clamp(0, maxX).toDouble();
    final double end = _following || _manualEnd == null
        ? maxX
        : _manualEnd!.clamp(0, maxX).toDouble();
    final double safeEnd =
        (end - start) < 2 ? (start + 2).clamp(0, maxX).toDouble() : end;

    final hoverInRange =
        _hover != null && _hover! >= 0 && _hover! <= maxX ? _hover : null;
    final cursorIndex = (hoverInRange?.round() ?? (n - 1)).clamp(0, n - 1);
    final cursor = samples[cursorIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CursorReadout(sample: cursor, live: hoverInRange == null),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'SPEED',
          value: '${cursor.speed} km/h',
          accent: AppColors.info,
          child: TelemetryChannelChart(
            samples: samples,
            minX: start,
            maxX: safeEnd,
            minY: 0,
            maxY: TelemetrySample.speedScale,
            unit: 'km/h',
            hoverIndex: hoverInRange,
            onHover: _onHover,
            series: [
              ChannelSeries(
                label: 'Speed',
                color: AppColors.info,
                selector: (s) => s.speed.toDouble(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'ENGINE RPM',
          value: '${cursor.rpm} rpm',
          accent: AppColors.accentSoft,
          child: TelemetryChannelChart(
            samples: samples,
            minX: start,
            maxX: safeEnd,
            minY: 0,
            maxY: TelemetrySample.rpmScale,
            unit: 'rpm',
            hoverIndex: hoverInRange,
            onHover: _onHover,
            leftLabel: (v) => '${(v / 1000).toStringAsFixed(0)}k',
            series: [
              ChannelSeries(
                label: 'RPM',
                color: AppColors.accentSoft,
                selector: (s) => s.rpm.toDouble(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'THROTTLE & BRAKE',
          value: '${cursor.throttle}% / ${cursor.brake}%',
          accent: AppColors.positive,
          child: TelemetryChannelChart(
            samples: samples,
            minX: start,
            maxX: safeEnd,
            minY: 0,
            maxY: 105,
            unit: '%',
            hoverIndex: hoverInRange,
            onHover: _onHover,
            series: [
              ChannelSeries(
                label: 'Throttle',
                color: AppColors.positive,
                selector: (s) => s.throttle.toDouble(),
              ),
              ChannelSeries(
                label: 'Brake',
                color: AppColors.negative,
                selector: (s) => s.brake.toDouble(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ViewportNavigator(
            count: n,
            start: start,
            end: safeEnd,
            following: _following,
            onViewport: _onViewport,
            onFollow: _onFollow,
          ),
        ),
      ],
    );
  }
}

/// Engineer cursor read-out — the values under the crosshair (or live values
/// when the cursor isn't engaged).
class _CursorReadout extends StatelessWidget {
  const _CursorReadout({required this.sample, required this.live});
  final TelemetrySample sample;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final t = sample.date.toLocal();
    final time =
        '${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                live ? Icons.sensors_rounded : Icons.my_location_rounded,
                size: 14,
                color: live ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(live ? 'LIVE  $time' : 'CURSOR  $time',
                  style: AppTextStyles.overline),
            ],
          ),
          _Readout(label: 'SPEED', value: '${sample.speed}', unit: 'km/h'),
          _Readout(label: 'RPM', value: '${sample.rpm}', unit: ''),
          _Readout(label: 'GEAR', value: sample.gearLabel, unit: ''),
          _Readout(label: 'THR', value: '${sample.throttle}', unit: '%'),
          _Readout(label: 'BRK', value: '${sample.brake}', unit: '%'),
          _Readout(
            label: 'DRS',
            value: sample.drsActive
                ? 'OPEN'
                : sample.drsEligible
                    ? 'RDY'
                    : 'OFF',
            unit: '',
            valueColor: sample.drsActive
                ? AppColors.positive
                : sample.drsEligible
                    ? AppColors.warning
                    : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.overline.copyWith(fontSize: 9)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.numeric.copyWith(
                fontSize: 18,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(unit, style: AppTextStyles.overline.copyWith(fontSize: 9)),
            ],
          ],
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.child,
  });

  final String title;
  final String value;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(12, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: AppTextStyles.overline),
                  const Spacer(),
                  Text(
                    value,
                    style: AppTextStyles.label.copyWith(color: accent),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
