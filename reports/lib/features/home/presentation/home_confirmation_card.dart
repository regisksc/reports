import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/presentation/report_presentation.dart';
import 'package:reports/features/report/domain/report.dart';

class HomeConfirmationCard extends StatefulWidget {
  const HomeConfirmationCard({
    super.key,
    required this.serviceRequestNumber,
    required this.onViewReceipt,
    required this.onDismissed,
  });

  final String serviceRequestNumber;
  final VoidCallback onViewReceipt;
  final VoidCallback onDismissed;

  @override
  State<HomeConfirmationCard> createState() => _HomeConfirmationCardState();
}

class _HomeConfirmationCardState extends State<HomeConfirmationCard>
    with SingleTickerProviderStateMixin {
  late final _position = AnimationController.unbounded(vsync: this);
  bool _pointerCancelled = false;

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  Future<void> _settle(double destination) async {
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = destination;
    } else {
      await _position.animateTo(
        destination,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted && destination == -1) widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Listener(
      onPointerCancel: (_) => _pointerCancelled = true,
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          _pointerCancelled = false;
          _position.stop();
        },
        onHorizontalDragUpdate: (details) => _position.value = math.min(
          0.0,
          _position.value + details.delta.dx / constraints.maxWidth,
        ),
        onHorizontalDragEnd: (_) {
          final dismiss = !_pointerCancelled && _position.value <= -.4;
          _pointerCancelled = false;
          _settle(dismiss ? -1 : 0);
        },
        onHorizontalDragCancel: () {
          _pointerCancelled = false;
          _settle(0);
        },
        child: AnimatedBuilder(
          animation: _position,
          builder: (context, child) => Transform.translate(
            key: const Key('confirmation-displacement'),
            offset: Offset(_position.value * constraints.maxWidth, 0),
            child: Opacity(
              key: const Key('confirmation-opacity'),
              opacity: (1 - (-_position.value - .2) / .8).clamp(0, 1),
              child: child,
            ),
          ),
          child: Card(
            key: const Key('home-confirmation-card'),
            margin: EdgeInsets.zero,
            color: reportStatusColor(ReportState.submitted).withAlpha(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: reportStatusColor(ReportState.submitted),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Report received.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Submitted',
                    style: TextStyle(
                      color: reportStatusColor(ReportState.submitted),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text('Sent to MyLA311. Service Request number:'),
                  const SizedBox(height: 6),
                  Text(
                    widget.serviceRequestNumber,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: widget.serviceRequestNumber),
                        ),
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Copy'),
                      ),
                      TextButton(
                        onPressed: widget.onViewReceipt,
                        child: const Text('View receipt'),
                      ),
                    ],
                  ),
                  const Text(
                    'Swipe left to dismiss. Your receipt stays saved.',
                    style: TextStyle(fontSize: 11, color: ReportsStyle.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
