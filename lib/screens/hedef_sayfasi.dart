import 'package:flutter/material.dart';
import '../database/veritabani_yardimcisi.dart';
import '../models/modeller.dart';
class HedefSayfasi extends StatefulWidget {
  const HedefSayfasi({Key? key}) : super(key: key);

  @override
  State<HedefSayfasi> createState() => _HedefSayfasiState();
}

class _HedefSayfasiState extends State<HedefSayfasi> {
  final VeritabaniYardimcisi _dbYardimcisi = VeritabaniYardimcisi();

  int gunlukHedef = 50; // İstersen bunu da veritabanından çekilebilir yapabiliriz
  int bugunOkunan = 0;
  int bugununIndeksi = 0;
  int mevcutSeri = 0;

  // Pazartesi'den Pazar'a gerçek veritabanı sayıları buraya dolacak
  List<int> haftalikOkunanSayfalar = [0, 0, 0, 0, 0, 0, 0];
  List<bool> haftalikDurum = List.filled(7, false);
  final List<String> gunler = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  // Sayfaya her geri dönüldüğünde verilerin yenilenmesi için tetiklenebilir
  Future<void> _verileriYukle() async {
    setState(() {
      yukleniyor = true;
    });

    // Haftanın o anki gün indeksini buluyoruz (0 = Pzt, 6 = Paz)
    bugununIndeksi = DateTime.now().weekday - 1;

    try {
      // VERİTABANI SORGUSU: Veritabanından bu haftanın okuma sayılarını liste olarak alıyoruz
      // Not: Veritabanı yardımcındaki fonksiyonun ismine göre burayı düzenleyebilirsin
      List<int> dbVerileri = await _dbYardimcisi.haftalikOkumaRaporuGetir();

      if (dbVerileri.length == 7) {
        haftalikOkunanSayfalar = dbVerileri;
      }
    } catch (e) {
      debugPrint("Veritabanından haftalık veri çekilirken hata oluştu: $e");
      // Hata durumunda uygulama çökmesin diye varsayılan olarak boş liste kalır
    }

    // Bugün okunan sayfa sayısını dinamik listeden alıyoruz
    bugunOkunan = haftalikOkunanSayfalar[bugununIndeksi];

    // Haftalık görsel durum (🔥) belirleme
    for (int i = 0; i <= bugununIndeksi; i++) {
      haftalikDurum[i] = haftalikOkunanSayfalar[i] >= gunlukHedef;
    }

    // DİNAMİK SERİ HESAPLAMA: Bugünden geriye doğru giderek hedefin tuttuğu ardışık günleri sayıyoruz
    mevcutSeri = 0;
    for (int i = bugununIndeksi; i >= 0; i--) {
      if (haftalikOkunanSayfalar[i] >= gunlukHedef) {
        mevcutSeri++;
      } else {
        // Eğer bugünden geriye doğru giderken herhangi bir gün hedef (50 sayfa) yakalanamadıysa seri kesilir!
        break;
      }
    }

    setState(() {
      yukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = gunlukHedef > 0 ? (bugunOkunan / gunlukHedef) : 0.0;
    if (progress > 1.0) progress = 1.0;
    bool hedefTamamlandi = bugunOkunan >= gunlukHedef;

    return Scaffold(
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _verileriYukle,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Günlük Sayfa Hedefi",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 15,
                        backgroundColor: Colors.grey.shade300,
                        color: hedefTamamlandi ? Colors.green : Colors.blue,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$bugunOkunan / $gunlukHedef",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: hedefTamamlandi ? Colors.green : Colors.black87,
                          ),
                        ),
                        const Text(
                          "Sayfa",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (hedefTamamlandi)
                  const Text(
                    "🎉 Harika, bugünkü hedefini tamamladın!",
                    style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                  ),

                const SizedBox(height: 40),
                const Divider(thickness: 1.5),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Haftalık Okuma Serisi",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "🔥 $mevcutSeri Gün",
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    bool okuduMu = haftalikDurum[index];
                    bool gecmisVeyaBugun = index <= bugununIndeksi;

                    return Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: okuduMu ? Colors.orange.shade100 : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: okuduMu
                                  ? Colors.orange
                                  : (gecmisVeyaBugun ? Colors.grey.shade400 : Colors.grey.shade200),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              okuduMu ? "🔥" : "",
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gunler[index],
                          style: TextStyle(
                            fontWeight: okuduMu ? FontWeight.bold : FontWeight.normal,
                            color: okuduMu
                                ? Colors.black87
                                : (gecmisVeyaBugun ? Colors.black54 : Colors.grey.shade400),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}