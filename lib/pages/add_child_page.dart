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
  final PageController _pageController = PageController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController umurController = TextEditingController();
  final TextEditingController pendidikanController = TextEditingController();

  List<String> selectedHarapan = [];

  String? selectedGender;
  // Variabel untuk menyimpan 20 jawaban radio button
  String? doaSederhana;
  String? rutinMurottal;
  String? dikenalkanShalat;
  String? ceritaIslami;
  String? doaPerlindungan;
  String? pahamSakitUjian;
  String? hafalSuratPendek;
  String? tahuRukunIman;
  String? tahuRukunIslam;
  String? sopanSantun;
  String? jujurDalamBerkata;
  String? menghormatiOrtu;
  String? berbagiDenganSaudara;
  String? menjagaKebersihan;
  String? disiplinWaktu;
  String? menghafalDoaHarian;
  String? mengucapSalam;
  String? membacaBismillah;
  String? bersyukur;
  String? sabarMenghadapiMasalah;

  String? _error;
  int _currentPage = 0;
  bool _isLoading = false;

  final ChildAuthService _childAuthService = ChildAuthService();

  @override
  void dispose() {
    _pageController.dispose();
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    umurController.dispose();
    pendidikanController.dispose(); // 👈 NEW
    super.dispose();
  }



  void _updateHarapan(String value, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedHarapan.add(value);
      } else {
        selectedHarapan.remove(value);
      }
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _save() async {
    if (_isLoading) return;

    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final umur = umurController.text.trim();
    final pendidikan = pendidikanController.text.trim();

    // Validasi input dasar
    if (name.isEmpty || username.isEmpty || password.isEmpty || umur.isEmpty) {
      setState(() {
        _error = 'Nama, username, password, dan umur wajib diisi';
      });
      _pageController.jumpToPage(0);
      return;
    }

    // Validasi format username
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username)) {
      setState(() {
        _error = 'Username hanya boleh mengandung huruf dan angka';
      });
      _pageController.jumpToPage(0);
      return;
    }

    // Validasi password
    if (password.length < 6) {
      setState(() {
        _error = 'Password minimal 6 karakter';
      });
      _pageController.jumpToPage(0);
      return;
    }

    // ✅ Validasi jenis kelamin
    if (selectedGender == null || selectedGender!.isEmpty) {
      setState(() {
        _error = 'Jenis kelamin wajib dipilih';
      });
      _pageController.jumpToPage(0);
      return;
    }

    // ✅ Validasi pendidikan
    if (pendidikan.isEmpty) {
      setState(() {
        _error = 'Pendidikan anak wajib diisi';
      });
      _pageController.jumpToPage(0);
      return;
    }

    // Validasi 20 pertanyaan
    if (!_validateAllQuestions()) {
      setState(() {
        _error = 'Semua 20 pertanyaan di halaman Pendidikan Agama wajib diisi';
      });
      _pageController.jumpToPage(1);
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    // Validasi username unik
    try {
      final isUsernameAvailable = await _childAuthService.isUsernameAvailable(username);
      if (!isUsernameAvailable) {
        setState(() {
          _error = 'Username "$username" sudah digunakan';
          _isLoading = false;
        });
        _pageController.jumpToPage(0);
        return;
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memeriksa username: $e';
        _isLoading = false;
      });
      _pageController.jumpToPage(0);
      return;
    }

    // Panggil cubit untuk menambah anak
    context.read<ChildCubit>().addChild(
      parentId: widget.parentId,
      name: name,
      username: username,
      password: password,
      umur: umur,
      jenisKelamin: selectedGender!,     // 👈 NEW
      pendidikan: pendidikan,
      // 20 pertanyaan
      doaSederhana: doaSederhana!,
      rutinMurottal: rutinMurottal!,
      dikenalkanShalat: dikenalkanShalat!,
      ceritaIslami: ceritaIslami!,
      doaPerlindungan: doaPerlindungan!,
      pahamSakitUjian: pahamSakitUjian!,
      hafalSuratPendek: hafalSuratPendek!,
      tahuRukunIman: tahuRukunIman!,
      tahuRukunIslam: tahuRukunIslam!,
      sopanSantun: sopanSantun!,
      jujurDalamBerkata: jujurDalamBerkata!,
      menghormatiOrtu: menghormatiOrtu!,
      berbagiDenganSaudara: berbagiDenganSaudara!,
      menjagaKebersihan: menjagaKebersihan!,
      disiplinWaktu: disiplinWaktu!,
      menghafalDoaHarian: menghafalDoaHarian!,
      mengucapSalam: mengucapSalam!,
      membacaBismillah: membacaBismillah!,
      bersyukur: bersyukur!,
      sabarMenghadapiMasalah: sabarMenghadapiMasalah!,
      harapan: selectedHarapan,
    );
  }

  bool _validateAllQuestions() {
    return doaSederhana != null &&
        rutinMurottal != null &&
        dikenalkanShalat != null &&
        ceritaIslami != null &&
        doaPerlindungan != null &&
        pahamSakitUjian != null &&
        hafalSuratPendek != null &&
        tahuRukunIman != null &&
        tahuRukunIslam != null &&
        sopanSantun != null &&
        jujurDalamBerkata != null &&
        menghormatiOrtu != null &&
        berbagiDenganSaudara != null &&
        menjagaKebersihan != null &&
        disiplinWaktu != null &&
        menghafalDoaHarian != null &&
        mengucapSalam != null &&
        membacaBismillah != null &&
        bersyukur != null &&
        sabarMenghadapiMasalah != null;
  }

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
          // Success - kembali ke halaman sebelumnya
          setState(() {
            _isLoading = false;
          });

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
            // Progress Indicator
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(3, (index) {
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

            // Page Indicator
            Text(
              'Langkah ${_currentPage + 1} dari 3',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // Page 1: Data Dasar
                  _buildDataDasarPage(),

                  // Page 2: Pendidikan Agama (20 pertanyaan)
                  _buildPendidikanAgamaPage(),

                  // Page 3: Harapan
                  _buildHarapanPage(),
                ],
              ),
            ),

            // Navigation Buttons
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                        : ElevatedButton(
                      onPressed: _currentPage < 2 ? _nextPage : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentPage < 2 ? 'Lanjut' : 'Simpan Anak',
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

  Widget _buildDataDasarPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan ikon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.child_care,
                  size: 50,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Data Dasar Anak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi informasi dasar tentang anak Anda',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Input Fields dengan desain yang lebih menarik
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

          // 👇 NEW: Jenis Kelamin
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
                DropdownMenuItem(
                  value: 'Laki-laki',
                  child: Text('Laki-laki'),
                ),
                DropdownMenuItem(
                  value: 'Perempuan',
                  child: Text('Perempuan'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGender = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // 👇 NEW: Pendidikan
          _buildTextFieldWithIcon(
            pendidikanController,
            'Pendidikan Anak',
            Icons.school,
          ),

          const SizedBox(height: 16),

          // Error message
          if (_error != null)
            Container(
              width: double.infinity,
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
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendidikanAgamaPage() {
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
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.mosque,
                  size: 50,
                  color: Colors.green.shade600,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pendidikan Agama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bagaimana perkembangan pendidikan agama anak Anda?',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 20 Pertanyaan dengan Radio Button
          _buildRadioQuestion(
            '1. Apakah anak sudah diajarkan doa sederhana?',
            doaSederhana,
            ['Ya', 'Tidak', 'Kadang'],
            Icons.front_hand,
            Colors.orange.shade100,
                (value) => setState(() => doaSederhana = value),
          ),

          _buildRadioQuestion(
            '2. Apakah anak rutin mendengar bacaan Al-Qur\'an / murottal?',
            rutinMurottal,
            ['Rutin', 'Tidak', 'Kadang'],
            Icons.music_note,
            Colors.purple.shade100,
                (value) => setState(() => rutinMurottal = value),
          ),

          _buildRadioQuestion(
            '3. Apakah anak sudah dikenalkan shalat sesuai usia?',
            dikenalkanShalat,
            ['Ya', 'Belum'],
            Icons.people,
            Colors.blue.shade100,
                (value) => setState(() => dikenalkanShalat = value),
          ),

          _buildRadioQuestion(
            '4. Apakah anak dikenalkan dengan cerita Islami?',
            ceritaIslami,
            ['Rutin', 'Kadang', 'Tidak'],
            Icons.book,
            Colors.green.shade100,
                (value) => setState(() => ceritaIslami = value),
          ),

          _buildRadioQuestion(
            '5. Apakah orang tua membacakan doa perlindungan?',
            doaPerlindungan,
            ['Ya', 'Kadang', 'Tidak'],
            Icons.security,
            Colors.red.shade100,
                (value) => setState(() => doaPerlindungan = value),
          ),

          _buildRadioQuestion(
            '6. Apakah anak diberi pemahaman sederhana bahwa sakit adalah ujian?',
            pahamSakitUjian,
            ['Ya', 'Tidak'],
            Icons.health_and_safety,
            Colors.teal.shade100,
                (value) => setState(() => pahamSakitUjian = value),
          ),

          _buildRadioQuestion(
            '7. Apakah anak sudah hafal surat-surat pendek (Al-Fatihah, Al-Ikhlas, dll)?',
            hafalSuratPendek,
            ['Ya', 'Sedang belajar', 'Belum'],
            Icons.library_books,
            Colors.indigo.shade100,
                (value) => setState(() => hafalSuratPendek = value),
          ),

          _buildRadioQuestion(
            '8. Apakah anak tahu rukun iman?',
            tahuRukunIman,
            ['Ya', 'Sedikit', 'Belum'],
            Icons.emoji_people,
            Colors.cyan.shade100,
                (value) => setState(() => tahuRukunIman = value),
          ),

          _buildRadioQuestion(
            '9. Apakah anak tahu rukun islam?',
            tahuRukunIslam,
            ['Ya', 'Sedikit', 'Belum'],
            Icons.mosque,
            Colors.amber.shade100,
                (value) => setState(() => tahuRukunIslam = value),
          ),

          _buildRadioQuestion(
            '10. Apakah anak menunjukkan sikap sopan santun?',
            sopanSantun,
            ['Selalu', 'Kadang', 'Perlu bimbingan'],
            Icons.emoji_emotions,
            Colors.lightGreen.shade100,
                (value) => setState(() => sopanSantun = value),
          ),

          _buildRadioQuestion(
            '11. Apakah anak jujur dalam berkata?',
            jujurDalamBerkata,
            ['Selalu', 'Kadang', 'Perlu diajarkan'],
            Icons.psychology,
            Colors.deepOrange.shade100,
                (value) => setState(() => jujurDalamBerkata = value),
          ),

          _buildRadioQuestion(
            '12. Apakah anak menghormati orang tua?',
            menghormatiOrtu,
            ['Ya', 'Kadang', 'Perlu diingatkan'],
            Icons.family_restroom,
            Colors.pink.shade100,
                (value) => setState(() => menghormatiOrtu = value),
          ),

          _buildRadioQuestion(
            '13. Apakah anak mau berbagi dengan saudara/teman?',
            berbagiDenganSaudara,
            ['Selalu', 'Kadang', 'Masih egois'],
            Icons.share,
            Colors.brown.shade100,
                (value) => setState(() => berbagiDenganSaudara = value),
          ),

          _buildRadioQuestion(
            '14. Apakah anak menjaga kebersihan diri dan lingkungan?',
            menjagaKebersihan,
            ['Ya', 'Kadang', 'Perlu diingatkan'],
            Icons.clean_hands,
            Colors.lime.shade100,
                (value) => setState(() => menjagaKebersihan = value),
          ),

          _buildRadioQuestion(
            '15. Apakah anak disiplin dalam waktu bermain dan belajar?',
            disiplinWaktu,
            ['Ya', 'Kadang', 'Masih sulit'],
            Icons.access_time,
            Colors.deepPurple.shade100,
                (value) => setState(() => disiplinWaktu = value),
          ),

          _buildRadioQuestion(
            '16. Apakah anak menghafal doa-doa harian?',
            menghafalDoaHarian,
            ['Banyak', 'Beberapa', 'Belum'],
            Icons.auto_stories,
            Colors.blueGrey.shade100,
                (value) => setState(() => menghafalDoaHarian = value),
          ),

          _buildRadioQuestion(
            '17. Apakah anak mengucap salam ketika bertemu?',
            mengucapSalam,
            ['Selalu', 'Kadang', 'Perlu diingatkan'],
            Icons.waving_hand,
            Colors.orange.shade100,
                (value) => setState(() => mengucapSalam = value),
          ),

          _buildRadioQuestion(
            '18. Apakah anak membaca bismillah sebelum melakukan aktivitas?',
            membacaBismillah,
            ['Selalu', 'Kadang', 'Perlu diingatkan'],
            Icons.create,
            Colors.green.shade100,
                (value) => setState(() => membacaBismillah = value),
          ),

          _buildRadioQuestion(
            '19. Apakah anak menunjukkan sikap bersyukur?',
            bersyukur,
            ['Selalu', 'Kadang', 'Perlu diajarkan'],
            Icons.thumb_up,
            Colors.yellow.shade100,
                (value) => setState(() => bersyukur = value),
          ),

          _buildRadioQuestion(
            '20. Apakah anak sabar menghadapi masalah/kesulitan?',
            sabarMenghadapiMasalah,
            ['Ya', 'Kadang', 'Masih rewel'],
            Icons.self_improvement,
            Colors.purple.shade100,
                (value) => setState(() => sabarMenghadapiMasalah = value),
          ),

          const SizedBox(height: 16),

          // Error message
          if (_error != null && _currentPage == 1)
            Container(
              width: double.infinity,
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
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHarapanPage() {
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
                Icon(
                  Icons.flag,
                  size: 50,
                  color: Colors.purple.shade600,
                ),
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
                  'Apa yang Anda harapkan dari aplikasi ini?',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
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

          // Checkbox dengan desain yang lebih menarik
          _buildCustomCheckbox(
            'Edukasi doa',
            'Membantu anak belajar doa-doa harian',
            'Edukasi doa',
            Icons.handshake,
            Colors.blue.shade100,
          ),

          _buildCustomCheckbox(
            'Pengingat doa',
            'Mengingatkan waktu doa dan ibadah',
            'Pengingat doa',
            Icons.notifications,
            Colors.orange.shade100,
          ),

          _buildCustomCheckbox(
            'Cerita Islam',
            'Menyediakan cerita-cerita Islami yang mendidik',
            'Cerita Islam',
            Icons.library_books,
            Colors.green.shade100,
          ),

          _buildCustomCheckbox(
            'Motivasi perawat',
            'Memberikan motivasi dan dukungan',
            'Motivasi perawat',
            Icons.favorite,
            Colors.pink.shade100,
          ),

          const SizedBox(height: 24),

          // Preview data yang akan disimpan
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
                  'Pratinjau Data:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Nama: ${nameController.text}'),
                Text('Username: ${usernameController.text}'),
                Text('Umur: ${umurController.text} tahun'),
                const SizedBox(height: 8),
                Text(
                  'Harapan dipilih: ${selectedHarapan.length} item',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildRadioQuestion(
      String question,
      String? selectedValue,
      List<String> options,
      IconData icon,
      Color iconColor,
      ValueChanged<String?> onChanged,
      ) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black87, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: selectedValue,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
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
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        value: selectedHarapan.contains(value),
        onChanged: (bool? isSelected) {
          _updateHarapan(value, isSelected!);
        },
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}