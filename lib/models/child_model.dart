import 'package:equatable/equatable.dart';

class ChildModel extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final String username;
  final String password;
  final String umur;
  final String jenisKelamin;
  final String pendidikan;
  final String role;

  /// Semua jawaban kuesioner:
  /// contoh:
  /// 'pertanyaan1' -> 'Teks jawaban utama'
  /// 'pertanyaan12' -> 'Tidak yakin'
  /// 'pertanyaan12_detail' -> 'Karena ...'
  /// plus:
  /// 'hifz_an_nafs_score', 'hifz_an_nafs_category', 'hifz_an_nafs_video', dst.
  final Map<String, String> pertanyaan;

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
    required this.jenisKelamin,
    required this.pendidikan,
    required this.pertanyaan,
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
    String? jenisKelamin,
    String? pendidikan,
    Map<String, String>? pertanyaan,
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
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      pendidikan: pendidikan ?? this.pendidikan,
      pertanyaan: pertanyaan ?? this.pertanyaan,
      harapan: harapan ?? this.harapan,
      totalSkor: totalSkor ?? this.totalSkor,
      kategori: kategori ?? this.kategori,
      role: role ?? this.role,
    );
  }

  factory ChildModel.fromJson(String id, Map<String, dynamic> json) {
    final rawPertanyaan = json['pertanyaan'];
    Map<String, String> p = {};
    if (rawPertanyaan is Map<String, dynamic>) {
      p = rawPertanyaan.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
    }

    return ChildModel(
      id: id,
      parentId: json['parentId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      umur: json['umur']?.toString() ?? '',
      jenisKelamin: json['jenisKelamin']?.toString() ?? '',
      pendidikan: json['pendidikan']?.toString() ?? '',
      pertanyaan: p,
      harapan: (json['harapan'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      totalSkor: (json['totalSkor'] ?? 0) is int
          ? json['totalSkor'] as int
          : int.tryParse(json['totalSkor'].toString()) ?? 0,
      kategori: json['kategori']?.toString() ?? 'Rendah',
      role: json['role']?.toString() ?? 'child',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentId': parentId,
      'name': name,
      'username': username,
      'password': password,
      'umur': umur,
      'jenisKelamin': jenisKelamin,
      'pendidikan': pendidikan,
      'pertanyaan': pertanyaan,
      'harapan': harapan,
      'totalSkor': totalSkor,
      'kategori': kategori,
      'role': role,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // =========================
  // HIFZ getters (dari pertanyaan)
  // =========================

  int _intFromPertanyaan(String key) {
    return int.tryParse(pertanyaan[key] ?? '0') ?? 0;
  }

  String _stringFromPertanyaan(String key, String defaultValue) {
    return pertanyaan[key] ?? defaultValue;
  }

  // Hifz An-Nafs
  int get hifzAnNafsScore => _intFromPertanyaan('hifz_an_nafs_score');
  String get hifzAnNafsCategory =>
      _stringFromPertanyaan('hifz_an_nafs_category', 'Aman / risiko minimal');
  String get hifzAnNafsVideo =>
      _stringFromPertanyaan('hifz_an_nafs_video', '');

  // Hifz Ad-Diin
  int get hifzAdDiinScore => _intFromPertanyaan('hifz_ad_diin_score');
  String get hifzAdDiinCategory =>
      _stringFromPertanyaan('hifz_ad_diin_category', 'Kesejahteraan Spiritual');
  String get hifzAdDiinVideo =>
      _stringFromPertanyaan('hifz_ad_diin_video', '');

  // Hifz Al-Aql
  int get hifzAlAqlScore => _intFromPertanyaan('hifz_al_aql_score');
  String get hifzAlAqlCategory =>
      _stringFromPertanyaan('hifz_al_aql_category', 'Perkembangan baik');
  String get hifzAlAqlVideo =>
      _stringFromPertanyaan('hifz_al_aql_video', '');

  // Hifz An-Nasl
  int get hifzAnNaslScore => _intFromPertanyaan('hifz_an_nasl_score');
  String get hifzAnNaslCategory =>
      _stringFromPertanyaan('hifz_an_nasl_category', 'Pola asuh baik');
  String get hifzAnNaslVideo =>
      _stringFromPertanyaan('hifz_an_nasl_video', '');

  // Hifz Al-Mal
  int get hifzAlMalScore => _intFromPertanyaan('hifz_al_mal_score');
  String get hifzAlMalCategory =>
      _stringFromPertanyaan('hifz_al_mal_category', 'Kecukupan ekonomi baik');
  String get hifzAlMalVideo =>
      _stringFromPertanyaan('hifz_al_mal_video', '');

  /// (Opsional) total skor HIFZ gabungan
  int get totalHifzScore =>
      hifzAnNafsScore +
          hifzAdDiinScore +
          hifzAlAqlScore +
          hifzAnNaslScore +
          hifzAlMalScore;

  /// Hitung skor dari semua jawaban utama (key tanpa suffix `_detail`)
  /// NOTE: ini generic, tidak pakai logika HIFZ di AddChildPage
  int calculateScore() {
    int score = 0;

    pertanyaan.forEach((key, value) {
      if (!key.endsWith('_detail') && !key.startsWith('hifz_')) {
        score += _getScoreForAnswer(value);
      }
    });

    return score;
  }

  int _getScoreForAnswer(String answer) {
    final a = answer.toLowerCase().trim();

    // Jawaban sangat positif
    if (a.startsWith('ya') ||
        a.contains('yakin') ||
        a.contains('mengetahui') ||
        a.contains('tahu') ||
        a.contains('mandiri') ||
        a.contains('mampu') ||
        a.contains('tercukupi') ||
        a.contains('ketetapan dari allah') ||
        a.contains('ke pelayanan kesehatan') ||
        a.contains('jalan allah')) {
      return 5;
    }

    // Jawaban sedang
    if (a.contains('kadang') ||
        a.contains('sebagian') ||
        a.contains('pernah')) {
      return 3;
    }

    // Jawaban negatif
    if (a.contains('tidak') || a.contains('belum')) {
      return 0;
    }

    // default
    return 0;
  }

  String determineCategory(int score) {
    if (score >= 80) return 'Tinggi';
    if (score >= 60) return 'Sedang';
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
    jenisKelamin,
    pendidikan,
    pertanyaan,
    harapan,
    totalSkor,
    kategori,
    role,
  ];
}
