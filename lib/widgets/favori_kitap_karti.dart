import 'package:flutter/material.dart';
import '../models/modeller.dart';
class FavoriKitapKarti extends StatefulWidget {
  final Kitap kitap;
  const FavoriKitapKarti({super.key, required this.kitap});

  @override
  State<FavoriKitapKarti> createState() => _FavoriKitapKartiState();
}

class _FavoriKitapKartiState extends State<FavoriKitapKarti> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    double yuzde = widget.kitap.sayfaSayisi > 0
        ? (widget.kitap.okunanSayfa / widget.kitap.sayfaSayisi) * 100
        : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.kitap.ad,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "%${yuzde.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              Text("Yazar: ${widget.kitap.yazar.isEmpty ? 'Bilinmiyor' : widget.kitap.yazar}"),
              Text("Mevcut Durum: ${widget.kitap.durum}"),
              Text("Okunan Sayfa: ${widget.kitap.okunanSayfa} / ${widget.kitap.sayfaSayisi}"),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: widget.kitap.sayfaSayisi > 0 ? widget.kitap.okunanSayfa / widget.kitap.sayfaSayisi : 0,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueGrey),
              ),
            ]
          ],
        ),
      ),
    );
  }
}