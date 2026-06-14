import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/veritabani_yardimcisi.dart';
import 'ana_sayfa.dart'; // Giriş başarılı olduğunda yönlendirilecek sayfa eklendi (Kritik!)

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _girisKullaniciAdi = TextEditingController();
  final TextEditingController _girisSifre = TextEditingController();

  final TextEditingController _kayitKullaniciAdi = TextEditingController();
  final TextEditingController _kayitSifre = TextEditingController();

  bool _isLoginMode = true;
  bool _sifreGizli = true;

  @override
  void dispose() {
    _girisKullaniciAdi.dispose();
    _girisSifre.dispose();
    _kayitKullaniciAdi.dispose();
    _kayitSifre.dispose();
    super.dispose();
  }

  // --- KAYIT OLMA FONKSİYONU ---
  Future<void> _kayitOl() async {
    final kAdi = _kayitKullaniciAdi.text.trim();
    final sifre = _kayitSifre.text.trim();

    if (kAdi.isEmpty || sifre.isEmpty) {
      _uyariGoster("Lütfen kullanıcı adı ve şifre alanlarını doldurun.", Colors.orange);
      return;
    }

    final basariliMi = await VeritabaniYardimcisi().kullaniciKaydet(kAdi, sifre);

    if (basariliMi) {
      _uyariGoster("Hesabınız başarıyla oluşturuldu! Giriş yapabilirsiniz.", Colors.green);
      _kayitKullaniciAdi.clear();
      _kayitSifre.clear();
      setState(() {
        _isLoginMode = true;
      });
    } else {
      _uyariGoster("Bu kullanıcı adı zaten alınmış!", Colors.redAccent);
    }
  }

  // --- GİRİŞ YAPMA FONKSİYONU ---
  Future<void> _girisYap() async {
    final kAdi = _girisKullaniciAdi.text.trim();
    final sifre = _girisSifre.text.trim();

    if (kAdi.isEmpty || sifre.isEmpty) {
      _uyariGoster("Lütfen kullanıcı adı ve şifrenizi girin.", Colors.orange);
      return;
    }

    final girisBasarili = await VeritabaniYardimcisi().kullaniciGirisYap(kAdi, sifre);

    if (girisBasarili) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("aktif_kullanici_adi", kAdi);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnaSayfa()),
        );
      }
    } else {
      _girisSifre.clear();
      _uyariGoster("Hatalı kullanıcı adı veya şifre!", Colors.redAccent);
    }
  }

  void _uyariGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: renk),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.blueGrey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories, size: 80, color: Colors.blueGrey[400]),
                const SizedBox(height: 15),
                Text(
                  _isLoginMode ? "Kitaplığa Hoş Geldin" : "Yeni Hesap Oluştur",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                    ],
                  ),
                  child: _isLoginMode ? _buildGirisFormu() : _buildKayitFormu(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGirisFormu() {
    return Column(
      children: [
        TextField(
          controller: _girisKullaniciAdi,
          decoration: const InputDecoration(
            hintText: "Kullanıcı Adı",
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _girisSifre,
          obscureText: _sifreGizli,
          decoration: InputDecoration(
            hintText: "Şifre",
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_sifreGizli ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
            ),
          ),
          onSubmitted: (_) => _girisYap(),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: _girisYap,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
          ),
          child: const Text("Giriş Yap", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _isLoginMode = false),
          child: const Text("Hesabın yok mu? Kayıt Ol"),
        )
      ],
    );
  }

  Widget _buildKayitFormu() {
    return Column(
      children: [
        TextField(
          controller: _kayitKullaniciAdi,
          decoration: const InputDecoration(
            hintText: "Yeni Kullanıcı Adı",
            prefixIcon: Icon(Icons.person_add),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _kayitSifre,
          obscureText: _sifreGizli,
          decoration: InputDecoration(
            hintText: "Yeni Şifre",
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_sifreGizli ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
            ),
          ),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: _kayitOl,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
          ),
          child: const Text("Hesap Oluştur ve Kaydet", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _isLoginMode = true),
          child: const Text("Zaten hesabın var mı? Giriş Yap"),
        ),
      ],
    );
  }
}