import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:reports/design/reports_design.dart';

class AcceptedHomeHero extends StatelessWidget {
  const AcceptedHomeHero({
    super.key,
    required this.height,
    required this.onStartReport,
  });

  final double height;
  final VoidCallback onStartReport;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('home-hero'),
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(color: ReportsStyle.orangeDark, offset: Offset(0, 4)),
      ],
    ),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: ReportsStyle.orangeDark, width: 2),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          painter: ReportDeliveryPainter(
            seconds: 5.8,
            heroBounds: Offset.zero & constraints.biggest,
          ),
          child: _AcceptedHeroControls(onStartReport: onStartReport),
        ),
      ),
    ),
  );
}

class _AcceptedHeroControls extends StatelessWidget {
  const _AcceptedHeroControls({this.onStartReport});

  final VoidCallback? onStartReport;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const Positioned(
        top: 27,
        left: 24,
        right: 24,
        child: Text(
          'Thank you.',
          style: TextStyle(
            fontSize: 35,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ),
      Positioned(
        left: 24,
        right: 24,
        bottom: 25,
        child: FilledButton.icon(
          style:
              ReportsStyle.raisedButtonStyle(
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: ReportsStyle.orangeDark,
                  width: 2,
                ),
              ).copyWith(
                foregroundColor: const WidgetStatePropertyAll(ReportsStyle.ink),
                backgroundBuilder: (context, states, child) =>
                    ReportsRaisedButton(
                      states: onStartReport == null ? const {} : states,
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: ReportsStyle.orangeDark,
                        width: 2,
                      ),
                      child: child!,
                    ),
              ),
          onPressed: onStartReport,
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          iconAlignment: IconAlignment.end,
          label: const Text('Start a report'),
        ),
      ),
    ],
  );
}
