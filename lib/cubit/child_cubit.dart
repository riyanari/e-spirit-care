// cubit/child_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/child_model.dart';
import '../services/child_services.dart';

part 'child_state.dart';

class ChildCubit extends Cubit<ChildState> {
  ChildCubit() : super(ChildInitial());

  final ChildServices _services = ChildServices();

  Future<void> loadChildren(String parentId) async {
    debugPrint('[ChildCubit] loadChildren untuk parentId = $parentId');
    try {
      emit(ChildLoading());
      final children = await _services.getChildren(parentId);
      emit(ChildLoaded(children));
    } catch (e) {
      emit(ChildFailed(e.toString()));
    }
  }

  Future<void> addChild({
    required String parentId,
    required String name,
    required String username,
    required String password,
    required String umur,
    required String jenisKelamin,
    required String pendidikan,
    required Map<String, String> pertanyaan,
    List<String> harapan = const [],

    // Hapus parameter HIFZ karena kita akan hitung ulang
    // int? hifzAnNafsScore,
    // int? hifzAdDiinScore,
    // int? hifzAlAqlScore,
    // int? hifzAnNaslScore,
    // int? hifzAlMalScore,
    // String? hifzAnNafsCategory,
    // String? hifzAdDiinCategory,
    // String? hifzAlAqlCategory,
    // String? hifzAnNaslCategory,
    // String? hifzAlMalCategory,
  }) async {
    try {
      emit(ChildLoading());

      // HITUNG SKOR HIFZ dari pertanyaan
      final hifzScores = _calculateHifzScores(pertanyaan);

      // Tentukan kategori berdasarkan skor
      final hifzCategories = _determineHifzCategories(hifzScores);

      // Hitung total skor dan kategori overall
      final totalHifzScore = hifzScores.values.reduce((a, b) => a + b);
      final overallCategory = _calculateOverallCategory(hifzScores);

      // LOGGING untuk debug
      debugPrint('[ChildCubit] Skor HIFZ yang dihitung:');
      hifzScores.forEach((key, value) {
        debugPrint('  $key: $value (${hifzCategories[key]})');
      });
      debugPrint('Total Skor HIFZ: $totalHifzScore');
      debugPrint('Kategori Overall: $overallCategory');

      // Tambahkan skor dan kategori ke dalam pertanyaan
      final updatedPertanyaan = Map<String, String>.from(pertanyaan);

      // Simpan skor HIFZ
      updatedPertanyaan['hifz_an_nafs_score'] = hifzScores['an_nafs']!.toString();
      updatedPertanyaan['hifz_ad_diin_score'] = hifzScores['ad_diin']!.toString();
      updatedPertanyaan['hifz_al_aql_score'] = hifzScores['al_aql']!.toString();
      updatedPertanyaan['hifz_an_nasl_score'] = hifzScores['an_nasl']!.toString();
      updatedPertanyaan['hifz_al_mal_score'] = hifzScores['al_mal']!.toString();

      // Simpan kategori HIFZ
      updatedPertanyaan['hifz_an_nafs_category'] = hifzCategories['an_nafs']!;
      updatedPertanyaan['hifz_ad_diin_category'] = hifzCategories['ad_diin']!;
      updatedPertanyaan['hifz_al_aql_category'] = hifzCategories['al_aql']!;
      updatedPertanyaan['hifz_an_nasl_category'] = hifzCategories['an_nasl']!;
      updatedPertanyaan['hifz_al_mal_category'] = hifzCategories['al_mal']!;

      // Simpan total dan overall
      updatedPertanyaan['total_hifz_score'] = totalHifzScore.toString();
      updatedPertanyaan['hifz_overall_category'] = overallCategory;

      // Buat ChildModel
      final finalChild = ChildModel(
        id: '',
        parentId: parentId,
        name: name,
        username: username,
        password: password,
        umur: umur,
        jenisKelamin: jenisKelamin,
        pendidikan: pendidikan,
        pertanyaan: updatedPertanyaan,
        harapan: harapan,
        totalSkor: totalHifzScore,
        kategori: overallCategory,
      );

      // Simpan ke Firestore
      await _services.addChild(finalChild);

      // Reload children untuk update UI
      final children = await _services.getChildren(parentId);
      emit(ChildLoaded(children));

    } catch (e) {
      debugPrint('[ChildCubit] ❌ addChild error: $e');
      emit(ChildFailed(e.toString()));
    }
  }

  Future<void> saveDiagnosis({
    required String parentId,
    required ChildModel child,
    required String diagnosis,
    required String note,
    String? nurseId,
    String? nurseName,
  }) async {
    try {
      debugPrint(
        '[ChildCubit] saveDiagnosis untuk childId=${child.id}, parentId=$parentId',
      );
      await _services.saveDiagnosisForChild(
        parentId: parentId,
        child: child,
        diagnosis: diagnosis,
        note: note,
        nurseId: nurseId,
        nurseName: nurseName,
      );
      // Tidak mengubah state list anak, hanya log
    } catch (e) {
      debugPrint('[ChildCubit] ❌ saveDiagnosis error: $e');
      emit(ChildFailed(e.toString()));
    }
  }


  // ==================== HELPER FUNCTIONS ====================

  /// Fungsi untuk menghitung skor per aspek
  /// Fungsi baru untuk menghitung semua skor HIFZ sekaligus
  Map<String, int> _calculateHifzScores(Map<String, String> pertanyaan) {
    return {
      'an_nafs': _calculateHifzScoreForAspect('an_nafs', pertanyaan),
      'ad_diin': _calculateHifzScoreForAspect('ad_diin', pertanyaan),
      'al_aql': _calculateHifzScoreForAspect('al_aql', pertanyaan),
      'an_nasl': _calculateHifzScoreForAspect('an_nasl', pertanyaan),
      'al_mal': _calculateHifzScoreForAspect('al_mal', pertanyaan),
    };
  }

  /// Fungsi untuk menghitung skor per aspek
  int _calculateHifzScoreForAspect(String aspect, Map<String, String> pertanyaan) {
    // Mapping pertanyaan per aspek
    final Map<String, List<String>> aspectQuestions = {
      'an_nafs': ['pertanyaan5', 'pertanyaan6', 'pertanyaan9', 'pertanyaan10', 'pertanyaan11'],
      'ad_diin': ['pertanyaan12', 'pertanyaan13', 'pertanyaan14', 'pertanyaan15',
        'pertanyaan16', 'pertanyaan17', 'pertanyaan18', 'pertanyaan19'],
      'al_aql': ['pertanyaan20', 'pertanyaan21', 'pertanyaan22', 'pertanyaan23',
        'pertanyaan24', 'pertanyaan25', 'pertanyaan26'],
      'an_nasl': ['pertanyaan27', 'pertanyaan28', 'pertanyaan29', 'pertanyaan30',
        'pertanyaan31', 'pertanyaan32', 'pertanyaan33', 'pertanyaan34',
        'pertanyaan35', 'pertanyaan36', 'pertanyaan37', 'pertanyaan38', 'pertanyaan39'],
      'al_mal': ['pertanyaan40', 'pertanyaan41', 'pertanyaan42', 'pertanyaan43',
        'pertanyaan44', 'pertanyaan45'],
    };

    int score = 0;
    final questions = aspectQuestions[aspect] ?? [];

    for (final questionId in questions) {
      final answer = pertanyaan[questionId] ?? '';
      score += _getScoreForAnswer(questionId, answer);
    }

    return score;
  }


  /// Fungsi untuk menghitung skor per HIFZ dari pertanyaan
  int _calculateHifzScore(String hifzKey, Map<String, String> pertanyaan) {
    int score = 0;

    // Mapping pertanyaan per HIFZ (sesuai dengan AddChildPage)
    final Map<String, List<String>> questionMapping = {
      'an_nafs': [
        'pertanyaan5', 'pertanyaan6', 'pertanyaan9', 'pertanyaan10', 'pertanyaan11'
      ],
      'ad_diin': [
        'pertanyaan12', 'pertanyaan13', 'pertanyaan14', 'pertanyaan15',
        'pertanyaan16', 'pertanyaan17', 'pertanyaan18', 'pertanyaan19'
      ],
      'al_aql': [
        'pertanyaan20', 'pertanyaan21', 'pertanyaan22', 'pertanyaan23',
        'pertanyaan24', 'pertanyaan25', 'pertanyaan26'
      ],
      'an_nasl': [
        'pertanyaan27', 'pertanyaan28', 'pertanyaan29', 'pertanyaan30',
        'pertanyaan31', 'pertanyaan32', 'pertanyaan33', 'pertanyaan34',
        'pertanyaan35', 'pertanyaan36', 'pertanyaan37', 'pertanyaan38', 'pertanyaan39'
      ],
      'al_mal': [
        'pertanyaan40', 'pertanyaan41', 'pertanyaan42', 'pertanyaan43',
        'pertanyaan44', 'pertanyaan45'
      ],
    };

    final questions = questionMapping[hifzKey] ?? [];

    for (final questionId in questions) {
      final answer = pertanyaan[questionId] ?? '';
      score += _getScoreForAnswer(questionId, answer);
    }

    return score;
  }

  /// Sistem skoring yang persis sama dengan AddChildPage
  int _getScoreForAnswer(String questionId, String answer) {
    final normalizedAnswer = answer.toLowerCase().trim();

    // Scoring berdasarkan sistem AddChildPage
    switch (questionId) {
    // ===== HIFZ AN-NAFS (PAGE 1) =====
      case 'pertanyaan5': // alergi obat
      case 'pertanyaan6': // alergi makanan
      case 'pertanyaan11': // masalah makan
        return normalizedAnswer == 'tidak ada' ? 0 : 2;

      case 'pertanyaan9': // porsi makan
        if (normalizedAnswer == 'selalu habis') return 0;
        if (normalizedAnswer == 'sebagian') return 1;
        return 2; // "sering tidak habis"

      case 'pertanyaan10': // kebiasaan/pantangan makan
        return normalizedAnswer == 'tidak ada' ? 0 : 1;

    // ===== HIFZ AD-DIIN (PAGE 2) =====
      case 'pertanyaan12': // yakin Allah sembuhkan
      case 'pertanyaan13': // yakin Allah bersama saya
        return normalizedAnswer == 'yakin' ? 0 : 2;

      case 'pertanyaan14': // kesulitan sholat
        return normalizedAnswer == 'tidak' ? 0 : 2;

      case 'pertanyaan15': // tahu cara sholat saat sakit
        return normalizedAnswer == 'mengerti' ? 0 : 2;

      case 'pertanyaan16': // perlu pendampingan sholat
        return normalizedAnswer == 'tidak' ? 0 : 1;

      case 'pertanyaan17': // cara sholat
        if (normalizedAnswer == 'berdiri') return 0;
        if (normalizedAnswer == 'duduk') return 1;
        if (normalizedAnswer.contains('berbaring')) return 2;
        if (normalizedAnswer.contains('terlentang')) return 2;
        if (normalizedAnswer.contains('gerakan mata')) return 2;
        return 2; // bentuk lain

      case 'pertanyaan18': // mampu tayamum
        return normalizedAnswer == 'mampu' ? 0 : 2;

      case 'pertanyaan19': // perlu bantuan tayamum
        return normalizedAnswer == 'mandiri' ? 0 : 1;

    // ===== HIFZ AL-‘AQL (PAGE 3) =====
      case 'pertanyaan20': // tahu sakit ujian Allah
      case 'pertanyaan24': // tahu kebutuhan ibadah saat sakit
      case 'pertanyaan25': // tahu ada hikmah saat sakit
      case 'pertanyaan26': // tahu ada larangan dalam Islam saat sakit
        return normalizedAnswer == 'mengetahui' ? 0 : 2;

      case 'pertanyaan21': // sehat dan sakit berasal dari
        return normalizedAnswer.contains('ketetapan dari allah swt') ? 0 : 2;

      case 'pertanyaan22': // pengobatan yang dilakukan
        return normalizedAnswer.contains('segera datang') ? 0 : 2;

      case 'pertanyaan23': // yakin dengan pengobatan medis
        return normalizedAnswer.contains('yakin bahwa pengobatan medis') ? 0 : 2;

    // ===== HIFZ AN-NASL (PAGE 4) =====
      case 'pertanyaan27': // keluarga yakin sehat sakit dari Allah
        return normalizedAnswer == 'yakin' ? 0 : 2;

      case 'pertanyaan28': // menurut keluarga sakit berasal dari
        return normalizedAnswer.contains('dari allah swt') ? 0 : 2;

      case 'pertanyaan29': // ketika sakit keluarga mencari pengobatan
        return normalizedAnswer.contains('ke pelayanan kesehatan') ? 0 : 2;

      case 'pertanyaan30': // orang tua membantu berdoa
      case 'pertanyaan31': // orang tua membantu sholat
      case 'pertanyaan33': // diperdengarkan Al-Qur'an
      case 'pertanyaan36': // orang tua ingatkan kebersihan
      case 'pertanyaan38': // orang tua jelaskan perubahan tubuh
      case 'pertanyaan39': // merasa aman dirawat
        return normalizedAnswer == 'ya' ? 0 : 2;

      case 'pertanyaan32': // orang tua menanamkan sholat/doa
        return normalizedAnswer.contains('ya, menanamkan') ? 0 : 2;

      case 'pertanyaan34': // tahu tubuh harus dijaga
      case 'pertanyaan35': // tahu bagian tubuh yang tidak boleh disentuh
      case 'pertanyaan37': // tahu perubahan tubuh normal
        return normalizedAnswer == 'tahu' ? 0 : 2;

    // ===== HIFZ AL-MAL (PAGE 5) =====
      case 'pertanyaan40': // orang yang bekerja dalam keluarga
        if (normalizedAnswer == 'ayah') return 0;
        if (normalizedAnswer == 'ibu') return 0;
        if (normalizedAnswer.contains('anggota keluarga lain')) return 1;
        return 2; // "tidak ada sumber tetap"

      case 'pertanyaan41': // kebutuhan makan tercukupi
        return normalizedAnswer.contains('ya, tercukupi') ? 0 : 2;

      case 'pertanyaan42': // orang tua bekerja sebagai
        return normalizedAnswer == 'tidak bekerja' ? 2 : 0;

      case 'pertanyaan43': // kegiatan lain yang menghasilkan uang
        return normalizedAnswer == 'tidak ada' ? 0 : 2;

      case 'pertanyaan44': // memiliki asuransi
        return normalizedAnswer == 'tidak memiliki' ? 2 : 0;

      case 'pertanyaan45': // orang tua mengeluh biaya rumah sakit
        return normalizedAnswer == 'tidak ada' ? 0 : 2;

      default:
        return 0;
    }
  }

  /// Menentukan kategori berdasarkan skor HIFZ
  Map<String, String> _determineHifzCategories(Map<String, int> scores) {
    return {
      'an_nafs': _getHifzCategory('an_nafs', scores['an_nafs']!),
      'ad_diin': _getHifzCategory('ad_diin', scores['ad_diin']!),
      'al_aql': _getHifzCategory('al_aql', scores['al_aql']!),
      'an_nasl': _getHifzCategory('an_nasl', scores['an_nasl']!),
      'al_mal': _getHifzCategory('al_mal', scores['al_mal']!),
    };
  }

  String _getHifzCategory(String hifzKey, int score) {
    switch (hifzKey) {
      case 'ad_diin':
        if (score <= 3) return 'Kesejahteraan Spiritual';
        if (score <= 7) return 'Risiko Distres Spiritual';
        return 'Distres Spiritual';

      case 'an_nafs':
        if (score <= 4) return 'Aman / risiko minimal';
        if (score <= 8) return 'Risiko sedang';
        return 'Risiko tinggi / perlu intervensi segera';

      case 'al_aql':
        if (score <= 3) return 'Perkembangan baik';
        if (score <= 6) return 'Risiko keterlambatan / stimulasi kurang';
        return 'Gangguan perkembangan / butuh evaluasi lanjutan';

      case 'an_nasl':
        if (score <= 4) return 'Pola asuh baik';
        if (score <= 8) return 'Risiko pola asuh tidak adekuat';
        return 'Pola asuh buruk / risiko perlakuan salah';

      case 'al_mal':
        if (score <= 3) return 'Kecukupan ekonomi baik';
        if (score <= 6) return 'Risiko ketidakcukupan ekonomi';
        return 'Ketidakcukupan berat / perlu rujukan sosial';

      default:
        return 'Tidak Diketahui';
    }
  }

  /// Menghitung kategori overall dari skor HIFZ
  String _calculateOverallCategory(Map<String, int> scores) {
    // Hitung total score
    final totalScore = scores.values.reduce((a, b) => a + b);

    // Total maksimal = 74 poin, jadi:
    // - Baik: 0-14 poin (skor rendah = baik)
    // - Perhatian: 15-29 poin
    // - Perlu Intervensi: 30+ poin
    if (totalScore <= 14) return 'Baik';
    if (totalScore <= 29) return 'Perhatian';
    return 'Perlu Intervensi';
  }

}