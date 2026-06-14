import 'package:flutter/material.dart';
import 'dart:math' show max; // max fonksiyonunu net olarak içeri aldık
import '../models/modeller.dart';

class HaftalikGrafikCizer extends CustomPainter {
  final List<OkumaLog> loglar;
  HaftalikGrafikCizer({required this.loglar});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBar = Paint()
      ..color = Colors.blueGrey.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final paintLine = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    double chartHeight = size.height - 20;

    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), paintLine);

    double barWidth = size.width / 7 - 8;

    List<int> sayfaVerileri = List.filled(7, 0);
    for (int i = 0; i < loglar.length && i < 7; i++) {
      sayfaVerileri[i] = loglar[i].okunanSayfaSayisi;
    }

    int maxSayfa = sayfaVerileri.isEmpty ? 1 : sayfaVerileri.reduce(max);
    if (maxSayfa == 0) maxSayfa = 1;

    for (int i = 0; i < 7; i++) {
      double left = i * (size.width / 7) + 4;

      double height = (sayfaVerileri[i] / maxSayfa) * (chartHeight * 0.8);
      if (height < 5 && sayfaVerileri[i] > 0) height = 5;

      canvas.drawRect(Rect.fromLTWH(left, chartHeight - height, barWidth, height), paintBar);

      TextPainter tp = TextPainter(
        text: TextSpan(
          text: sayfaVerileri[i].toString(),
          style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      double textX = left + (barWidth / 2) - (tp.width / 2);
      double textY = chartHeight + 4;
      tp.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}