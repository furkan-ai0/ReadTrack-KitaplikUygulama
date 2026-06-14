import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' show Random; // Sadece rastgele alıntı seçimi için kütüphane eklendi
import 'package:shared_preferences/shared_preferences.dart';

// Veritabanı ve Model importları
import '../database/veritabani_yardimcisi.dart';
import '../models/modeller.dart';

// Diğer Ekranlar
import 'hedef_sayfasi.dart';
import 'giris_ekrani.dart';

// widgets klasörüne taşıdığımız görsel bileşenlerin importları (Kritik Bölge!)
import '../widgets/kitap_karti.dart';
import '../widgets/favori_kitap_karti.dart';
import '../widgets/pasta_grafik_cizer.dart';

// Uygulamanın temasını main.dart'tan dinlemek için global çağrı importu
import '../main.dart' show themeNotifier;

// ==========================================
// 3. ANA SAYFA VE REAKTİF YÖNETİM
// ==========================================
class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _seciliSekme = 0;
  List<Kitap> _kitaplar = [];
  List<KitapNotu> _tumNotlar = [];
  String _aramaMetni = "";
  String _siralamaTuru = "En Yeni";
  String _aktifKullaniciAdi = "Yükleniyor...";
  String _rastgeleAlinti = "Notlarınız burada parlayacak...";

  final VeritabaniYardimcisi _db = VeritabaniYardimcisi();

  @override
  void initState() {
    super.initState();
    _verileriYukle();
    _kullaniciAdiYukle();
  }

  Future<void> _kullaniciAdiYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aktifKullaniciAdi = prefs.getString("aktif_kullanici_adi") ?? "Bilgisayar Mühendisi";
    });
  }

  Future<void> _verileriYukle() async {
    try {
      final kitapListesi = await _db.kitaplariGetir();
      final notListesi = await _db.tumNotleriGetir();
      setState(() {
        _kitaplar = kitapListesi;
        _tumNotlar = notListesi;
        _alintiSec();
      });
    } catch (e) {
      _hataMesajiGoster("Veritabanından veriler yüklenirken bir sorun oluştu.");
    }
  }

  void _alintiSec() {
    if (_tumNotlar.isNotEmpty) {
      final rand = Random();
      setState(() {
        _rastgeleAlinti = _tumNotlar[rand.nextInt(_tumNotlar.length)].notIcerigi;
      });
    } else {
      setState(() {
        _rastgeleAlinti = "Kitaplarınıza eklediğiniz önemli notlar rastgele burada gösterilecektir.";
      });
    }
  }

  void _hataMesajiGoster(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.redAccent));
  }

  void _kitapEkleDialog() {
    final TextEditingController adController = TextEditingController();
    final TextEditingController yazarController = TextEditingController();
    final TextEditingController sayfaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Kitap Ekle"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: adController,
                  decoration: const InputDecoration(labelText: "Kitap Adı *"),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Kitap adı boş bırakılamaz!" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: yazarController,
                  decoration: const InputDecoration(labelText: "Yazar Adı"),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty && double.tryParse(v.trim()) != null) {
                      return "Yazar adı sayı içeremez!Tekrar girin.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: sayfaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: "Toplam Sayfa"),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      int? girilenSayfa = int.tryParse(v.trim());
                      if (girilenSayfa == 0) {
                        return "Sayfa sayısı 0 olamaz!";
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  Kitap yeni = Kitap(
                    ad: adController.text.trim(),
                    yazar: yazarController.text.trim(),
                    sayfaSayisi: int.tryParse(sayfaController.text) ?? 0,
                    durum: "Okunacak",
                  );
                  await _db.kitapEkle(yeni);
                  if (context.mounted) Navigator.pop(context);
                  _verileriYukle();
                } catch (e) {
                  _hataMesajiGoster("Kitap kaydedilirken teknik bir hata oluştu.");
                }
              }
            },
            child: const Text("Ekle"),
          )
        ],
      ),
    );
  }

  void _notYonetimDialog(Kitap kitap) async {
    final List<KitapNotu> notlar = await _db.kitapNotlariniGetir(kitap.id!);
    final TextEditingController yeniNotController = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("${kitap.ad} - Notları"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: notlar.isEmpty
                      ? const Center(child: Text("Henüz not eklenmemiş."))
                      : ListView.builder(
                    itemCount: notlar.length,
                    itemBuilder: (c, i) => ListTile(
                      title: Text(notlar[i].notIcerigi),
                      subtitle: Text(notlar[i].eklenmeTarihi.toString().substring(0, 10)),
                      leading: const Icon(Icons.bookmark, color: Colors.amber),
                    ),
                  ),
                ),
                const Divider(),
                TextField(
                  controller: yeniNotController,
                  decoration: const InputDecoration(hintText: "Yeni not veya alıntı yazın..."),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
            ElevatedButton(
              onPressed: () async {
                if (yeniNotController.text.trim().isNotEmpty) {
                  KitapNotu yeniNot = KitapNotu(kitapId: kitap.id!, notIcerigi: yeniNotController.text.trim());
                  await _db.notEkle(yeniNot);
                  yeniNotController.clear();
                  final yenilenenler = await _db.kitapNotlariniGetir(kitap.id!);
                  setDialogState(() {
                    notlar.clear();
                    notlar.addAll(yenilenenler);
                  });
                  _verileriYukle();
                }
              },
              child: const Text("Ekle"),
            )
          ],
        ),
      ),
    );
  }

  void _ilerlemeGuncelleDialog(Kitap kitap) {
    final TextEditingController sayfaKontrol = TextEditingController(
      text: kitap.okunanSayfa > 0 ? kitap.okunanSayfa.toString() : "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Okuma Durumu Güncelle (${kitap.sayfaSayisi} Sayfa)"),
        content: TextField(
          controller: sayfaKontrol,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: "Şu an gelinen sayfa sayısı"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              String metin = sayfaKontrol.text.trim();

              if (metin.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Sayfa sayısı bilinmiyor! Lütfen bir değer girin."),
                      backgroundColor: Colors.red
                  ),
                );
                return;
              }

              int? girilen = int.tryParse(metin);

              if (girilen == null || girilen <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Sayfa sayısı 0 olamaz!"),
                      backgroundColor: Colors.red
                  ),
                );
                return;
              }

              if (kitap.sayfaSayisi > 0 && girilen > kitap.sayfaSayisi) {
                girilen = kitap.sayfaSayisi;
              }

              int fark = girilen - kitap.okunanSayfa;
              if (fark > 0) {
                await _db.logEkle(OkumaLog(kitapId: kitap.id!, okunanSayfaSayisi: fark));
              }

              kitap.okunanSayfa = girilen;
              if (kitap.sayfaSayisi > 0 && girilen == kitap.sayfaSayisi) {
                kitap.durum = "Okundu";
              } else {
                kitap.durum = "Okunuyor";
              }

              await _db.kitapGuncelle(kitap);
              if (context.mounted) Navigator.pop(context);
              _verileriYukle();
            },
            child: const Text("Güncelle"),
          )
        ],
      ),
    );
  }

  void _kitapSilOnayDialog(Kitap kitap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text("Eylemi Onayla")],
        ),
        content: Text("\"${kitap.ad}\" kitabını ve buna bağlı eklenmiş tüm özel notları/okuma geçmişini kalıcı olarak silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _db.kitapSil(kitap.id!);
                Navigator.pop(context);
                _verileriYukle();
              } catch (e) {
                _hataMesajiGoster("Silme işlemi esnasında hata meydana geldi.");
              }
            },
            child: const Text("Evet, Sil"),
          )
        ],
      ),
    );
  }

  Widget _buildKitaplikSekmesi(List<Kitap> liste) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blueGrey[400]!, Colors.blueGrey[700]!]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [Icon(Icons.format_quote, color: Colors.white70), SizedBox(width: 5), Text("Alıntılardan ...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
              ),
              const SizedBox(height: 8),
              Text("\"$_rastgeleAlinti\"", style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Kitap Ara...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => setState(() => _aramaMetni = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _siralamaTuru,
                icon: const Icon(Icons.sort, color: Colors.blueGrey),
                onChanged: (String? n) => {if (n != null) setState(() => _siralamaTuru = n)},
                items: <String>['En Yeni', "A'dan Z'ye", 'Sayfa Sayısı'].map<DropdownMenuItem<String>>((String v) {
                  return DropdownMenuItem<String>(value: v, child: Text(v));
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: liste.isEmpty
              ? const Center(child: Text("Kitaplığınızda kriterlere uygun veri bulunamadı."))
              : ListView.builder(
            itemCount: liste.length,
            itemBuilder: (context, index) {
              return KitapKarti(
                kitap: liste[index],
                onNotEkle: () => _notYonetimDialog(liste[index]),
                onFavoriDegis: () async {
                  liste[index].favoriMi = !liste[index].favoriMi;
                  await _db.kitapGuncelle(liste[index]);
                  _verileriYukle();
                },
                onSil: () => _kitapSilOnayDialog(liste[index]),
                onIclerGuncelle: () => _ilerlemeGuncelleDialog(liste[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavorilerSekmesi() {
    List<Kitap> favoriler = _kitaplar.where((k) => k.favoriMi).toList();
    return favoriler.isEmpty
        ? const Center(child: Text("Henüz favori kitap eklenmemiş."))
        : ListView.builder(
      itemCount: favoriler.length,
      itemBuilder: (context, index) {
        return FavoriKitapKarti(kitap: favoriler[index]);
      },
    );
  }

  Widget _buildIstatistikSekmesi() {
    int okunacak = _kitaplar.where((k) => k.durum == "Okunacak").length;
    int okunuyor = _kitaplar.where((k) => k.durum == "Okunuyor").length;
    int okundu = _kitaplar.where((k) => k.durum == "Okundu").length;

    return FutureBuilder<List<int>>(
      future: _db.haftalikOkumaRaporuGetir(),
      builder: (context, snapshot) {
        List<int> haftalikSayfalar = snapshot.data ?? [0, 0, 0, 0, 0, 0, 0];
        int haftalikToplam = haftalikSayfalar.reduce((a, b) => a + b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              const Text("Okunma Durumu İstatistikleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (_kitaplar.isNotEmpty)
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(painter: PastaGrafikCizer(okunacak: okunacak, okunuyor: okunuyor, okundu: okundu)),
                )
              else
                const Text("Grafik verisi bulunmuyor."),
              const SizedBox(height: 25),
              _istatistikLejandSatir("Tamamlanan Kitaplar", okundu, Colors.green),
              _istatistikLejandSatir("Şu An Okunanlar", okunuyor, Colors.orange),
              _istatistikLejandSatir("Okunacak Kitaplar", okunacak, Colors.blue),
              const Divider(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Bu Hafta Okunan Toplam Sayfa",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "$haftalikToplam",
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      haftalikToplam > 0
                          ? "Harika gidiyorsun! 🚀"
                          : "Hadi, bir kitap açıp okumaya başla! 📖",
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _istatistikLejandSatir(String b, int a, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 8), Text(b)]),
          Text(a.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAyarlarSekmesi() {
    bool isDark = themeNotifier.value == ThemeMode.dark;
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.blueGrey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15)
          ),
          child: Row(
            children: [
              const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person, color: Colors.white, size: 30)
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_aktifKullaniciAdi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text("Aktif Kullanıcı Profili", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text("Koyu Tema"),
          trailing: Switch(
            value: isDark,
            onChanged: (v) {
              setState(() {
                themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
              });
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text("Şifre Değiştir"),
          onTap: _sifreDegistirDialog,
        ),
        ListTile(
          leading: const Icon(Icons.exit_to_app, color: Colors.red),
          title: const Text("Güvenli Çıkış Yap", style: TextStyle(color: Colors.red)),
          onTap: () {
            SharedPreferences.getInstance().then((prefs) {
              prefs.remove("aktif_kullanici_adi");
            });
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GirisEkrani()));
          },
        ),
      ],
    );
  }

  void _sifreDegistirDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Şifre Değiştir"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: "Yeni 6 Haneli Şifre", counterText: ""),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().length == 6) {
                String yeniSifre = controller.text.trim();
                bool basarili = await VeritabaniYardimcisi().sifreGuncelle(_aktifKullaniciAdi, yeniSifre);

                if (mounted) {
                  Navigator.pop(context);

                  if (basarili) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Şifreniz başarıyla güncellendi!"), backgroundColor: Colors.green)
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Şifre güncellenirken bir hata oluştu!"), backgroundColor: Colors.red)
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen 6 haneli bir şifre girin!"), backgroundColor: Colors.orange)
                );
              }
            },
            child: const Text("Güncelle"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Kitap> filtrelenmisKitaplar = _kitaplar.where((k) {
      return k.ad.toLowerCase().contains(_aramaMetni.toLowerCase()) ||
          k.yazar.toLowerCase().contains(_aramaMetni.toLowerCase());
    }).toList();

    if (_siralamaTuru == "En Yeni") {
      filtrelenmisKitaplar.sort((a, b) => b.eklenmeTarihi.compareTo(a.eklenmeTarihi));
    } else if (_siralamaTuru == "A'dan Z'ye") {
      filtrelenmisKitaplar.sort((a, b) => a.ad.toLowerCase().compareTo(b.ad.toLowerCase()));
    } else if (_siralamaTuru == "Sayfa Sayısı") {
      filtrelenmisKitaplar.sort((a, b) => b.sayfaSayisi.compareTo(a.sayfaSayisi));
    }

    Widget gosterilecekSekme;

    switch (_seciliSekme) {
      case 0:
        gosterilecekSekme = _buildKitaplikSekmesi(filtrelenmisKitaplar);
        break;
      case 1:
        gosterilecekSekme = _buildFavorilerSekmesi();
        break;
      case 2:
        gosterilecekSekme = _buildIstatistikSekmesi();
        break;
      case 3:
        gosterilecekSekme = const HedefSayfasi();
        break;
      case 4:
        gosterilecekSekme = _buildAyarlarSekmesi();
        break;
      default:
        gosterilecekSekme = _buildKitaplikSekmesi(filtrelenmisKitaplar);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _seciliSekme == 0 ? "Kitaplığım" :
            _seciliSekme == 1 ? "Favoriler" :
            _seciliSekme == 2 ? "İstatistikler" :
            _seciliSekme == 3 ? "Hedefler" : "Ayarlar"
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: gosterilecekSekme,
      floatingActionButton: _seciliSekme == 0
          ? FloatingActionButton(
        onPressed: _kitapEkleDialog,
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _seciliSekme,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueGrey,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _seciliSekme = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Kitaplık"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favoriler"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "İstatistik"),
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: "Hedef"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ayarlar"),
        ],
      ),
    );
  }
}