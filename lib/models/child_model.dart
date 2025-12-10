import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

  /// Mapping pertanyaan per aspek Hifz
  Map<String, Map<String, List<String>>> get hifzQuestionMapping {
    return {
      'an_nafs': {
        'A. Keluhan Utama': ['pertanyaan1'],
        'B. Sakit Sekarang': ['pertanyaan2'],
        'C. Riwayat Penyakit': ['pertanyaan3'],
        'D. Obat yang Pernah Dikonsumsi': ['pertanyaan4'],
        'E. Riwayat Alergi Obat': ['pertanyaan5', 'pertanyaan5_detail'],
        'F. Riwayat Alergi Makanan': ['pertanyaan6', 'pertanyaan6_detail'],
        'G1. Frekuensi Makan': ['pertanyaan7'],
        'G2. Jenis Makanan': ['pertanyaan8'],
        'G3. Porsi Makan': ['pertanyaan9'],
        'G4. Kebiasaan Makan Khusus': ['pertanyaan10', 'pertanyaan10_detail'],
        'G5. Masalah Makan': ['pertanyaan11', 'pertanyaan11_detail'],
      },
      'ad_diin': {
        'A. Yakin Allah Akan Memberikan Kesembuhan': ['pertanyaan12', 'pertanyaan12_detail'],
        'B. Yakin Allah Selalu Bersama Saya': ['pertanyaan13', 'pertanyaan13_detail'],
        'C. Kesulitan Melakukan Sholat': ['pertanyaan14', 'pertanyaan14_detail'],
        'D. Tahu Cara Sholat Saat Sakit': ['pertanyaan15'],
        'E. Perlu Pendampingan Sholat': ['pertanyaan16', 'pertanyaan16_detail'],
        'F. Cara Melakukan Sholat': ['pertanyaan17'],
        'G. Dapat Melakukan Tayamum': ['pertanyaan18', 'pertanyaan18_detail'],
        'H. Perlu Bantuan Tayamum': ['pertanyaan19'],
      },
      'al_aql': {
        'A. Tahu Sakit Ujian dari Allah': ['pertanyaan20', 'pertanyaan20_detail'],
        'B. Asal Sehat dan Sakit': ['pertanyaan21', 'pertanyaan21_detail'],
        'C. Pengobatan yang Pernah Dilakukan': ['pertanyaan22', 'pertanyaan22_detail'],
        'D. Yakin dengan Pengobatan Medis': ['pertanyaan23', 'pertanyaan23_detail'],
        'E. Tahu Kebutuhan Ibadah Saat Sakit': ['pertanyaan24', 'pertanyaan24_detail'],
        'F. Tahu Ada Hikmah Saat Sakit': ['pertanyaan25'],
        'G. Tahu Larangan Islam Saat Sakit': ['pertanyaan26'],
      },
      'an_nasl': {
        'A. Keluarga Yakin Takdir Allah': ['pertanyaan27', 'pertanyaan27_detail'],
        'B. Asal Sakit Menurut Keluarga': ['pertanyaan28', 'pertanyaan28_detail'],
        'C. Pengobatan Keluarga': ['pertanyaan29', 'pertanyaan29_detail'],
        'D. Orang Tua Membantu Doa': ['pertanyaan30', 'pertanyaan30_detail'],
        'E. Orang Tua Membantu Sholat/Ibadah': ['pertanyaan31'],
        'F. Orang Tua Membiasakan Ibadah': ['pertanyaan32'],
        'G. Sering Diperdengarkan Al-Qur\'an': ['pertanyaan33'],
        'H. Tahu Tubuh Harus Dijaga': ['pertanyaan34'],
        'I. Tahu Bagian Tubuh Privat': ['pertanyaan35'],
        'J. Orang Tua Mengingatkan Kebersihan': ['pertanyaan36'],
        'K. Tahu Perubahan Tubuh Normal': ['pertanyaan37'],
        'L. Orang Tua Menjelaskan Perubahan Tubuh': ['pertanyaan38'],
        'M. Merasa Aman Saat Dirawat': ['pertanyaan39'],
      },
      'al_mal': {
        'A. Pekerja dalam Keluarga': ['pertanyaan40'],
        'B. Kebutuhan Makan-Minum Tercukupi': ['pertanyaan41'],
        'C. Pekerjaan Orang Tua': ['pertanyaan42'],
        'D. Kegiatan Menghasilkan Uang': ['pertanyaan43', 'pertanyaan43_detail'],
        'E. Kepemilikan Asuransi': ['pertanyaan44'],
        'F. Keluhan Biaya Rumah Sakit': ['pertanyaan45', 'pertanyaan45_detail'],
      },
    };
  }

  /// Mendapatkan daftar pertanyaan untuk Hifz tertentu
  Map<String, List<String>> getQuestionsForHifz(String hifzKey) {
    return hifzQuestionMapping[hifzKey] ?? {};
  }

  /// Mendapatkan jawaban untuk pertanyaan tertentu
  String getAnswer(String questionId) {
    return pertanyaan[questionId] ?? '-';
  }

  /// Mendapatkan semua jawaban untuk Hifz tertentu
  List<Map<String, dynamic>> getHifzAnswers(String hifzKey) {
    final questions = getQuestionsForHifz(hifzKey);
    final answers = <Map<String, dynamic>>[];

    questions.forEach((questionText, questionIds) {
      final questionAnswers = <String>[];
      for (var id in questionIds) {
        final answer = getAnswer(id);
        if (answer != '-') {
          questionAnswers.add(answer);
        }
      }

      if (questionAnswers.isNotEmpty) {
        answers.add({
          'question': questionText,
          'answers': questionAnswers,
        });
      }
    });

    return answers;
  }

  Map<String, String> getAllAnswers() {
    return pertanyaan;
  }

  /// Mendapatkan jumlah jawaban yang telah diisi
  int getFilledAnswersCount() {
    return pertanyaan.values.where((answer) => answer.isNotEmpty && answer != '-').length;
  }

  /// Mendapatkan presentase kelengkapan jawaban
  double getAnswerCompletionPercentage() {
    final total = pertanyaan.length;
    if (total == 0) return 0.0;
    final filled = getFilledAnswersCount();
    return (filled / total) * 100;
  }

  /// Mendapatkan data lengkap Hifz
  Map<String, dynamic> getHifzData(String hifzKey) {
    final hifzMap = {
      'an_nafs': {
        'title': 'Hifz An-Nafs',
        'subtitle': 'Penjagaan Jiwa dan Keselamatan',
        'icon': Icons.health_and_safety,
        'color': Colors.red,
        'score': hifzAnNafsScore,
        'category': hifzAnNafsCategory,
        'video': hifzAnNafsVideo,
      },
      'ad_diin': {
        'title': 'Hifz Ad-Diin',
        'subtitle': 'Penjagaan Spiritual',
        'icon': Icons.mosque,
        'color': Colors.green,
        'score': hifzAdDiinScore,
        'category': hifzAdDiinCategory,
        'video': hifzAdDiinVideo,
      },
      'al_aql': {
        'title': 'Hifz Al-Aql',
        'subtitle': 'Penjagaan Akal dan Perkembangan',
        'icon': Icons.psychology,
        'color': Colors.purple,
        'score': hifzAlAqlScore,
        'category': hifzAlAqlCategory,
        'video': hifzAlAqlVideo,
      },
      'an_nasl': {
        'title': 'Hifz An-Nasl',
        'subtitle': 'Penjagaan Keturunan dan Pola Asuh',
        'icon': Icons.family_restroom,
        'color': Colors.orange,
        'score': hifzAnNaslScore,
        'category': hifzAnNaslCategory,
        'video': hifzAnNaslVideo,
      },
      'al_mal': {
        'title': 'Hifz Al-Mal',
        'subtitle': 'Penjagaan Ekonomi Keluarga',
        'icon': Icons.savings,
        'color': Colors.blue,
        'score': hifzAlMalScore,
        'category': hifzAlMalCategory,
        'video': hifzAlMalVideo,
      },
    };

    final data = hifzMap[hifzKey] ?? {};
    data['answers'] = getHifzAnswers(hifzKey);

    return data;
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
