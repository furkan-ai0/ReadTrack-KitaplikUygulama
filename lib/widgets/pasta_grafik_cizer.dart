import 'package:flutter/material.dart';
import 'dart:math';
class PastaGrafikCizer extends CustomPainter {
  final int okunacak;
  final int okunuyor;
  final int okundu;

  PastaGrafikCizer({required this.okunacak, required this.okunuyor, required this.okundu});

  @override
  void paint(Canvas canvas, Size size) {
    int toplam = okunacak + okunuyor + okundu;
    if (toplam == 0) return;

    double startAngle = -pi / 2;

    final paintOkunacak = Paint()..color = Colors.blue;
    final paintOkunuyor = Paint()..color = Colors.orange;
    final paintOkundu = Paint()..color = Colors.green;

    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    double sweepOkunacak = (okunacak / toplam) * 2 * pi;
    canvas.drawArc(rect, startAngle, sweepOkunacak, true, paintOkunacak);
    startAngle += sweepOkunacak;

    double sweepOkunuyor = (okunuyor / toplam) * 2 * pi;
    canvas.drawArc(rect, startAngle, sweepOkunuyor, true, paintOkunuyor);
    startAngle += sweepOkunuyor;

    double sweepOkundu = (okundu / toplam) * 2 * pi;
    canvas.drawArc(rect, startAngle, sweepOkundu, true, paintOkundu);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}