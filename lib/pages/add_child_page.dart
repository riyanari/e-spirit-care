import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/child_cubit.dart';
import '../services/child_auth_service.dart';

class AddChildPage extends StatefulWidget {
  final String parentId;

  const AddChildPage({super.key, required this.parentId});

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  static const int _totalPages = 7;

  final PageController _pageController = PageController();

  // Biodata
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController umurController = TextEditingController();
  final TextEditingController pendidikanController = TextEditingController();
  String? selectedGender;

  // Harapan (kalau tidak dipakai bisa diabaikan)
  final List<String> selectedHarapan = [];

  String? _error;
  int _currentPage = 0;
  bool _isLoading = false;

  final ChildAuthService _childAuthService = ChildAuthService();

  /// jawaban utama
  final Map<String, String?> _answers = {};

  /// jawaban tambahan (keterangan "karena...", "yaitu...", dll)
  final Map<String, String?> _extraAnswers = {};

  late final List<_QuestionConfig> _questions = _buildQuestions();

  @override
  void dispose() {
    _pageController.dispose();
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    umurController.dispose();
    pendidikanController.dispose();
    super.dispose();
  }

  Map<String, _HifzResult> _calculateHifzResults() {
    int nafs = 0;
    int diin = 0;
    int aql = 0;
    int nasl = 0;
    int mal = 0;

    for (final q in _questions) {
      if (q.type != QuestionType.choice) continue;

      final ans = _answers[q.id];
      final s = _scoreForAnswer(q, ans);

      switch (q.pageIndex) {
        case 1:
          nafs += s;
          break;
        case 2:
          diin += s;
          break;
        case 3:
          aql += s;
          break;
        case 4:
          nasl += s;
          break;
        case 5:
          mal += s;
          break;
      }
    }

    final nafsCat = _kategoriHifzAnNafs(nafs);
    final diinCat = _kategoriHifzAdDiin(diin);
    final aqlCat = _kategoriHifzAlAql(aql);
    final naslCat = _kategoriHifzAnNasl(nasl);
    final malCat = _kategoriHifzAlMal(mal);

    return {
      'nafs': _HifzResult(
        score: nafs,
        category: nafsCat,
        videoSuggestion: _videoHifzAnNafs(nafsCat),
      ),
      'diin': _HifzResult(
        score: diin,
        category: diinCat,
        videoSuggestion: _videoHifzAdDiin(diinCat),
      ),
      'aql': _HifzResult(
        score: aql,
        category: aqlCat,
        videoSuggestion: _videoHifzAlAql(aqlCat),
      ),
      'nasl': _HifzResult(
        score: nasl,
        category: naslCat,
        videoSuggestion: _videoHifzAnNasl(naslCat),
      ),
      'mal': _HifzResult(
        score: mal,
        category: malCat,
        videoSuggestion: _videoHifzAlMal(malCat),
      ),
    };
  }

  // ---------- Kategori per Hifz (sesuai tabel klien) ----------

  String _kategoriHifzAdDiin(int total) {
    if (total <= 3) return 'Kesejahteraan Spiritual';
    if (total <= 7) return 'Risiko Distres Spiritual';
    return 'Distres Spiritual';
  }

  String _kategoriHifzAnNafs(int total) {
    if (total <= 4) return 'Aman / risiko minimal';
    if (total <= 8) return 'Risiko sedang';
    return 'Risiko tinggi / perlu intervensi segera';
  }

  String _kategoriHifzAlAql(int total) {
    if (total <= 3) return 'Perkembangan baik';
    if (total <= 6) return 'Risiko keterlambatan / stimulasi kurang';
    return 'Gangguan perkembangan / butuh evaluasi lanjutan';
  }

  String _kategoriHifzAnNasl(int total) {
    if (total <= 4) return 'Pola asuh baik';
    if (total <= 8) return 'Risiko pola asuh tidak adekuat';
    return 'Pola asuh buruk / risiko perlakuan salah';
  }

  String _kategoriHifzAlMal(int total) {
    if (total <= 3) return 'Kecukupan ekonomi baik';
    if (total <= 6) return 'Risiko ketidakcukupan ekonomi';
    return 'Ketidakcukupan berat / perlu rujukan sosial';
  }

  // ---------- Rekomendasi video per kategori ----------

  String _videoHifzAdDiin(String kategori) {
    switch (kategori) {
      case 'Kesejahteraan Spiritual':
        return 'Panduan sholat saat sakit (ringan) dan dzikir untuk anak';
      case 'Risiko Distres Spiritual':
        return 'Cara tayamum, sholat sambil duduk/tidur, dan pendampingan ibadah anak';
      default:
        return 'Penyuluhan makna sakit dalam Islam dan pentingnya doa & dukungan keluarga';
    }
  }

  String _videoHifzAnNafs(String kategori) {
    if (kategori.startsWith('Aman')) {
      return 'Cara menjaga kesehatan anak: nutrisi, hygiene, dan istirahat';
    } else if (kategori.startsWith('Risiko sedang')) {
      return 'Pencegahan cedera, pencegahan kekerasan, dan pemantauan anak sakit';
    } else {
      return 'Edukasi kekerasan & penelantaran anak, keamanan rumah, dan tanda darurat';
    }
  }

  String _videoHifzAlAql(String kategori) {
    if (kategori == 'Perkembangan baik') {
      return 'Stimulasi perkembangan sesuai usia dan permainan edukatif';
    } else if (kategori.startsWith('Risiko')) {
      return 'Stimulasi otak, manajemen screen time, dan komunikasi efektif dengan anak';
    } else {
      return 'Deteksi dini keterlambatan tumbuh kembang dan kapan ke dokter tumbuh kembang';
    }
  }

  String _videoHifzAnNasl(String kategori) {
    if (kategori == 'Pola asuh baik') {
      return 'Bonding ibu-anak, sentuhan kasih sayang, dan komunikasi hangat';
    } else if (kategori.startsWith('Risiko')) {
      return 'Pola asuh positif, merespons tantrum, dan menjaga kebersihan area reproduksi';
    } else {
      return 'Pencegahan kekerasan, hak anak, dan keamanan tubuh anak';
    }
  }

  String _videoHifzAlMal(String kategori) {
    if (kategori == 'Kecukupan ekonomi baik') {
      return 'Manajemen keuangan keluarga sederhana';
    } else if (kategori.startsWith('Risiko ketidakcukupan')) {
      return 'Memilih nutrisi murah–bergizi dan pemanfaatan layanan kesehatan terjangkau';
    } else {
      return 'Informasi program bantuan pemerintah, BPJS, dinas sosial, dan posyandu';
    }
  }

  // =======================
  // LOGIC
  // =======================

  void _updateHarapan(String value, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedHarapan.add(value);
      } else {
        selectedHarapan.remove(value);
      }
    });
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onNextPressed() async {
    // Kalau masih loading, jangan apa-apa
    if (_isLoading) return;

    // STEP 0: validasi biodata + cek username
    if (_currentPage == 0) {
      final name = nameController.text.trim();
      final username = usernameController.text.trim();
      final password = passwordController.text.trim();
      final umur = umurController.text.trim();
      final pendidikan = pendidikanController.text.trim();

      // --- Validasi biodata sama seperti di _save() ---
      if (name.isEmpty ||
          username.isEmpty ||
          password.isEmpty ||
          umur.isEmpty) {
        setState(
          () => _error = 'Nama, username, password, dan umur wajib diisi',
        );
        return;
      }

      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username)) {
        setState(
          () => _error = 'Username hanya boleh mengandung huruf dan angka',
        );
        return;
      }

      if (password.length < 6) {
        setState(() => _error = 'Password minimal 6 karakter');
        return;
      }

      if (selectedGender == null || selectedGender!.isEmpty) {
        setState(() => _error = 'Jenis kelamin wajib dipilih');
        return;
      }

      if (pendidikan.isEmpty) {
        setState(() => _error = 'Pendidikan anak wajib diisi');
        return;
      }

      // --- Cek username ke server di sini ---
      setState(() {
        _error = null;
        _isLoading = true;
      });

      try {
        final isUsernameAvailable = await _childAuthService.isUsernameAvailable(
          username,
        );
        if (!isUsernameAvailable) {
          setState(() {
            _error = 'Username "$username" sudah digunakan';
            _isLoading = false;
          });
          return; // tetap di halaman 0
        }
      } catch (e) {
        setState(() {
          _error = 'Gagal memeriksa username: $e';
          _isLoading = false;
        });
        return; // tetap di halaman 0
      }

      // kalau semua ok
      setState(() {
        _isLoading = false;
      });
    }

    // Halaman lain: cukup next saja
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateAllQuestions() {
    for (final q in _questions) {
      final main = _answers[q.id];
      if (main == null || main.isEmpty) return false;

      if (q.extraLabel != null &&
          q.type == QuestionType.choice &&
          q.showExtraFor.contains(main)) {
        final extra = _extraAnswers[q.id];
        if (extra == null || extra.isEmpty) return false;
      }
    }
    return true;
  }

  // =======================
  // SCORING HIFZ
  // =======================

  /// Skor per jawaban (0–2) untuk setiap pertanyaan pilihan ganda.
  int _scoreForAnswer(_QuestionConfig q, String? answer) {
    if (answer == null || answer.isEmpty || q.type != QuestionType.choice) {
      return 0;
    }

    switch (q.id) {
      // ===== HIFZ AN-NAFS (pageIndex 1) =====
      case 'pertanyaan5': // alergi obat
      case 'pertanyaan6': // alergi makanan
        return answer == 'Tidak ada' ? 0 : 2;

      case 'pertanyaan9': // porsi makan
        if (answer == 'Selalu habis') return 0;
        if (answer == 'Sebagian') return 1;
        return 2; // Sering tidak habis

      case 'pertanyaan10': // kebiasaan/pantangan makan
        return answer == 'Tidak ada' ? 0 : 1; // pantangan = hambatan ringan

      case 'pertanyaan11': // masalah makan
        return answer == 'Tidak ada' ? 0 : 2;

      // ===== HIFZ AD-DIIN (pageIndex 2) =====
      case 'pertanyaan12': // yakin Allah sembuhkan
      case 'pertanyaan13': // yakin Allah bersama saya
        return answer == 'Yakin' ? 0 : 2;

      case 'pertanyaan14': // kesulitan sholat
        return answer == 'Tidak' ? 0 : 2; // Tidak = tidak ada masalah

      case 'pertanyaan15': // tahu cara sholat saat sakit
        return answer == 'Mengerti' ? 0 : 2;

      case 'pertanyaan16': // perlu pendampingan sholat
        return answer == 'Tidak' ? 0 : 1; // butuh bantuan = 1

      case 'pertanyaan17': // cara sholat (derajat kemampuan)
        if (answer == 'Berdiri') return 0;
        if (answer == 'Duduk') return 1;
        return 2; // bentuk lain = keterbatasan lebih berat

      case 'pertanyaan18': // mampu tayamum
        return answer == 'Mampu' ? 0 : 2;

      case 'pertanyaan19': // perlu bantuan tayamum
        return answer == 'Mandiri' ? 0 : 1;

      // ===== HIFZ AL-‘AQL (pageIndex 3) =====
      case 'pertanyaan20':
      case 'pertanyaan24':
      case 'pertanyaan25':
      case 'pertanyaan26':
        // Mengetahui = sejahtera, Tidak mengetahui = masalah
        return answer == 'Mengetahui' ? 0 : 2;

      case 'pertanyaan21':
        return answer == 'Ketetapan dari Allah SWT' ? 0 : 2;

      case 'pertanyaan22':
        return answer ==
                'Menempuh jalur medis sebagai ikhtiar dan tetap pasrah pada Allah SWT'
            ? 0
            : 2;

      case 'pertanyaan23':
        return answer == 'Yakin bahwa pengobatan medis adalah jalan Allah SWT'
            ? 0
            : 2;

      // ===== HIFZ AN-NASL (pageIndex 4) =====
      case 'pertanyaan27':
        return answer == 'Yakin' ? 0 : 2;

      case 'pertanyaan28':
        return answer == 'Dari Allah SWT' ? 0 : 2;

      case 'pertanyaan29':
        return answer == 'Ke pelayanan kesehatan sebagai bentuk ikhtiar dan doa'
            ? 0
            : 2;

      case 'pertanyaan30':
      case 'pertanyaan31':
      case 'pertanyaan33':
      case 'pertanyaan36':
      case 'pertanyaan38':
        // Ya = baik, Tidak = masalah
        return answer.startsWith('Ya') ? 0 : 2;

      case 'pertanyaan32':
        return answer == 'Ya, menanamkan' ? 0 : 2;

      case 'pertanyaan34':
      case 'pertanyaan35':
      case 'pertanyaan37':
        return answer == 'Tahu' ? 0 : 2;

      case 'pertanyaan39':
        return answer == 'Ya' ? 0 : 2;

      // ===== HIFZ AL-MAL (pageIndex 5) =====
      case 'pertanyaan40':
        if (answer == 'Tidak ada sumber tetap') return 2;
        if (answer == 'Anggota keluarga lain') return 1;
        return 0; // Ayah / Ibu

      case 'pertanyaan41':
        return answer == 'Ya, tercukupi' ? 0 : 2;

      case 'pertanyaan42':
        return answer == 'Tidak bekerja' ? 2 : 0;

      case 'pertanyaan43':
        // kegiatan menghasilkan uang -> di sini dianggap netral (tidak dipakai skor)
        return 0;

      case 'pertanyaan44':
        return answer == 'Tidak memiliki' ? 2 : 0;

      case 'pertanyaan45':
        return answer == 'Tidak ada' ? 0 : 2;

      default:
        return 0;
    }
  }

  Future<void> _save() async {
    if (_isLoading) return;

    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final umur = umurController.text.trim();
    final pendidikan = pendidikanController.text.trim();

    // Validasi biodata
    if (name.isEmpty || username.isEmpty || password.isEmpty || umur.isEmpty) {
      setState(() => _error = 'Nama, username, password, dan umur wajib diisi');
      _pageController.jumpToPage(0);
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username)) {
      setState(
        () => _error = 'Username hanya boleh mengandung huruf dan angka',
      );
      _pageController.jumpToPage(0);
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter');
      _pageController.jumpToPage(0);
      return;
    }

    if (selectedGender == null || selectedGender!.isEmpty) {
      setState(() => _error = 'Jenis kelamin wajib dipilih');
      _pageController.jumpToPage(0);
      return;
    }

    if (pendidikan.isEmpty) {
      setState(() => _error = 'Pendidikan anak wajib diisi');
      _pageController.jumpToPage(0);
      return;
    }

    // Validasi semua pertanyaan 1–45
    if (!_validateAllQuestions()) {
      setState(
        () => _error =
            'Semua pertanyaan pengkajian wajib diisi (termasuk keterangan).',
      );
      _pageController.jumpToPage(1); // lompat ke tab pertama pengkajian
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    // Cek username unik
    // try {
    //   final isUsernameAvailable = await _childAuthService.isUsernameAvailable(
    //     username,
    //   );
    //   if (!isUsernameAvailable) {
    //     setState(() {
    //       _error = 'Username "$username" sudah digunakan';
    //       _isLoading = false;
    //     });
    //     _pageController.jumpToPage(0);
    //     return;
    //   }
    // } catch (e) {
    //   setState(() {
    //     _error = 'Gagal memeriksa username: $e';
    //     _isLoading = false;
    //   });
    //   _pageController.jumpToPage(0);
    //   return;
    // }

    // Susun map pertanyaan
    final Map<String, String> pertanyaan = {};
    for (final q in _questions) {
      final main = _answers[q.id] ?? '';
      pertanyaan[q.id] = main;

      if (q.extraLabel != null &&
          q.type == QuestionType.choice &&
          q.showExtraFor.contains(main)) {
        pertanyaan['${q.id}_detail'] = _extraAnswers[q.id] ?? '';
      }
    }

    // Hitung skor, kategori, dan rekomendasi video per HIFZ (revisi klien)
    final hifzResults = _calculateHifzResults();

    final hNafs = hifzResults['nafs']!;
    final hDiin = hifzResults['diin']!;
    final hAql = hifzResults['aql']!;
    final hNasl = hifzResults['nasl']!;
    final hMal = hifzResults['mal']!;

    // Masukkan ke map pertanyaan (bisa dibaca backend untuk diagnosa & video)
    pertanyaan.addAll({
      'hifz_an_nafs_score': hNafs.score.toString(),
      'hifz_an_nafs_category': hNafs.category,
      'hifz_an_nafs_video': hNafs.videoSuggestion,

      'hifz_ad_diin_score': hDiin.score.toString(),
      'hifz_ad_diin_category': hDiin.category,
      'hifz_ad_diin_video': hDiin.videoSuggestion,

      'hifz_al_aql_score': hAql.score.toString(),
      'hifz_al_aql_category': hAql.category,
      'hifz_al_aql_video': hAql.videoSuggestion,

      'hifz_an_nasl_score': hNasl.score.toString(),
      'hifz_an_nasl_category': hNasl.category,
      'hifz_an_nasl_video': hNasl.videoSuggestion,

      'hifz_al_mal_score': hMal.score.toString(),
      'hifz_al_mal_category': hMal.category,
      'hifz_al_mal_video': hMal.videoSuggestion,
    });

    // Kirim ke Cubit
    context.read<ChildCubit>().addChild(
      parentId: widget.parentId,
      name: name,
      username: username,
      password: password,
      umur: umur,
      jenisKelamin: selectedGender!,
      pendidikan: pendidikan,
      pertanyaan: pertanyaan,
      harapan: selectedHarapan, // kalau tidak dipakai, tetap aman
    );
  }

  // =======================
  // BUILD
  // =======================

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChildCubit, ChildState>(
      listener: (context, state) {
        if (state is ChildFailed) {
          setState(() {
            _error = state.error;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ChildLoaded) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anak berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tambah Anak'),
          backgroundColor: Colors.blue.shade100,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            // progress
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentPage >= index
                            ? Colors.blue.shade400
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Langkah ${_currentPage + 1} dari $_totalPages',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildDataDasarPage(),
                  _buildAspectPage(
                    1,
                    '1. Pengkajian Aspek Fisik dan Psikologis (Hifz-An Nafs)',
                    Icons.health_and_safety,
                    Colors.red.shade50,
                  ),
                  _buildAspectPage(
                    2,
                    '2. Pengkajian Aspek Spiritual (Hifz-Ad-Diin)',
                    Icons.mosque,
                    Colors.green.shade50,
                  ),
                  _buildAspectPage(
                    3,
                    "3. Pengkajian Aspek Intelektual (Hifz-'Aql)",
                    Icons.psychology,
                    Colors.purple.shade50,
                  ),
                  _buildAspectPage(
                    4,
                    "4. Pengkajian Aspek Penjagaan Keturunan (Hifz-'Nasl)",
                    Icons.family_restroom,
                    Colors.orange.shade50,
                  ),
                  _buildAspectPage(
                    5,
                    "5. Pengkajian Aspek Penjagaan Ekonomi (Hifz-'Mal)",
                    Icons.savings,
                    Colors.blue.shade50,
                  ),
                  _buildHarapanPage(),
                ],
              ),
            ),

            // nav buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha:0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.blue.shade400),
                        ),
                        child: Text(
                          'Kembali',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _isLoading
                        ? const ElevatedButton(
                            onPressed: null,
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (_currentPage < _totalPages - 1
                                      ? () => _onNextPressed()
                                      : () => _save()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _currentPage < _totalPages - 1
                                  ? 'Lanjut'
                                  : 'Simpan Anak',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================
  // PAGE 0: BIODATA
  // =======================

  Widget _buildDataDasarPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.child_care, size: 50, color: Colors.blue.shade600),
                const SizedBox(height: 8),
                const Text(
                  'Data Dasar Anak',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi informasi dasar tentang anak Anda',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildTextFieldWithIcon(
            nameController,
            'Nama Anak',
            Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextFieldWithIcon(
            usernameController,
            'Username Anak',
            Icons.alternate_email,
          ),
          const SizedBox(height: 16),
          _buildTextFieldWithIcon(
            passwordController,
            'Password Anak',
            Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildTextFieldWithIcon(
            umurController,
            'Umur Anak',
            Icons.cake_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Gender
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha:0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: InputDecoration(
                labelText: 'Jenis Kelamin',
                prefixIcon: Icon(Icons.wc, color: Colors.blue.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
              ],
              onChanged: (val) => setState(() => selectedGender = val),
            ),
          ),
          const SizedBox(height: 16),

          _buildTextFieldWithIcon(
            pendidikanController,
            'Pendidikan Anak',
            Icons.school,
          ),
          const SizedBox(height: 16),

          if (_error != null && _currentPage == 0) _buildErrorBox(_error!),
        ],
      ),
    );
  }

  // =======================
  // PAGE 1–5: ASPEK
  // =======================

  Widget _buildAspectPage(
    int pageIndex,
    String title,
    IconData icon,
    Color headerColor,
  ) {
    final qs = _questions
        .where((q) => q.pageIndex == pageIndex)
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 40, color: Colors.black54),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ...qs.map(_buildQuestionCard).toList(),

          if (_error != null && _currentPage == pageIndex)
            _buildErrorBox(_error!),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(_QuestionConfig q) {
    final selectedValue = _answers[q.id];
    final showExtra =
        q.type == QuestionType.choice &&
        q.extraLabel != null &&
        selectedValue != null &&
        q.showExtraFor.contains(selectedValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul + icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: q.iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(q.icon, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (q.type == QuestionType.text)
            TextFormField(
              initialValue: _answers[q.id] ?? '',
              onChanged: (val) => _answers[q.id] = val,
              maxLines: null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            )
          else
            Column(
              children: q.options.map((opt) {
                return RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  groupValue: selectedValue,
                  onChanged: (val) {
                    setState(() {
                      _answers[q.id] = val;
                      if (val != null && !q.showExtraFor.contains(val)) {
                        _extraAnswers[q.id] = null;
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),

          if (showExtra) ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _extraAnswers[q.id] ?? '',
              onChanged: (val) => _extraAnswers[q.id] = val,
              maxLines: null,
              decoration: InputDecoration(
                labelText: q.extraLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =======================
  // PAGE 6: HARAPAN + PREVIEW SKOR HIFZ
  // =======================

  Widget _buildHarapanPage() {
    // Hitung skor & kategori HIFZ dari jawaban yang sudah diisi
    final hifzResults = _calculateHifzResults();
    final hNafs = hifzResults['nafs']!;
    final hDiin = hifzResults['diin']!;
    final hAql = hifzResults['aql']!;
    final hNasl = hifzResults['nasl']!;
    final hMal = hifzResults['mal']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.flag, size: 50, color: Colors.purple.shade600),
                const SizedBox(height: 8),
                const Text(
                  'Harapan Orang Tua',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih harapan terkait penggunaan aplikasi ini\n(akan digunakan untuk pengingat doa/sholat dan filter video).',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Pilih harapan Anda:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Checkbox seperti versi lama
          _buildCustomCheckbox(
            'Edukasi doa',
            'Membantu anak belajar doa-doa harian',
            'Edukasi doa',
            Icons.menu_book,
            Colors.blue.shade100,
          ),
          _buildCustomCheckbox(
            'Pengingat doa & sholat',
            'Memberikan pengingat waktu doa dan sholat',
            'Pengingat doa & sholat',
            Icons.notifications_active,
            Colors.orange.shade100,
          ),
          _buildCustomCheckbox(
            'Video & cerita Islami',
            'Menyediakan dan memfilter video/cerita Islami yang sesuai',
            'Video & cerita Islami',
            Icons.ondemand_video,
            Colors.green.shade100,
          ),
          _buildCustomCheckbox(
            'Motivasi orang tua/perawat',
            'Memberikan motivasi dan dukungan untuk pendamping',
            'Motivasi perawat',
            Icons.favorite,
            Colors.pink.shade100,
          ),

          const SizedBox(height: 24),

          // Preview data dasar + harapan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pratinjau Data Anak:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Nama: ${nameController.text}'),
                Text('Username: ${usernameController.text}'),
                Text('Umur: ${umurController.text} tahun'),
                Text('Jenis Kelamin: ${selectedGender ?? '-'}'),
                Text('Pendidikan: ${pendidikanController.text}'),
                const SizedBox(height: 8),
                Text(
                  'Harapan dipilih: ${selectedHarapan.length} item',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (selectedHarapan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    selectedHarapan.join(', '),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Preview skor & kategori HIFZ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha:0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Skor & Kategori HIFZ:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                _buildHifzRow(
                  title: 'Hifz Ad-Diin (Spiritual)',
                  score: hDiin.score,
                  category: hDiin.category,
                  video: hDiin.videoSuggestion,
                  icon: Icons.mosque,
                  color: Colors.green.shade50,
                ),
                const SizedBox(height: 8),

                _buildHifzRow(
                  title: 'Hifz An-Nafs (Jiwa & Keselamatan)',
                  score: hNafs.score,
                  category: hNafs.category,
                  video: hNafs.videoSuggestion,
                  icon: Icons.health_and_safety,
                  color: Colors.red.shade50,
                ),
                const SizedBox(height: 8),

                _buildHifzRow(
                  title: "Hifz Al-'Aql (Akal & Perkembangan)",
                  score: hAql.score,
                  category: hAql.category,
                  video: hAql.videoSuggestion,
                  icon: Icons.psychology,
                  color: Colors.purple.shade50,
                ),
                const SizedBox(height: 8),

                _buildHifzRow(
                  title: "Hifz An-Nasl (Keturunan & Pola Asuh)",
                  score: hNasl.score,
                  category: hNasl.category,
                  video: hNasl.videoSuggestion,
                  icon: Icons.family_restroom,
                  color: Colors.orange.shade50,
                ),
                const SizedBox(height: 8),

                _buildHifzRow(
                  title: "Hifz Al-Mal (Ekonomi Keluarga)",
                  score: hMal.score,
                  category: hMal.category,
                  video: hMal.videoSuggestion,
                  icon: Icons.savings,
                  color: Colors.blue.shade50,
                ),
              ],
            ),
          ),

          if (_error != null && _currentPage == 6) _buildErrorBox(_error!),
        ],
      ),
    );
  }

  /// Card kecil per HIFZ (judul + skor + kategori + video edukasi)
  Widget _buildHifzRow({
    required String title,
    required int score,
    required String category,
    required String video,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text('Skor: $score'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(category),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Video edukasi: $video',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =======================
  // SMALL WIDGETS
  // =======================

  Widget _buildTextFieldWithIcon(
    TextEditingController controller,
    String labelText,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.blue.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCheckbox(
    String title,
    String subtitle,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        value: selectedHarapan.contains(value),
        onChanged: (bool? isSelected) {
          if (isSelected == null) return;
          _updateHarapan(value, isSelected);
        },
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black87),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  // =======================
  // KONFIGURASI PERTANYAAN
  // =======================

  List<_QuestionConfig> _buildQuestions() {
    return [
      // ============ 1. Hifz-An Nafs (pageIndex = 1) ============
      _QuestionConfig(
        id: 'pertanyaan1',
        pageIndex: 1,
        question: 'A. Keluhan utama:',
        type: QuestionType.text,
        icon: Icons.sick,
        iconColor: Colors.red.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan2',
        pageIndex: 1,
        question: 'B. Riwayat kesehatan sekarang:',
        type: QuestionType.text,
        icon: Icons.history,
        iconColor: Colors.orange.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan3',
        pageIndex: 1,
        question: 'C. Riwayat kesehatan dahulu:',
        type: QuestionType.text,
        icon: Icons.history_toggle_off,
        iconColor: Colors.deepOrange.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan4',
        pageIndex: 1,
        question: 'D. Riwayat penggunaan obat:',
        type: QuestionType.text,
        icon: Icons.medication,
        iconColor: Colors.blue.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan5',
        pageIndex: 1,
        question:
            'E. Riwayat alergi obat (jika ada, petugas akan memasang tanda alergi pada gelang pasien):',
        type: QuestionType.choice,
        options: ['Tidak ada', 'Ada'],
        icon: Icons.warning_amber,
        iconColor: Colors.red.shade100,
        showExtraFor: ['Ada'],
        extraLabel: 'Sebutkan alergi obat',
      ),
      _QuestionConfig(
        id: 'pertanyaan6',
        pageIndex: 1,
        question:
            'F. Riwayat alergi makanan (jika ada, petugas akan memasang tanda alergi pada gelang pasien):',
        type: QuestionType.choice,
        options: ['Tidak ada', 'Ada'],
        icon: Icons.restaurant,
        iconColor: Colors.green.shade100,
        showExtraFor: ['Ada'],
        extraLabel: 'Sebutkan alergi makanan',
      ),
      _QuestionConfig(
        id: 'pertanyaan7',
        pageIndex: 1,
        question: 'G1. Berapa kali anak makan dalam sehari?',
        type: QuestionType.text,
        icon: Icons.fastfood,
        iconColor: Colors.amber.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan8',
        pageIndex: 1,
        question: 'G2. Apa saja jenis makanan yang diberikan anak sehari-hari?',
        type: QuestionType.text,
        icon: Icons.lunch_dining,
        iconColor: Colors.amber.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan9',
        pageIndex: 1,
        question:
            'G3. Porsi makan (apakah anak menghabiskan makanan yang disediakan?)',
        type: QuestionType.choice,
        options: ['Selalu habis', 'Sebagian', 'Sering tidak habis'],
        icon: Icons.set_meal,
        iconColor: Colors.orange.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan10',
        pageIndex: 1,
        question:
            'G4. Kebiasaan makan khusus (apakah ada makanan khusus atau pantangan khusus pada anak?)',
        type: QuestionType.choice,
        options: ['Tidak ada', 'Ada'],
        icon: Icons.rule,
        iconColor: Colors.teal.shade100,
        showExtraFor: ['Ada'],
        extraLabel: 'Contoh: susu kedelai, seafood, dll.',
      ),
      _QuestionConfig(
        id: 'pertanyaan11',
        pageIndex: 1,
        question:
            'G5. Masalah makan (apakah anak ada masalah dalam makan sehari-hari? contoh: muntah, sulit menelan)',
        type: QuestionType.choice,
        options: ['Tidak ada', 'Ada'],
        icon: Icons.error_outline,
        iconColor: Colors.pink.shade100,
        showExtraFor: ['Ada'],
        extraLabel: 'Jelaskan masalah makan',
      ),

      // ============ 2. Hifz-Ad-Diin (pageIndex = 2) ============
      _QuestionConfig(
        id: 'pertanyaan12',
        pageIndex: 2,
        question: 'A. Saya yakin Allah akan memberikan kesembuhan.',
        type: QuestionType.choice,
        options: ['Yakin', 'Tidak yakin'],
        icon: Icons.favorite,
        iconColor: Colors.red.shade100,
        showExtraFor: ['Tidak yakin'],
        extraLabel: 'Karena...',
      ),
      _QuestionConfig(
        id: 'pertanyaan13',
        pageIndex: 2,
        question: 'B. Saya yakin Allah selalu bersama saya.',
        type: QuestionType.choice,
        options: ['Yakin', 'Tidak yakin'],
        icon: Icons.favorite_border,
        iconColor: Colors.pink.shade100,
        showExtraFor: ['Tidak yakin'],
        extraLabel: 'Karena...',
      ),
      _QuestionConfig(
        id: 'pertanyaan14',
        pageIndex: 2,
        question: 'C. Saya kesulitan melakukan sholat.',
        type: QuestionType.choice,
        options: ['Tidak', 'Ya'],
        icon: Icons.mosque,
        iconColor: Colors.green.shade100,
        showExtraFor: ['Ya'],
        extraLabel: 'Karena... sejak...',
      ),
      _QuestionConfig(
        id: 'pertanyaan15',
        pageIndex: 2,
        question:
            'D. Saya tahu cara sholat saat sakit boleh tidak berdiri dan tahu doa kesembuhan.',
        type: QuestionType.choice,
        options: ['Mengerti', 'Tidak mengerti'],
        icon: Icons.menu_book,
        iconColor: Colors.blue.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan16',
        pageIndex: 2,
        question: 'E. Saya perlu pendampingan sholat.',
        type: QuestionType.choice,
        options: ['Tidak', 'Ya'],
        icon: Icons.group,
        iconColor: Colors.orange.shade100,
        showExtraFor: ['Ya'],
        extraLabel: 'Karena... sejak...',
      ),
      _QuestionConfig(
        id: 'pertanyaan17',
        pageIndex: 2,
        question: 'F. Saya dapat melakukan sholat dengan cara:',
        type: QuestionType.choice,
        options: [
          'Berdiri',
          'Duduk',
          'Berbaring menyamping (‘Ala janbin)',
          'Terlentang (Mustalqiyan)',
          'Gerakan mata (Al-Imaa’)',
          'Membayangkan gerakan & bacaan (dalam hati)',
        ],
        icon: Icons.accessibility_new,
        iconColor: Colors.purple.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan18',
        pageIndex: 2,
        question: 'G. Saya dapat melakukan tayamum.',
        type: QuestionType.choice,
        options: ['Mampu', 'Tidak mampu'],
        icon: Icons.grain,
        iconColor: Colors.brown.shade100,
        showExtraFor: ['Tidak mampu'],
        extraLabel: 'Karena...',
      ),
      _QuestionConfig(
        id: 'pertanyaan19',
        pageIndex: 2,
        question: 'H. Saya perlu dibantu dalam melakukan tayamum.',
        type: QuestionType.choice,
        options: ['Mandiri', 'Butuh bantuan'],
        icon: Icons.pan_tool,
        iconColor: Colors.teal.shade100,
      ),

      // ============ 3. Hifz-‘Aql (pageIndex = 3) ============
      _QuestionConfig(
        id: 'pertanyaan20',
        pageIndex: 3,
        question:
            'A. Saya tahu sakit yang saya rasakan merupakan ujian dari Allah agar saya semakin disayang oleh Allah.',
        type: QuestionType.choice,
        options: ['Mengetahui', 'Tidak mengetahui'],
        icon: Icons.psychology,
        iconColor: Colors.purple.shade100,
        showExtraFor: ['Tidak mengetahui'],
        extraLabel: 'Menurut saya sakit...',
      ),
      _QuestionConfig(
        id: 'pertanyaan21',
        pageIndex: 3,
        question: 'B. Saya tahu, sehat dan sakit berasal dari:',
        type: QuestionType.choice,
        options: [
          'Ketetapan dari Allah SWT',
          'Tidak ketetapan dari Allah, namun dari...',
        ],
        icon: Icons.medical_information,
        iconColor: Colors.blue.shade100,
        showExtraFor: ['Tidak ketetapan dari Allah, namun dari...'],
        extraLabel: 'Sebutkan menurut Anda berasal dari...',
      ),
      _QuestionConfig(
        id: 'pertanyaan22',
        pageIndex: 3,
        question: 'C. Pengobatan yang pernah saya lakukan:',
        type: QuestionType.choice,
        options: [
          'Menempuh jalur medis sebagai ikhtiar dan tetap pasrah pada Allah SWT',
          'Tidak menempuh jalur medis, tapi dengan...',
        ],
        icon: Icons.local_hospital,
        iconColor: Colors.red.shade100,
        showExtraFor: ['Tidak menempuh jalur medis, tapi dengan...'],
        extraLabel: 'Sebutkan pengobatan yang dilakukan...',
      ),
      _QuestionConfig(
        id: 'pertanyaan23',
        pageIndex: 3,
        question: 'D. Saya yakin dengan pengobatan medis.',
        type: QuestionType.choice,
        options: [
          'Yakin bahwa pengobatan medis adalah jalan Allah SWT',
          'Tidak yakin, karena...',
        ],
        icon: Icons.check_circle,
        iconColor: Colors.green.shade100,
        showExtraFor: ['Tidak yakin, karena...'],
        extraLabel: 'Jelaskan alasan tidak yakin...',
      ),
      _QuestionConfig(
        id: 'pertanyaan24',
        pageIndex: 3,
        question: 'E. Saya tahu kebutuhan ibadah saat sakit.',
        type: QuestionType.choice,
        options: ['Mengetahui', 'Tidak mengetahui'],
        icon: Icons.menu_book,
        iconColor: Colors.indigo.shade100,
        showExtraFor: ['Tidak mengetahui'],
        extraLabel: 'Karena...',
      ),
      _QuestionConfig(
        id: 'pertanyaan25',
        pageIndex: 3,
        question: 'F. Saya tahu ada hikmah saat sakit.',
        type: QuestionType.choice,
        options: ['Mengetahui', 'Tidak mengetahui'],
        icon: Icons.lightbulb,
        iconColor: Colors.amber.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan26',
        pageIndex: 3,
        question: 'G. Saya tahu ada larangan dalam Islam saat sakit.',
        type: QuestionType.choice,
        options: ['Mengetahui', 'Tidak mengetahui'],
        icon: Icons.do_not_touch,
        iconColor: Colors.red.shade100,
      ),

      // ============ 4. Hifz-‘Nasl (pageIndex = 4) ============
      _QuestionConfig(
        id: 'pertanyaan27',
        pageIndex: 4,
        question:
            'A. Keluarga saya yakin bahwa sehat dan sakit merupakan ketetapan dari Allah SWT.',
        type: QuestionType.choice,
        options: ['Yakin', 'Tidak yakin, karena...'],
        icon: Icons.family_restroom,
        iconColor: Colors.blue.shade100,
        showExtraFor: ['Tidak yakin, karena...'],
        extraLabel: 'Jelaskan...',
      ),
      _QuestionConfig(
        id: 'pertanyaan28',
        pageIndex: 4,
        question: 'B. Menurut keluarga saya, sakit berasal dari...',
        type: QuestionType.choice,
        options: ['Dari Allah SWT', 'Dari hal lain...'],
        icon: Icons.healing,
        iconColor: Colors.green.shade100,
        showExtraFor: ['Dari hal lain...'],
        extraLabel: 'Sebutkan hal lain...',
      ),
      _QuestionConfig(
        id: 'pertanyaan29',
        pageIndex: 4,
        question: 'C. Ketika anak saya sakit, kami mencari pengobatan...',
        type: QuestionType.choice,
        options: [
          'Ke pelayanan kesehatan sebagai bentuk ikhtiar dan doa',
          'Tidak ke medis, tapi ke...',
        ],
        icon: Icons.local_hospital,
        iconColor: Colors.red.shade100,
        showExtraFor: ['Tidak ke medis, tapi ke...'],
        extraLabel: 'Sebutkan...',
      ),
      _QuestionConfig(
        id: 'pertanyaan30',
        pageIndex: 4,
        question:
            'D. Orang tua saya membantu saya berdoa atau membacakan doa saat saya sakit.',
        type: QuestionType.choice,
        options: ['Ya', 'Tidak, karena...'],
        icon: Icons.volunteer_activism,
        iconColor: Colors.pink.shade100,
        showExtraFor: ['Tidak, karena...'],
        extraLabel: 'Jelaskan...',
      ),
      _QuestionConfig(
        id: 'pertanyaan31',
        pageIndex: 4,
        question:
            'E. Orang tua saya membantu saya untuk tetap sholat atau beribadah meskipun saya sakit.',
        type: QuestionType.choice,
        options: ['Ya', 'Tidak'],
        icon: Icons.mosque,
        iconColor: Colors.green.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan32',
        pageIndex: 4,
        question:
            'F. Orang tua saya membiasakan saya sholat, berdoa, dan membaca Al-Qur’an.',
        type: QuestionType.choice,
        options: ['Ya, menanamkan', 'Tidak menanamkan'],
        icon: Icons.menu_book,
        iconColor: Colors.blue.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan33',
        pageIndex: 4,
        question: 'G. Saya sering diperdengarkan bacaan Al-Qur’an di rumah.',
        type: QuestionType.choice,
        options: ['Ya', 'Tidak'],
        icon: Icons.library_music,
        iconColor: Colors.teal.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan34',
        pageIndex: 4,
        question:
            'H. Saya tahu tubuh saya harus dijaga dan tidak boleh disakiti.',
        type: QuestionType.choice,
        options: ['Tahu', 'Tidak tahu'],
        icon: Icons.health_and_safety,
        iconColor: Colors.red.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan35',
        pageIndex: 4,
        question:
            'I. Saya tahu bagian tubuh mana yang tidak boleh disentuh orang lain.',
        type: QuestionType.choice,
        options: ['Tahu', 'Tidak tahu'],
        icon: Icons.pan_tool,
        iconColor: Colors.orange.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan36',
        pageIndex: 4,
        question:
            'J. Orang tua saya mengingatkan saya untuk menjaga kebersihan tubuh setiap hari.',
        type: QuestionType.choice,
        options: ['Ya', 'Tidak'],
        icon: Icons.clean_hands,
        iconColor: Colors.blue.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan37',
        pageIndex: 4,
        question:
            'K. Saya tahu perubahan tubuh seperti tumbuh tinggi, tumbuh rambut, atau menstruasi/mimpi basah adalah hal yang normal.',
        type: QuestionType.choice,
        options: ['Tahu', 'Tidak tahu'],
        icon: Icons.height,
        iconColor: Colors.green.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan38',
        pageIndex: 4,
        question:
            'L. Orang tua saya pernah menjelaskan tentang perubahan tubuh saat saya bertambah besar.',
        type: QuestionType.choice,
        options: ['Ya', 'Tidak'],
        icon: Icons.chat,
        iconColor: Colors.purple.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan39',
        pageIndex: 4,
        question:
            'M. Saya merasa aman saat dirawat, tidak ada yang menyentuh tubuh saya tanpa izin.',
        type: QuestionType.choice,
        options: ['Ya', 'Tidak'],
        icon: Icons.security,
        iconColor: Colors.red.shade100,
      ),

      // ============ 5. Hifz-‘Mal (pageIndex = 5) ============
      _QuestionConfig(
        id: 'pertanyaan40',
        pageIndex: 5,
        question: 'A. Orang yang bekerja dalam keluarga saya adalah...',
        type: QuestionType.choice,
        options: [
          'Ayah',
          'Ibu',
          'Anggota keluarga lain',
          'Tidak ada sumber tetap',
        ],
        icon: Icons.work,
        iconColor: Colors.brown.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan41',
        pageIndex: 5,
        question: 'B. Kebutuhan makan dan minum saya tercukupi setiap hari.',
        type: QuestionType.choice,
        options: ['Ya, tercukupi', 'Tidak tercukupi'],
        icon: Icons.food_bank,
        iconColor: Colors.green.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan42',
        pageIndex: 5,
        question: 'C. Orang tua saya bekerja sebagai...',
        type: QuestionType.choice,
        options: [
          'Ibu Rumah Tangga',
          'Petani/Nelayan',
          'Swasta',
          'Wiraswasta',
          'PNS/Guru/Dosen',
          'Tidak bekerja',
        ],
        icon: Icons.badge,
        iconColor: Colors.indigo.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan43',
        pageIndex: 5,
        question:
            'D. Selain sekolah, saya memiliki kegiatan lain di rumah yang menghasilkan uang.',
        type: QuestionType.choice,
        options: ['Ada, yaitu...', 'Tidak ada'],
        icon: Icons.savings,
        iconColor: Colors.teal.shade100,
        showExtraFor: ['Ada, yaitu...'],
        extraLabel: 'Sebutkan kegiatan tersebut...',
      ),
      _QuestionConfig(
        id: 'pertanyaan44',
        pageIndex: 5,
        question: 'E. Saya atau keluarga saya memiliki asuransi...',
        type: QuestionType.choice,
        options: [
          'BPJS PBI (bpjs gratis dari pemerintah)',
          'BPJS Non PBI (bpjs berbayar sendiri)',
          'Swasta (dari tempat bekerja)',
          'Tidak memiliki',
        ],
        icon: Icons.health_and_safety,
        iconColor: Colors.red.shade100,
      ),
      _QuestionConfig(
        id: 'pertanyaan45',
        pageIndex: 5,
        question:
            'F. Orang tua saya sering mengeluh masalah biaya rumah sakit.',
        type: QuestionType.choice,
        options: ['Tidak ada', 'Ada, karena...'],
        icon: Icons.warning_amber,
        iconColor: Colors.deepOrange.shade100,
        showExtraFor: ['Ada, karena...'],
        extraLabel: 'Jelaskan keluhan biaya rumah sakit...',
      ),
    ];
  }
}

// =======================
// CONFIG CLASS
// =======================

enum QuestionType { text, choice }

class _QuestionConfig {
  final String id;
  final int pageIndex; // 1..5
  final String question;
  final QuestionType type;
  final List<String> options;
  final IconData icon;
  final Color iconColor;
  final List<String> showExtraFor;
  final String? extraLabel;

  const _QuestionConfig({
    required this.id,
    required this.pageIndex,
    required this.question,
    required this.type,
    this.options = const [],
    required this.icon,
    required this.iconColor,
    this.showExtraFor = const [],
    this.extraLabel,
  });
}

class _HifzResult {
  final int score;
  final String category;
  final String videoSuggestion;

  const _HifzResult({
    required this.score,
    required this.category,
    required this.videoSuggestion,
  });
}
