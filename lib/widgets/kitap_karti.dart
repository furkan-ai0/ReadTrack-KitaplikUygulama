import 'package:flutter/material.dart';
import '../models/modeller.dart';
class KitapKarti extends StatelessWidget {
  final Kitap kitap;
  final VoidCallback onNotEkle;
  final VoidCallback onFavoriDegis;
  final VoidCallback onSil;
  final VoidCallback onIclerGuncelle;

  const KitapKarti({
    super.key,
    required this.kitap,
    required this.onNotEkle,
    required this.onFavoriDegis,
    required this.onSil,
    required this.onIclerGuncelle,
  });

  @override
  Widget build(BuildContext context) {
    double yuzde = kitap.sayfaSayisi > 0 ? (kitap.okunanSayfa / kitap.sayfaSayisi) : 0.0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(kitap.ad, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${kitap.yazar} - %${(yuzde * 100).toStringAsFixed(0)} (${kitap.durum})"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kitap.durum != "Okundu")
              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: onIclerGuncelle),
            IconButton(icon: const Icon(Icons.note_add, color: Colors.amber), onPressed: onNotEkle),
            IconButton(
              icon: Icon(kitap.favoriMi ? Icons.favorite : Icons.favorite_border, color: Colors.red),
              onPressed: onFavoriDegis,
            ),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onSil),
          ],
        ),
      ),
    );
  }
}