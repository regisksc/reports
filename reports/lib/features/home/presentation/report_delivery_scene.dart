import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:reports/design/reports_design.dart';

import 'report_delivery_painter.dart';

class ReportDeliveryScene extends StatefulWidget {
  const ReportDeliveryScene({
    super.key,
    required this.heroBounds,
    required this.onComplete,
  });

  final Rect heroBounds;
  final VoidCallback onComplete;

  @override
  State<ReportDeliveryScene> createState() => _ReportDeliverySceneState();
}

class _ReportDeliverySceneState extends State<ReportDeliveryScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 5800),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _complete();
        }
      });

  bool _completed = false;

  void _complete() {
    if (_completed) {
      return;
    }
    _completed = true;
    _controller.stop();
    widget.onComplete();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || widget.heroBounds.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _complete();
        }
      });
    } else if (!_completed) {
      _controller.forward();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _complete();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Your accepted report is arriving at town hall.',
    child: AnimatedBuilder(
      animation: _controller,
      child: const _AcceptedHeroControls(),
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          final seconds = _controller.value * 5.8;
          final settle = Curves.easeInOutCubic.transform(
            ((seconds - 4.4) / 1.4).clamp(0, 1),
          );
          final frame = Rect.lerp(
            Offset.zero & constraints.biggest,
            widget.heroBounds,
            settle,
          )!;
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                key: const Key('report-delivery-scene'),
                painter: ReportDeliveryPainter(
                  seconds: seconds,
                  heroBounds: widget.heroBounds,
                ),
              ),
              Positioned.fromRect(
                rect: frame,
                child: IgnorePointer(
                  child: Opacity(opacity: settle, child: child),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
