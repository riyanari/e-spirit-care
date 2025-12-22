import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../pages/hifz_scoring_system.dart';

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

  /// Semua jawaban kuesioner
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

  /// Mendapatkan semua jawaban untuk Hifz tertentu (format baru)
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

  /// =========================
  /// GETTERS untuk skor HIFZ berdasarkan sistem baru
  /// =========================

  int get hifzAnNafsScore {
    final answers = getHifzAnswers('an_nafs');
    return HifzScoringSystem.calculateScore(answers);
  }

  int get hifzAdDiinScore {
    final answers = getHifzAnswers('ad_diin');
    return HifzScoringSystem.calculateScore(answers);
  }

  int get hifzAlAqlScore {
    final answers = getHifzAnswers('al_aql');
    return HifzScoringSystem.calculateScore(answers);
  }

  int get hifzAnNaslScore {
    final answers = getHifzAnswers('an_nasl');
    return HifzScoringSystem.calculateScore(answers);
  }

  int get hifzAlMalScore {
    final answers = getHifzAnswers('al_mal');
    return HifzScoringSystem.calculateScore(answers);
  }

  /// GETTER untuk kategori berdasarkan sistem baru
  String get hifzAnNafsCategory {
    final score = hifzAnNafsScore;
    return HifzScoringSystem.getCategory('an_nafs', score);
  }

  String get hifzAdDiinCategory {
    final score = hifzAdDiinScore;
    return HifzScoringSystem.getCategory('ad_diin', score);
  }

  String get hifzAlAqlCategory {
    final score = hifzAlAqlScore;
    return HifzScoringSystem.getCategory('al_aql', score);
  }

  String get hifzAnNaslCategory {
    final score = hifzAnNaslScore;
    return HifzScoringSystem.getCategory('an_nasl', score);
  }

  String get hifzAlMalCategory {
    final score = hifzAlMalScore;
    return HifzScoringSystem.getCategory('al_mal', score);
  }

  /// GETTER untuk video berdasarkan kategori baru
  List<HifzVideo> get hifzAnNafsVideos {
    final category = hifzAnNafsCategory;
    return HifzScoringSystem.getVideos('an_nafs', category);
  }

  List<HifzVideo> get hifzAdDiinVideos {
    final category = hifzAdDiinCategory;
    return HifzScoringSystem.getVideos('ad_diin', category);
  }

  List<HifzVideo> get hifzAlAqlVideos {
    final category = hifzAlAqlCategory;
    return HifzScoringSystem.getVideos('al_aql', category);
  }

  List<HifzVideo> get hifzAnNaslVideos {
    final category = hifzAnNaslCategory;
    return HifzScoringSystem.getVideos('an_nasl', category);
  }

  List<HifzVideo> get hifzAlMalVideos {
    final category = hifzAlMalCategory;
    return HifzScoringSystem.getVideos('al_mal', category);
  }

  /// Mendapatkan data lengkap Hifz (format baru dengan video)
  Map<String, dynamic> getHifzData(String hifzKey) {
    final scores = {
      'an_nafs': hifzAnNafsScore,
      'ad_diin': hifzAdDiinScore,
      'al_aql': hifzAlAqlScore,
      'an_nasl': hifzAnNaslScore,
      'al_mal': hifzAlMalScore,
    };

    final categories = {
      'an_nafs': hifzAnNafsCategory,
      'ad_diin': hifzAdDiinCategory,
      'al_aql': hifzAlAqlCategory,
      'an_nasl': hifzAnNaslCategory,
      'al_mal': hifzAlMalCategory,
    };

    final videos = {
      'an_nafs': hifzAnNafsVideos,
      'ad_diin': hifzAdDiinVideos,
      'al_aql': hifzAlAqlVideos,
      'an_nasl': hifzAnNaslVideos,
      'al_mal': hifzAlMalVideos,
    };

    final hifzMap = {
      'an_nafs': {
        'title': 'Hifz An-Nafs',
        'subtitle': 'Penjagaan Jiwa dan Keselamatan',
        'icon': Icons.health_and_safety,
        'color': Colors.red,
        'score': scores['an_nafs']!,
        'category': categories['an_nafs']!,
        'videos': videos['an_nafs']!,
        'description': HifzScoringSystem.getCategoryDescription('an_nafs', categories['an_nafs']!),
        'maxScore': HifzScoringSystem.getMaxScore('an_nafs'),
      },
      'ad_diin': {
        'title': 'Hifz Ad-Diin',
        'subtitle': 'Penjagaan Spiritual',
        'icon': Icons.mosque,
        'color': Colors.green,
        'score': scores['ad_diin']!,
        'category': categories['ad_diin']!,
        'videos': videos['ad_diin']!,
        'description': HifzScoringSystem.getCategoryDescription('ad_diin', categories['ad_diin']!),
        'maxScore': HifzScoringSystem.getMaxScore('ad_diin'),
      },
      'al_aql': {
        'title': 'Hifz Al-Aql',
        'subtitle': 'Penjagaan Akal dan Perkembangan',
        'icon': Icons.psychology,
        'color': Colors.purple,
        'score': scores['al_aql']!,
        'category': categories['al_aql']!,
        'videos': videos['al_aql']!,
        'description': HifzScoringSystem.getCategoryDescription('al_aql', categories['al_aql']!),
        'maxScore': HifzScoringSystem.getMaxScore('al_aql'),
      },
      'an_nasl': {
        'title': 'Hifz An-Nasl',
        'subtitle': 'Penjagaan Keturunan dan Pola Asuh',
        'icon': Icons.family_restroom,
        'color': Colors.orange,
        'score': scores['an_nasl']!,
        'category': categories['an_nasl']!,
        'videos': videos['an_nasl']!,
        'description': HifzScoringSystem.getCategoryDescription('an_nasl', categories['an_nasl']!),
        'maxScore': HifzScoringSystem.getMaxScore('an_nasl'),
      },
      'al_mal': {
        'title': 'Hifz Al-Mal',
        'subtitle': 'Penjagaan Ekonomi Keluarga',
        'icon': Icons.savings,
        'color': Colors.blue,
        'score': scores['al_mal']!,
        'category': categories['al_mal']!,
        'videos': videos['al_mal']!,
        'description': HifzScoringSystem.getCategoryDescription('al_mal', categories['al_mal']!),
        'maxScore': HifzScoringSystem.getMaxScore('al_mal'),
      },
    };

    final data = hifzMap[hifzKey] ?? {};
    data['answers'] = getHifzAnswers(hifzKey);

    return data;
  }

  /// Hitung total skor HIFZ (untuk overall category)
  int get totalHifzScore {
    return hifzAnNafsScore +
        hifzAdDiinScore +
        hifzAlAqlScore +
        hifzAnNaslScore +
        hifzAlMalScore;
  }

  /// Overall category berdasarkan rata-rata skor
  String get hifzOverallCategory {
    final scores = [
      hifzAnNafsScore,
      hifzAdDiinScore,
      hifzAlAqlScore,
      hifzAnNaslScore,
      hifzAlMalScore,
    ];

    final maxScores = [
      HifzScoringSystem.getMaxScore('an_nafs'),
      HifzScoringSystem.getMaxScore('ad_diin'),
      HifzScoringSystem.getMaxScore('al_aql'),
      HifzScoringSystem.getMaxScore('an_nasl'),
      HifzScoringSystem.getMaxScore('al_mal'),
    ];

    double totalPercentage = 0;

    for (int i = 0; i < scores.length; i++) {
      // Konversi ke persentase (skor rendah = baik, skor tinggi = buruk)
      final percentage = 100 - (scores[i] / maxScores[i] * 100);
      totalPercentage += percentage;
    }

    final avgPercentage = totalPercentage / scores.length;

    if (avgPercentage >= 70) return 'Tinggi';
    if (avgPercentage >= 40) return 'Sedang';
    return 'Rendah';
  }

  /// Warna untuk overall category
  Color get hifzOverallColor {
    final category = hifzOverallCategory;
    if (category == 'Tinggi') return Colors.green;
    if (category == 'Sedang') return Colors.orange;
    return Colors.red;
  }

  /// Progress value untuk overall (0-1)
  double get hifzOverallProgress {
    final totalMaxScore = HifzScoringSystem.getMaxScore('an_nafs') +
        HifzScoringSystem.getMaxScore('ad_diin') +
        HifzScoringSystem.getMaxScore('al_aql') +
        HifzScoringSystem.getMaxScore('an_nasl') +
        HifzScoringSystem.getMaxScore('al_mal');

    return totalHifzScore / totalMaxScore;
  }

  /// Mendapatkan semua video rekomendasi untuk semua HIFZ
  List<HifzVideo> getAllHifzVideos() {
    final allVideos = <HifzVideo>[];
    allVideos.addAll(hifzAnNafsVideos);
    allVideos.addAll(hifzAdDiinVideos);
    allVideos.addAll(hifzAlAqlVideos);
    allVideos.addAll(hifzAnNaslVideos);
    allVideos.addAll(hifzAlMalVideos);
    return allVideos;
  }

  /// Hitung skor dari semua jawaban utama (untuk backward compatibility)
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