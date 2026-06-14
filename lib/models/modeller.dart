// Kanka, buradaki material.dart importunu temizledik çünkü modeller tamamen saf Dart nesneleridir.

class Kitap {
  int? id;
  String ad;
  String yazar;
  int sayfaSayisi;
  int okunanSayfa;
  bool favoriMi;
  String durum;
  DateTime eklenmeTarihi;

  Kitap({
    this.id,
    required this.ad,
    this.yazar = "",
    this.sayfaSayisi = 0,
    this.okunanSayfa = 0,
    this.favoriMi = false,
    this.durum = "Okunacak",
    DateTime? eklenmeTarihi,
  }) : eklenmeTarihi = eklenmeTarihi ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad': ad,
      'yazar': yazar,
      'sayfa_sayisi': sayfaSayisi,
      'okunan_sayfa': okunanSayfa,
      'favori_mi': favoriMi ? 1 : 0,
      'durum': durum,
      'eklenme_tarihi': eklenmeTarihi.toIso8601String(),
    };
  }

  factory Kitap.fromMap(Map<String, dynamic> map) {
    return Kitap(
      id: map['id'],
      ad: map['ad'],
      yazar: map['yazar'] ?? "",
      sayfaSayisi: map['sayfa_sayisi'] ?? 0,
      okunanSayfa: map['okunan_sayfa'] ?? 0,
      favoriMi: map['favori_mi'] == 1,
      durum: map['durum'] ?? "Okunacak",
      eklenmeTarihi: DateTime.tryParse(map['eklenme_tarihi'] ?? "") ?? DateTime.now(),
    );
  }
}

class KitapNotu {
  int? id;
  int kitapId;
  String notIcerigi;
  DateTime eklenmeTarihi;

  KitapNotu({this.id, required this.kitapId, required this.notIcerigi, DateTime? eklenmeTarihi})
      : eklenmeTarihi = eklenmeTarihi ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kitap_id': kitapId,
      'not_icerigi': notIcerigi,
      'eklenme_tarihi': eklenmeTarihi.toIso8601String(),
    };
  }

  factory KitapNotu.fromMap(Map<String, dynamic> map) {
    return KitapNotu(
      id: map['id'],
      kitapId: map['kitap_id'],
      notIcerigi: map['not_icerigi'],
      eklenmeTarihi: DateTime.tryParse(map['eklenme_tarihi'] ?? "") ?? DateTime.now(),
    );
  }
}

class OkumaLog {
  int? id;
  int kitapId;
  int okunanSayfaSayisi;
  DateTime tarih;

  OkumaLog({this.id, required this.kitapId, required this.okunanSayfaSayisi, DateTime? tarih})
      : tarih = tarih ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kitap_id': kitapId,
      'okunan_sayfa_sayisi': okunanSayfaSayisi,
      'tarih': tarih.toIso8601String(),
    };
  }

  factory OkumaLog.fromMap(Map<String, dynamic> map) {
    return OkumaLog(
      id: map['id'],
      kitapId: map['kitap_id'],
      okunanSayfaSayisi: map['okunan_sayfa_sayisi'],
      tarih: DateTime.tryParse(map['tarih'] ?? "") ?? DateTime.now(),
    );
  }
}