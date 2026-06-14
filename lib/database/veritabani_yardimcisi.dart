import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/modeller.dart';

class VeritabaniYardimcisi {
  static final VeritabaniYardimcisi _instance = VeritabaniYardimcisi._internal();
  factory VeritabaniYardimcisi() => _instance;
  VeritabaniYardimcisi._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String veritabaniYolu = p.join(await getDatabasesPath(), 'kitaplik_projesi.db');

    return await openDatabase(
      veritabaniYolu,
      version: 2,
      onCreate: (db, version) async {
        await _tablolariOlustur(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Tablo varsa çökmesini engellemek için IF NOT EXISTS ekledik
          await db.execute('''
            CREATE TABLE IF NOT EXISTS kullanicilar (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              kullanici_adi TEXT UNIQUE,
              sifre TEXT
            )
          ''');
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _tablolariOlustur(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS kullanicilar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kullanici_adi TEXT UNIQUE,
        sifre TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS kitaplar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad TEXT NOT NULL,
        yazar TEXT,
        sayfa_sayisi INTEGER NOT NULL,
        okunan_sayfa INTEGER NOT NULL,
        favori_mi INTEGER NOT NULL,
        durum TEXT NOT NULL,
        eklenme_tarihi TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kitap_id INTEGER NOT NULL,
        not_icerigi TEXT NOT NULL,
        eklenme_tarihi TEXT NOT NULL,
        FOREIGN KEY (kitap_id) REFERENCES kitaplar (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS okuma_gecmisi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kitap_id INTEGER NOT NULL,
        okunan_sayfa_sayisi INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        FOREIGN KEY (kitap_id) REFERENCES kitaplar (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- KULLANICI GİRİŞ VE KAYIT FONKSİYONLARI ---

  Future<bool> kullaniciKaydet(String kullaniciAdi, String sifre) async {
    final db = await database;
    try {
      await db.insert('kullanicilar', {'kullanici_adi': kullaniciAdi, 'sifre': sifre});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> kullaniciGirisYap(String kullaniciAdi, String sifre) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> sonuc = await db.query(
        'kullanicilar',
        where: 'kullanici_adi = ? AND sifre = ?',
        whereArgs: [kullaniciAdi, sifre],
      );
      return sonuc.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // --- ŞİFRE GÜNCELLEME FONKSİYONU ---

  Future<bool> sifreGuncelle(String kullaniciAdi, String yeniSifre) async {
    final db = await database;
    try {
      int guncellenenSatir = await db.update(
        'kullanicilar',
        {'sifre': yeniSifre},
        where: 'kullanici_adi = ?',
        whereArgs: [kullaniciAdi],
      );
      return guncellenenSatir > 0;
    } catch (e) {
      return false;
    }
  }

  // --- KİTAP VE NOT FONKSİYONLARI ---

  Future<int> kitapEkle(Kitap kitap) async {
    final db = await database;
    return await db.insert('kitaplar', kitap.toMap());
  }

  Future<List<Kitap>> kitaplariGetir() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('kitaplar');
    return List.generate(maps.length, (i) => Kitap.fromMap(maps[i]));
  }

  Future<int> kitapGuncelle(Kitap kitap) async {
    final db = await database;
    return await db.update('kitaplar', kitap.toMap(), where: 'id = ?', whereArgs: [kitap.id]);
  }

  Future<int> kitapSil(int id) async {
    final db = await database;
    return await db.delete('kitaplar', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> notEkle(KitapNotu not) async {
    final db = await database;
    return await db.insert('notlar', not.toMap());
  }

  Future<List<KitapNotu>> kitapNotlariniGetir(int kitapId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notlar', where: 'kitap_id = ?', whereArgs: [kitapId]);
    return List.generate(maps.length, (i) => KitapNotu.fromMap(maps[i]));
  }

  Future<List<KitapNotu>> tumNotleriGetir() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notlar');
    return List.generate(maps.length, (i) => KitapNotu.fromMap(maps[i]));
  }

  // --- OKUMA GEÇMİŞİ FONKSİYONLARI ---

  Future<int> logEkle(OkumaLog log) async {
    final db = await database;
    return await db.insert('okuma_gecmisi', log.toMap());
  }

  Future<List<OkumaLog>> sonHaftaninLoglariniGetir() async {
    final db = await database;
    DateTime yediGunOnce = DateTime.now().subtract(const Duration(days: 7));
    final List<Map<String, dynamic>> maps = await db.query(
      'okuma_gecmisi',
      where: 'tarih >= ?',
      whereArgs: [yediGunOnce.toIso8601String()],
    );
    return List.generate(maps.length, (i) => OkumaLog.fromMap(maps[i]));
  }

  // --- İSTATİSTİKLER VE HAFTALIK RAPOR SORGUSU ---

  Future<List<int>> haftalikOkumaRaporuGetir() async {
    final db = await database;
    List<int> haftalikRapor = [0, 0, 0, 0, 0, 0, 0];

    // CRITICAL BUG FIX: UTC saat kaymasını engellemek için 'localtime' filtresi eklendi!
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT strftime('%w', tarih) as gun_indeksi, SUM(okunan_sayfa_sayisi) as toplam_sayfa 
      FROM okuma_gecmisi 
      WHERE date(tarih) >= date('now', 'localtime', 'weekday 0', '-6 days')
      GROUP BY gun_indeksi
    ''');

    for (var row in maps) {
      if (row['gun_indeksi'] == null || row['toplam_sayfa'] == null) continue;

      int sqliteGun = int.parse(row['gun_indeksi'].toString());
      int toplamSayfa = int.parse(row['toplam_sayfa'].toString());

      // SQLite (0=Pazar, 1=Pzt...) -> Flutter (0=Pzt, 6=Paz) dönüşümü
      int flutterIndex = (sqliteGun == 0) ? 6 : sqliteGun - 1;

      if (flutterIndex >= 0 && flutterIndex < 7) {
        haftalikRapor[flutterIndex] = toplamSayfa;
      }
    }

    return haftalikRapor;
  }
}