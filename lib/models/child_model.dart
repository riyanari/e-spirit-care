import 'package:equatable/equatable.dart';

class ChildModel extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final String username;
  final String password;
  final String umur;
  final String jenisKelamin;   // 👈 NEW
  final String pendidikan;
  final String role;

  // 20 Pertanyaan - diubah dari bool ke String
  final String doaSederhana;
  final String rutinMurottal;
  final String dikenalkanShalat;
  final String ceritaIslami;
  final String doaPerlindungan;
  final String pahamSakitUjian;
  final String hafalSuratPendek;
  final String tahuRukunIman;
  final String tahuRukunIslam;
  final String sopanSantun;
  final String jujurDalamBerkata;
  final String menghormatiOrtu;
  final String berbagiDenganSaudara;
  final String menjagaKebersihan;
  final String disiplinWaktu;
  final String menghafalDoaHarian;
  final String mengucapSalam;
  final String membacaBismillah;
  final String bersyukur;
  final String sabarMenghadapiMasalah;

  final List<String> harapan;
  final int totalSkor;
  final String kategori;

  const ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.username,
    required this.password,
    required this.umur,
    required this.jenisKelamin,      // 👈 NEW
    required this.pendidikan,
    required this.doaSederhana,
    required this.rutinMurottal,
    required this.dikenalkanShalat,
    required this.ceritaIslami,
    required this.doaPerlindungan,
    required this.pahamSakitUjian,
    required this.hafalSuratPendek,
    required this.tahuRukunIman,
    required this.tahuRukunIslam,
    required this.sopanSantun,
    required this.jujurDalamBerkata,
    required this.menghormatiOrtu,
    required this.berbagiDenganSaudara,
    required this.menjagaKebersihan,
    required this.disiplinWaktu,
    required this.menghafalDoaHarian,
    required this.mengucapSalam,
    required this.membacaBismillah,
    required this.bersyukur,
    required this.sabarMenghadapiMasalah,
    required this.harapan,
    required this.totalSkor,
    required this.kategori,
    this.role = 'child',
  });

  ChildModel copyWith({
    String? id,
    String? parentId,
    String? name,
    String? username,
    String? password,
    String? umur,
    String? jenisKelamin,     // 👈 NEW
    String? pendidikan,
    String? doaSederhana,
    String? rutinMurottal,
    String? dikenalkanShalat,
    String? ceritaIslami,
    String? doaPerlindungan,
    String? pahamSakitUjian,
    String? hafalSuratPendek,
    String? tahuRukunIman,
    String? tahuRukunIslam,
    String? sopanSantun,
    String? jujurDalamBerkata,
    String? menghormatiOrtu,
    String? berbagiDenganSaudara,
    String? menjagaKebersihan,
    String? disiplinWaktu,
    String? menghafalDoaHarian,
    String? mengucapSalam,
    String? membacaBismillah,
    String? bersyukur,
    String? sabarMenghadapiMasalah,
    List<String>? harapan,
    int? totalSkor,
    String? kategori,
    String? role,
  }) {
    return ChildModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      umur: umur ?? this.umur,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,  // 👈 NEW
      pendidikan: pendidikan ?? this.pendidikan,
      doaSederhana: doaSederhana ?? this.doaSederhana,
      rutinMurottal: rutinMurottal ?? this.rutinMurottal,
      dikenalkanShalat: dikenalkanShalat ?? this.dikenalkanShalat,
      ceritaIslami: ceritaIslami ?? this.ceritaIslami,
      doaPerlindungan: doaPerlindungan ?? this.doaPerlindungan,
      pahamSakitUjian: pahamSakitUjian ?? this.pahamSakitUjian,
      hafalSuratPendek: hafalSuratPendek ?? this.hafalSuratPendek,
      tahuRukunIman: tahuRukunIman ?? this.tahuRukunIman,
      tahuRukunIslam: tahuRukunIslam ?? this.tahuRukunIslam,
      sopanSantun: sopanSantun ?? this.sopanSantun,
      jujurDalamBerkata: jujurDalamBerkata ?? this.jujurDalamBerkata,
      menghormatiOrtu: menghormatiOrtu ?? this.menghormatiOrtu,
      berbagiDenganSaudara: berbagiDenganSaudara ?? this.berbagiDenganSaudara,
      menjagaKebersihan: menjagaKebersihan ?? this.menjagaKebersihan,
      disiplinWaktu: disiplinWaktu ?? this.disiplinWaktu,
      menghafalDoaHarian: menghafalDoaHarian ?? this.menghafalDoaHarian,
      mengucapSalam: mengucapSalam ?? this.mengucapSalam,
      membacaBismillah: membacaBismillah ?? this.membacaBismillah,
      bersyukur: bersyukur ?? this.bersyukur,
      sabarMenghadapiMasalah: sabarMenghadapiMasalah ?? this.sabarMenghadapiMasalah,
      harapan: harapan ?? this.harapan,
      totalSkor: totalSkor ?? this.totalSkor,
      kategori: kategori ?? this.kategori,
      role: role ?? this.role,
    );
  }

  factory ChildModel.fromJson(String id, Map<String, dynamic> json) {
    return ChildModel(
      id: id,
      parentId: json['parentId'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      umur: json['umur'] ?? '',
      jenisKelamin: json['jenisKelamin'] ?? '',   // 👈 NEW
      pendidikan: json['pendidikan'] ?? '',
      // 20 pertanyaan
      doaSederhana: json['doaSederhana'] ?? '',
      rutinMurottal: json['rutinMurottal'] ?? '',
      dikenalkanShalat: json['dikenalkanShalat'] ?? '',
      ceritaIslami: json['ceritaIslami'] ?? '',
      doaPerlindungan: json['doaPerlindungan'] ?? '',
      pahamSakitUjian: json['pahamSakitUjian'] ?? '',
      hafalSuratPendek: json['hafalSuratPendek'] ?? '',
      tahuRukunIman: json['tahuRukunIman'] ?? '',
      tahuRukunIslam: json['tahuRukunIslam'] ?? '',
      sopanSantun: json['sopanSantun'] ?? '',
      jujurDalamBerkata: json['jujurDalamBerkata'] ?? '',
      menghormatiOrtu: json['menghormatiOrtu'] ?? '',
      berbagiDenganSaudara: json['berbagiDenganSaudara'] ?? '',
      menjagaKebersihan: json['menjagaKebersihan'] ?? '',
      disiplinWaktu: json['disiplinWaktu'] ?? '',
      menghafalDoaHarian: json['menghafalDoaHarian'] ?? '',
      mengucapSalam: json['mengucapSalam'] ?? '',
      membacaBismillah: json['membacaBismillah'] ?? '',
      bersyukur: json['bersyukur'] ?? '',
      sabarMenghadapiMasalah: json['sabarMenghadapiMasalah'] ?? '',
      harapan: List<String>.from(json['harapan'] ?? []),
      totalSkor: json['totalSkor'] ?? 0,
      kategori: json['kategori'] ?? 'Rendah',
      role: json['role'] ?? 'child',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentId': parentId,
      'name': name,
      'username': username,
      'password': password,
      'umur': umur,
      'jenisKelamin': jenisKelamin,    // 👈 NEW
      'pendidikan': pendidikan,
      // 20 pertanyaan
      'doaSederhana': doaSederhana,
      'rutinMurottal': rutinMurottal,
      'dikenalkanShalat': dikenalkanShalat,
      'ceritaIslami': ceritaIslami,
      'doaPerlindungan': doaPerlindungan,
      'pahamSakitUjian': pahamSakitUjian,
      'hafalSuratPendek': hafalSuratPendek,
      'tahuRukunIman': tahuRukunIman,
      'tahuRukunIslam': tahuRukunIslam,
      'sopanSantun': sopanSantun,
      'jujurDalamBerkata': jujurDalamBerkata,
      'menghormatiOrtu': menghormatiOrtu,
      'berbagiDenganSaudara': berbagiDenganSaudara,
      'menjagaKebersihan': menjagaKebersihan,
      'disiplinWaktu': disiplinWaktu,
      'menghafalDoaHarian': menghafalDoaHarian,
      'mengucapSalam': mengucapSalam,
      'membacaBismillah': membacaBismillah,
      'bersyukur': bersyukur,
      'sabarMenghadapiMasalah': sabarMenghadapiMasalah,
      'harapan': harapan,
      'totalSkor': totalSkor,
      'kategori': kategori,
      'role': role,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Method untuk menghitung skor berdasarkan 20 jawaban
  int calculateScore() {
    int score = 0;

    // Mapping 20 jawaban ke skor
    score += _getScoreForAnswer(doaSederhana);
    score += _getScoreForAnswer(rutinMurottal);
    score += _getScoreForAnswer(dikenalkanShalat);
    score += _getScoreForAnswer(ceritaIslami);
    score += _getScoreForAnswer(doaPerlindungan);
    score += _getScoreForAnswer(pahamSakitUjian);
    score += _getScoreForAnswer(hafalSuratPendek);
    score += _getScoreForAnswer(tahuRukunIman);
    score += _getScoreForAnswer(tahuRukunIslam);
    score += _getScoreForAnswer(sopanSantun);
    score += _getScoreForAnswer(jujurDalamBerkata);
    score += _getScoreForAnswer(menghormatiOrtu);
    score += _getScoreForAnswer(berbagiDenganSaudara);
    score += _getScoreForAnswer(menjagaKebersihan);
    score += _getScoreForAnswer(disiplinWaktu);
    score += _getScoreForAnswer(menghafalDoaHarian);
    score += _getScoreForAnswer(mengucapSalam);
    score += _getScoreForAnswer(membacaBismillah);
    score += _getScoreForAnswer(bersyukur);
    score += _getScoreForAnswer(sabarMenghadapiMasalah);

    return score;
  }

  int _getScoreForAnswer(String answer) {
    switch (answer.toLowerCase()) {
      case 'ya':
      case 'rutin':
      case 'selalu':
        return 5;
      case 'kadang':
      case 'pernah':
        return 3;
      case 'tidak':
      case 'belum':
      case 'tidak pernah':
        return 0;
      default:
        return 0;
    }
  }

  // Method untuk menentukan kategori berdasarkan skor (maksimal 100 poin)
  String determineCategory(int score) {
    if (score > 80) return 'Tinggi';
    if (score > 60) return 'Sedang';
    return 'Rendah';
  }

  @override
  List<Object?> get props => [
    id,
    parentId,
    name,
    username,
    password,
    umur,
    jenisKelamin,      // 👈 NEW
    pendidikan,
    doaSederhana,
    rutinMurottal,
    dikenalkanShalat,
    ceritaIslami,
    doaPerlindungan,
    pahamSakitUjian,
    hafalSuratPendek,
    tahuRukunIman,
    tahuRukunIslam,
    sopanSantun,
    jujurDalamBerkata,
    menghormatiOrtu,
    berbagiDenganSaudara,
    menjagaKebersihan,
    disiplinWaktu,
    menghafalDoaHarian,
    mengucapSalam,
    membacaBismillah,
    bersyukur,
    sabarMenghadapiMasalah,
    harapan,
    totalSkor,
    kategori,
  ];
}