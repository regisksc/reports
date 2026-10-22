import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:reports/design/reports_design.dart';

class ReportDeliveryPainter extends CustomPainter {
  const ReportDeliveryPainter({
    required this.seconds,
    required this.heroBounds,
  });

  final double seconds;
  final Rect heroBounds;

  double _phase(double start, double end) =>
      ((seconds - start) / (end - start)).clamp(0, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final settle = Curves.easeInOutCubic.transform(_phase(4.4, 5.8));
    final frame = Rect.lerp(Offset.zero & size, heroBounds, settle)!;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(frame, Radius.circular(22 * settle)),
    );
    canvas.drawRect(
      frame,
      Paint()..color = Color.lerp(Colors.white, ReportsStyle.orange, settle)!,
    );
    final scale = math.min(frame.width / 1120, frame.height / 820);
    canvas.translate(frame.center.dx, frame.center.dy);
    canvas.scale(scale);
    canvas.translate(-960, -600);
    _clouds(canvas);
    final reveal = Curves.easeOutBack.transform(_phase(2.5, 3.15));
    if (seconds >= 2.5) {
      canvas.saveLayer(
        null,
        Paint()..color = Colors.white.withValues(alpha: _phase(2.5, 3.15)),
      );
      canvas.save();
      canvas.translate(960, 760 + 80 * (1 - reveal));
      canvas.scale(.85 + .15 * reveal);
      canvas.translate(-960, -760);
      _townHall(canvas);
      final glow = _phase(3.85, 4.13);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(903, 681, 114, 38),
          const Radius.circular(19),
        ),
        Paint()..color = const Color(0xffffd98d).withValues(alpha: glow),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(914, 692, 92, 16),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xff2f5149),
      );
      _sparkles(canvas, _phase(3.98, 4.33));
      canvas.restore();
      canvas.restore();
    }
    if (seconds < 3.95) {
      _letter(canvas, frame.height / scale);
    }
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame.deflate(1), Radius.circular(21 * settle)),
      Paint()
        ..color = ReportsStyle.orangeDark.withValues(alpha: settle)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _clouds(Canvas canvas) {
    final opacity = _phase(1.6, 1.9) * (1 - _phase(3.1, 3.8));
    final travel = _phase(1.6, 3.8);
    final paint = Paint()
      ..color = const Color(0xfff7f2ea).withValues(alpha: opacity);
    for (final (index, center) in [
      Offset(600 - 220 * travel, 290),
      Offset(1430 - 100 * travel, 220),
    ].indexed) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(.8 + index * .3);
      canvas.drawPath(
        Path()
          ..moveTo(-130, 20)
          ..cubicTo(-160, -15, -135, -58, -88, -50)
          ..cubicTo(-60, -110, 25, -100, 55, -50)
          ..cubicTo(125, -65, 160, 10, 115, 30)
          ..close(),
        paint,
      );
      canvas.restore();
    }
  }

  void _letter(Canvas canvas, double viewportHeight) {
    final cameraZoom = math.max(12.0, viewportHeight / 160 + 2);
    var center = const Offset(960, 540);
    var zoom = 1.0;
    var angle = 0.0;
    if (seconds >= .45 && seconds < 1.05) {
      zoom = lerpDouble(
        1,
        cameraZoom,
        Curves.easeInCubic.transform(_phase(.45, 1.05)),
      )!;
    } else if (seconds >= 1.05 && seconds < 1.8) {
      zoom = lerpDouble(
        cameraZoom,
        1,
        Curves.easeOutCubic.transform(_phase(1.05, 1.8)),
      )!;
    } else if (seconds >= 1.9 && seconds < 2.5) {
      final flight = Curves.easeInCubic.transform(_phase(1.9, 2.3));
      center = Offset(
        lerpDouble(960, 2400, flight)!,
        540 - 300 * math.sin(flight * math.pi / 2),
      );
      zoom = lerpDouble(1, .62, flight)!;
      angle = flight * .21;
      _trail(canvas, flight, false);
    } else if (seconds >= 2.5) {
      final flight = Curves.easeOutCubic.transform(_phase(2.5, 3.55));
      center = Offset(
        lerpDouble(-400, 960, flight)!,
        410 + 290 * flight - 140 * math.sin(flight * math.pi),
      );
      zoom = lerpDouble(.62, .13, flight)!;
      angle = -.3 * (1 - flight) + .3 * math.sin(flight * math.pi);
      _trail(canvas, _phase(2.5, 3.02), true);
    }
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: 1 - _phase(3.85, 3.95)),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final posted = Curves.easeInQuad.transform(_phase(3.65, 3.93));
    canvas.scale(zoom, zoom * (1 - posted * .9));
    final fold = Curves.easeInOut.transform(_phase(1.05, 1.65));
    final width = lerpDouble(1020, 520, fold)!;
    final height = lerpDouble(160, 320, fold)!;
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    if (seconds < .65) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 15)),
          const Radius.circular(45),
        ),
        Paint()..color = ReportsStyle.orangeDark,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(lerpDouble(45, 20, fold)!)),
      Paint()..color = ReportsStyle.orange,
    );
    final line = Paint()
      ..color = const Color(0xffd77b00).withValues(alpha: _phase(1.55, 1.73))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(-248, 147)
        ..lineTo(-65, -8)
        ..moveTo(248, 147)
        ..lineTo(65, -8),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-248, -145)
        ..lineTo(-22, 34)
        ..quadraticBezierTo(0, 51, 22, 34)
        ..lineTo(248, -145),
      line,
    );
    canvas.restore();
    canvas.restore();
  }

  void _trail(Canvas canvas, double progress, bool arriving) {
    final paint = Paint()
      ..color = const Color(
        0xffffb54d,
      ).withValues(alpha: math.sin(progress * math.pi).clamp(0, 1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.save();
    if (arriving) {
      canvas.translate(-1000, 750);
      canvas.scale(1, -1);
    }
    canvas.drawPath(
      Path()
        ..moveTo(430, 415)
        ..quadraticBezierTo(780, 135, 1470, 245),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(640, 460)
        ..quadraticBezierTo(970, 235, 1450, 295),
      paint..strokeWidth = 7,
    );
    canvas.drawPath(
      Path()
        ..moveTo(930, 140)
        ..quadraticBezierTo(1170, 100, 1430, 165),
      paint..strokeWidth = 6,
    );
    canvas.restore();
  }

  void _sparkles(Canvas canvas, double progress) {
    final paint = Paint()
      ..color = const Color(0xffffb64d).withValues(alpha: progress);
    canvas.drawPath(
      Path()
        ..moveTo(837, 657)
        ..quadraticBezierTo(844, 683, 866, 688)
        ..quadraticBezierTo(844, 694, 837, 720)
        ..quadraticBezierTo(830, 694, 808, 688)
        ..quadraticBezierTo(830, 683, 837, 657)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(1086, 645)
        ..quadraticBezierTo(1091, 665, 1109, 670)
        ..quadraticBezierTo(1091, 675, 1086, 695)
        ..quadraticBezierTo(1081, 675, 1063, 670)
        ..quadraticBezierTo(1081, 665, 1086, 645)
        ..close(),
      paint,
    );
    canvas.drawCircle(const Offset(1068, 735), 7, paint);
    canvas.drawCircle(const Offset(869, 750), 5, paint);
  }

  void _shape(
    Canvas canvas,
    Path path,
    Color? fill,
    Color? stroke,
    double width,
  ) {
    if (fill != null) {
      canvas.drawPath(path, Paint()..color = fill);
    }
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _townHall(Canvas canvas) {
    _shape(
      canvas,
      Path()..addOval(
        Rect.fromCenter(
          center: const Offset(960, 875),
          width: 910.0,
          height: 50.0,
        ),
      ),
      const Color(0xfff4eee5),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(595, 580, 190, 250),
          const Radius.circular(14),
        ),
      ),
      const Color(0xfffff1db),
      const Color(0xffcfad87),
      6,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1135, 580, 190, 250),
          const Radius.circular(14),
        ),
      ),
      const Color(0xfffff1db),
      const Color(0xffcfad87),
      6,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(581, 568, 218, 23),
          const Radius.circular(10),
        ),
      ),
      const Color(0xffdf9c68),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1121, 568, 218, 23),
          const Radius.circular(10),
        ),
      ),
      const Color(0xffdf9c68),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(632, 627, 49, 67),
          const Radius.circular(16),
        ),
      ),
      const Color(0xffa5c7bd),
      const Color(0xff6b9489),
      5,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(706, 627, 49, 67),
          const Radius.circular(16),
        ),
      ),
      const Color(0xffa5c7bd),
      const Color(0xff6b9489),
      5,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1165, 627, 49, 67),
          const Radius.circular(16),
        ),
      ),
      const Color(0xffa5c7bd),
      const Color(0xff6b9489),
      5,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1239, 627, 49, 67),
          const Radius.circular(16),
        ),
      ),
      const Color(0xffa5c7bd),
      const Color(0xff6b9489),
      5,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(632, 735, 49, 58),
          const Radius.circular(13),
        ),
      ),
      const Color(0xffa5c7bd),
      const Color(0xff6b9489),
      5,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(706, 735, 49, 58),
          const Radius.circular(13),
        ),
      ),
      const Color(0xffa5c7bd),
      const Color(0xff6b9489),
      5,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1165, 735, 49, 58),
          const Radius.circular(13),
        ),
      ),
      const Color(0xffa5c7bd),
      const Color(0xff6b9489),
      5,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1239, 735, 49, 58),
          const Radius.circular(13),
        ),
      ),
      const Color(0xffa5c7bd),
      const Color(0xff6b9489),
      5,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(760, 511, 400, 322),
          const Radius.circular(18),
        ),
      ),
      const Color(0xfffff6e7),
      const Color(0xffcfad87),
      7,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(730, 520)
        ..lineTo(948, 357)
        ..quadraticBezierTo(960, 348, 972, 357)
        ..lineTo(1190, 520)
        ..close(),
      const Color(0xffeaaa78),
      const Color(0xffc8885c),
      9,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(781, 501)
        ..lineTo(960, 371)
        ..lineTo(1139, 501)
        ..close(),
      const Color(0xfff7cf9b),
      null,
      0,
    );
    _shape(
      canvas,
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(960, 453), radius: 31)),
      const Color(0xfffff6e7),
      const Color(0xffc8885c),
      8,
    );
    _shape(
      canvas,
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(960, 453), radius: 13)),
      const Color(0xffa5c7bd),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(737, 516, 446, 24),
          const Radius.circular(10),
        ),
      ),
      const Color(0xffd99d70),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(798, 555, 38, 254),
          const Radius.circular(12),
        ),
      ),
      const Color(0xfffffcf3),
      const Color(0xffdcc5a6),
      4,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1084, 555, 38, 254),
          const Radius.circular(12),
        ),
      ),
      const Color(0xfffffcf3),
      const Color(0xffdcc5a6),
      4,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(783, 547, 68, 18),
          const Radius.circular(7),
        ),
      ),
      const Color(0xffe8c49a),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1069, 547, 68, 18),
          const Radius.circular(7),
        ),
      ),
      const Color(0xffe8c49a),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(783, 800, 68, 18),
          const Radius.circular(7),
        ),
      ),
      const Color(0xffe8c49a),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1069, 800, 68, 18),
          const Radius.circular(7),
        ),
      ),
      const Color(0xffe8c49a),
      null,
      0,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(890, 822)
        ..lineTo(890, 674)
        ..arcToPoint(
          const Offset(1030, 674),
          radius: const Radius.elliptical(70, 70),
          clockwise: true,
        )
        ..lineTo(1030, 822)
        ..close(),
      const Color(0xff4f776d),
      const Color(0xff3f665d),
      7,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(908, 813)
        ..lineTo(908, 677)
        ..arcToPoint(
          const Offset(1012, 677),
          radius: const Radius.elliptical(52, 52),
          clockwise: true,
        )
        ..lineTo(1012, 813)
        ..close(),
      const Color(0xff638b7e),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(914, 692, 92, 16),
          const Radius.circular(8),
        ),
      ),
      const Color(0xff2f5149),
      null,
      0,
    );
    _shape(
      canvas,
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(1000, 755), radius: 7)),
      const Color(0xfff6c16e),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(729, 821, 462, 21),
          const Radius.circular(9),
        ),
      ),
      const Color(0xffead1b1),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(703, 839, 514, 21),
          const Radius.circular(9),
        ),
      ),
      const Color(0xffead1b1),
      null,
      0,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(678, 857, 564, 18),
          const Radius.circular(9),
        ),
      ),
      const Color(0xffead1b1),
      null,
      0,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(533, 855)
        ..cubicTo(508, 834, 520, 794, 550, 795)
        ..cubicTo(555, 757, 608, 757, 616, 792)
        ..cubicTo(648, 782, 673, 820, 649, 855)
        ..close(),
      const Color(0xff83aa90),
      null,
      0,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(1271, 855)
        ..cubicTo(1247, 821, 1274, 784, 1303, 795)
        ..cubicTo(1316, 756, 1363, 760, 1369, 798)
        ..cubicTo(1400, 798, 1413, 834, 1388, 855)
        ..close(),
      const Color(0xff83aa90),
      null,
      0,
    );
  }

  @override
  bool shouldRepaint(ReportDeliveryPainter oldDelegate) =>
      oldDelegate.seconds != seconds || oldDelegate.heroBounds != heroBounds;
}
