import 'package:e_spirit_care/cubit/auth_cubit.dart';
import 'package:e_spirit_care/pages/video_player_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/child_model.dart';
import '../models/scheduled_reminder_model.dart';
import '../models/video_model.dart';
import '../services/child_services.dart';
import '../services/video_service.dart';
import '../services/reminder_service.dart';
import '../theme/theme.dart';

class VideoRecommendationsPage extends StatefulWidget {
  final ChildModel child;

  const VideoRecommendationsPage({super.key, required this.child});

  @override
  State<VideoRecommendationsPage> createState() =>
      _VideoRecommendationsPageState();
}

class _VideoRecommendationsPageState extends State<VideoRecommendationsPage>
    with TickerProviderStateMixin {
  final VideoService videoService = VideoService();
  late List<VideoModel> recommendations;

  // ===== HIFZ Data =====
  late int hifzNafsScore;
  late int hifzDiinScore;
  late int hifzAqlScore;
  late int hifzNaslScore;
  late int hifzMalScore;

  late String hifzNafsCategory;
  late String hifzDiinCategory;
  late String hifzAqlCategory;
  late String hifzNaslCategory;
  late String hifzMalCategory;

  late int totalScore;
  late String overallCategory;

  // ===== Animation Controllers =====
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // ===== Reminder State =====
  bool hasPrayerReminder = false;
  bool reminderScheduled = false;
  List<ScheduledReminder> _scheduledReminders = [];
  bool _isLoadingReminders = false;

  // ===== Nurse feedback state =====
  final TextEditingController _nurseNoteController = TextEditingController();
  String? _selectedDiagnosis;

  final Map<String, TextEditingController> _hifzNoteControllers = {
    'adDiin': TextEditingController(),
    'anNafs': TextEditingController(),
    'alAql': TextEditingController(),
    'anNasl': TextEditingController(),
    'alMal': TextEditingController(),
  };

  final Map<String, String?> _hifzSelectedDiagnosis = {
    'adDiin': null,
    'anNafs': null,
    'alAql': null,
    'anNasl': null,
    'alMal': null,
  };

  Future<void> _loadExistingHifzDiagnoses() async {
    try {
      final map = await ChildServices().getHifzDiagnosesForChild(
        parentId: widget.child.parentId,
        childId: widget.child.id,
      );

      setState(() {
        map.forEach((aspectKey, data) {
          final diagnosis = data['diagnosis'] as String?;
          final note = data['note'] as String?;

          if (diagnosis != null && diagnosis.isNotEmpty) {
            _hifzSelectedDiagnosis[aspectKey] = diagnosis;
          }
          if (note != null && note.isNotEmpty) {
            _hifzNoteControllers[aspectKey]?.text = note;
          }
        });
      });
    } catch (e) {
      debugPrint('❌ Gagal load HIFZ diagnosis: $e');
    }
  }


  void _showDiagnosisBottomSheet(String aspectKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pilih Diagnosa SDKI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _diagnosisOptions.length,
                itemBuilder: (context, index) {
                  final diagnosis = _diagnosisOptions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        diagnosis,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                      onTap: () {
                        setState(() {
                          _hifzSelectedDiagnosis[aspectKey] = diagnosis;
                        });
                        Navigator.pop(context);

                        // Show confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Diagnosa dipilih: $diagnosis'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
    _loadExistingHifzDiagnoses();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduledReminders(fromInit: true);
    });
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleController.forward();
    _fadeController.forward();
  }

  void _initializeData() {
    hifzNafsScore = widget.child.hifzAnNafsScore;
    hifzDiinScore = widget.child.hifzAdDiinScore;
    hifzAqlScore = widget.child.hifzAlAqlScore;
    hifzNaslScore = widget.child.hifzAnNaslScore;
    hifzMalScore = widget.child.hifzAlMalScore;

    hifzNafsCategory = widget.child.hifzAnNafsCategory;
    hifzDiinCategory = widget.child.hifzAdDiinCategory;
    hifzAqlCategory = widget.child.hifzAlAqlCategory;
    hifzNaslCategory = widget.child.hifzAnNaslCategory;
    hifzMalCategory = widget.child.hifzAlMalCategory;

    totalScore =
        hifzNafsScore +
        hifzDiinScore +
        hifzAqlScore +
        hifzNaslScore +
        hifzMalScore;
    overallCategory = _getOverallCategory();
    recommendations = videoService.getVideoRecommendations(widget.child);
    hasPrayerReminder = _checkPrayerReminder();
  }

  final List<String> _diagnosisOptions = [
    'Distres Spiritual (D.0128)',
    'Risiko Distres Spiritual',
    'Kesiapan Peningkatan Kesejahteraan Spiritual (D.0127)',
    'Defisit Pengetahuan (D.0016)',
    'Kesiapan Peningkatan Pengetahuan (D.0017)',
    'Ketidakpatuhan terhadap Regimen Terapeutik (D.0053)',
    'Perilaku Mencari Pengobatan Tidak Efektif (D.0051)',
    'Gangguan Pemeliharaan Spiritual (D.0126)',
    'Koping Keluarga Tidak Efektif (D.0107)',
    'Risiko Kekerasan Seksual (D.0111)',
    'Risiko Keterlambatan Tumbuh Kembang (D.0109)',
    'Defisit Perawatan Diri (D.0108)',
    'Pola Komunikasi Keluarga Tidak Efektif (D.0106)',
    'Distres Finansial (D.0110)',
    'Ketidakefektifan Pola Keluarga (D.0103)',
    'Risiko Ketidakseimbangan Nutrisi (D.0002)',
    'Risiko Ketidakmampuan Mengakses Pelayanan Kesehatan (D.0105)',
    'Kesiapan Peningkatan Manajemen Ekonomi Keluarga (D.0111)',
  ];

  String _getOverallCategory() {
    final levels = [
      _aspectLevel(hifzNafsCategory),
      _aspectLevel(hifzDiinCategory),
      _aspectLevel(hifzAqlCategory),
      _aspectLevel(hifzNaslCategory),
      _aspectLevel(hifzMalCategory),
    ];
    final avg = levels.reduce((a, b) => a + b) / levels.length;
    if (avg >= 1.5) return 'Tinggi';
    if (avg >= 0.8) return 'Sedang';
    return 'Rendah';
  }

  int _aspectLevel(String category) {
    final text = category.toLowerCase();
    if (text.contains('aman') ||
        text.contains('kesejahteraan') ||
        text.contains('perkembangan baik') ||
        text.contains('pola asuh baik') ||
        text.contains('kecukupan ekonomi baik')) {
      return 2;
    }
    if (text.contains('risiko')) return 1;
    return 0;
  }

  bool _checkPrayerReminder() {
    return widget.child.harapan.any(
      (h) =>
          h.toLowerCase().contains('pengingat') ||
          h.toLowerCase().contains('doa'),
    );
  }

  // ===== MODERN UI COMPONENTS =====

  Widget _buildModernProfileCard() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kPrimaryColor.withValues(alpha:0.9),
                  kPrimaryColor.withValues(alpha:0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha:0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Animated Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha:0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha:0.2),
                            Colors.white.withValues(alpha:0.1),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.child_care,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.child.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.child.umur} tahun • ${widget.child.harapan.length} harapan',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha:0.9),
                          fontSize: 14,
                        ),
                      ),
                      if (hasPrayerReminder && reminderScheduled) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_active,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Reminder aktif',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasPrayerReminder)
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.white.withValues(alpha:0.8),
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernScoreOverview() {
    final categoryColor = _getCategoryColor(overallCategory);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor.withValues(alpha:0.9),
                  categoryColor.withValues(alpha:0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withValues(alpha:0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated Score Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: totalScore / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withValues(alpha:0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$totalScore',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Skor Total',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha:0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Modern Stats Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.8,
                  children: [
                    _buildModernStatItem(
                      'Kategori',
                      overallCategory,
                      Icons.assessment,
                      Colors.white,
                    ),
                    _buildModernStatItem(
                      'Level',
                      _getLevel(overallCategory),
                      Icons.star,
                      Colors.white,
                    ),
                    _buildModernStatItem(
                      'Status',
                      _getStatus(),
                      Icons.emoji_events,
                      Colors.white,
                    ),
                  ],
                ),
                // const SizedBox(height: 10),

                // Animated Description Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getCategoryDescription(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
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
      },
    );
  }

  Widget _buildModernStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16), // Reduced size
          ),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10, // Reduced font size
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2), // Reduced spacing
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha:0.9),
              fontSize: 10, // Reduced font size
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernHifzAspectsCard(bool isNurse) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha:0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
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
                        color: kPrimaryColor.withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.analytics,
                        color: kPrimaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Aspek HIFZ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Analisis komprehensif perkembangan anak',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),

                _buildModernHifzAspectItemWithForm(
                  aspectKey: 'adDiin',
                  title: 'Hifz Ad-Diin',
                  subtitle: 'Spiritual & Keagamaan',
                  score: hifzDiinScore,
                  category: hifzDiinCategory,
                  icon: Icons.mosque,
                  color: Colors.green,
                  isNurse: isNurse,
                ),
                const SizedBox(height: 16),

                _buildModernHifzAspectItemWithForm(
                  aspectKey: 'anNafs',
                  title: 'Hifz An-Nafs',
                  subtitle: 'Jiwa & Keselamatan',
                  score: hifzNafsScore,
                  category: hifzNafsCategory,
                  icon: Icons.health_and_safety,
                  color: Colors.red,
                  isNurse: isNurse,
                ),
                const SizedBox(height: 16),

                _buildModernHifzAspectItemWithForm(
                  aspectKey: 'alAql',
                  title: "Hifz Al-'Aql",
                  subtitle: 'Akal & Perkembangan',
                  score: hifzAqlScore,
                  category: hifzAqlCategory,
                  icon: Icons.psychology,
                  color: Colors.purple,
                  isNurse: isNurse,
                ),
                const SizedBox(height: 16),

                _buildModernHifzAspectItemWithForm(
                  aspectKey: 'anNasl',
                  title: 'Hifz An-Nasl',
                  subtitle: 'Keturunan & Pola Asuh',
                  score: hifzNaslScore,
                  category: hifzNaslCategory,
                  icon: Icons.family_restroom,
                  color: Colors.orange,
                  isNurse: isNurse,
                ),
                const SizedBox(height: 16),

                _buildModernHifzAspectItemWithForm(
                  aspectKey: 'alMal',
                  title: 'Hifz Al-Mal',
                  subtitle: 'Ekonomi Keluarga',
                  score: hifzMalScore,
                  category: hifzMalCategory,
                  icon: Icons.savings,
                  color: Colors.blue,
                  isNurse: isNurse,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernHifzAspectItemWithForm({
    required String aspectKey,
    required String title,
    required String subtitle,
    required int score,
    required String category,
    required IconData icon,
    required Color color,
    required bool isNurse,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha:0.05), color.withValues(alpha:0.02)],
        ),
        border: Border.all(color: color.withValues(alpha:0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan progress bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            category,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),

          // Progress Bar
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / 20,
            backgroundColor: color.withValues(alpha:0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '${(score / 20 * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (isNurse) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            Text(
              'Diagnosa & Catatan Perawat',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown / picker diagnosa (buka bottom sheet)
            TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: _hifzSelectedDiagnosis[aspectKey] ?? '',
              ),
              decoration: InputDecoration(
                hintText: 'Pilih diagnosa SDKI',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () => _showDiagnosisBottomSheet(aspectKey),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _hifzNoteControllers[aspectKey],
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Catatan klinis untuk $title...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha:0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha:0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _saveHifzDiagnosis(
                    aspectKey: aspectKey,
                    aspectName: title,
                    score: score,
                    category: category,
                  ),
                  icon: const Icon(
                    Icons.save_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Simpan Diagnosa',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // 👇 MODE ORTU / ANAK: hanya lihat diagnosa + catatan
            const SizedBox(height: 12),
            if ((_hifzSelectedDiagnosis[aspectKey] ?? '').isNotEmpty ||
                (_hifzNoteControllers[aspectKey]?.text.isNotEmpty ?? false))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha:0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnosa Perawat',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if ((_hifzSelectedDiagnosis[aspectKey] ?? '').isNotEmpty)
                      Text(
                        _hifzSelectedDiagnosis[aspectKey]!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (_hifzNoteControllers[aspectKey]?.text.isNotEmpty ??
                        false) ...[
                      const SizedBox(height: 6),
                      Text(
                        _hifzNoteControllers[aspectKey]!.text,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernReminderCard() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: reminderScheduled
                    ? [
                        Colors.green.withValues(alpha:0.9),
                        Colors.lightGreen.withValues(alpha:0.7),
                      ]
                    : [
                        Colors.blue.withValues(alpha:0.9),
                        Colors.lightBlue.withValues(alpha:0.7),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (reminderScheduled ? Colors.green : Colors.blue)
                      .withValues(alpha:0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminderScheduled
                                ? 'Reminder Aktif 🎯'
                                : 'Mengaktifkan Reminder...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Berdasarkan harapan spiritual anak',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!reminderScheduled)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildModernReminderChip(
                      'Sholat 5 Waktu',
                      Icons.mosque,
                      Colors.white,
                    ),
                    _buildModernReminderChip(
                      'Doa Pagi',
                      Icons.wb_sunny,
                      Colors.white,
                    ),
                    _buildModernReminderChip(
                      'Doa Sore',
                      Icons.nightlight,
                      Colors.white,
                    ),
                    _buildModernReminderChip(
                      'Baca Quran',
                      Icons.menu_book,
                      Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: reminderScheduled
                              ? _viewReminderSchedule
                              : null,
                          icon: const Icon(Icons.schedule, size: 18),
                          label: const Text('Lihat Jadwal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: reminderScheduled
                                ? Colors.green
                                : Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                        onPressed: _showReminderInfo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernReminderChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernVideoSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha:0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.video_library,
                            color: kPrimaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Video Rekomendasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${recommendations.length} video',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Konten edukasi personalized berdasarkan analisis HIFZ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),

                recommendations.isEmpty
                    ? _buildModernEmptyVideos()
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.67,
                            ),
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final video = recommendations[index];
                          return _buildModernVideoCard(video);
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernVideoCard(VideoModel video) {
    final categoryColor = _getCategoryColor(overallCategory);

    return GestureDetector(
      onTap: () => _showVideoDetail(video),
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha:0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail dengan gradient overlay
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          categoryColor.withValues(alpha:0.3),
                          categoryColor.withValues(alpha:0.1),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Play button center
                        Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: categoryColor.withValues(alpha:0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: categoryColor,
                              size: 30,
                            ),
                          ),
                        ),
                        // Top gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha:0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Duration badge
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha:0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              video.duration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 18,),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                video.category,
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernEmptyVideos() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.video_library_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Video Rekomendasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Video akan muncul berdasarkan hasil analisis HIFZ yang mendalam',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryColor.withValues(alpha:0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  recommendations = videoService.getVideoRecommendations(
                    widget.child,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Refresh Rekomendasi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== BUILD METHOD =====
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        bool isNurse = false;
        if (state is AuthSuccess) {
          isNurse = state.user.role.toLowerCase() == 'perawat';
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: CustomScrollView(
            slivers: [
              // Modern App Bar dengan efek glassmorphism
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Rekomendasi Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha:0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPrimaryColor, kPrimaryColor.withValues(alpha:0.8)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated background elements
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: -20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: _isLoadingReminders
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                    onPressed: _isLoadingReminders ? null : _refreshReminders,
                  ),
                ],
              ),

              // Main Content
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _buildModernProfileCard(),
                  _buildModernScoreOverview(),
                  _buildModernHifzAspectsCard(isNurse),

                  if (hasPrayerReminder) _buildModernReminderCard(),

                  _buildModernVideoSection(),
                  const SizedBox(height: 40),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _nurseNoteController.dispose();
    for (final c in _hifzNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ===== HELPER METHODS =====
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Tinggi':
        return Colors.green;
      case 'Sedang':
        return Colors.orange;
      case 'Rendah':
        return Colors.red;
      default:
        return kPrimaryColor;
    }
  }

  String _getLevel(String category) {
    switch (category) {
      case 'Tinggi':
        return 'Lanjutan';
      case 'Sedang':
        return 'Menengah';
      case 'Rendah':
        return 'Dasar';
      default:
        return '-';
    }
  }

  String _getStatus() {
    switch (overallCategory) {
      case 'Tinggi':
        return 'Optimal';
      case 'Sedang':
        return 'Perlu Perhatian';
      case 'Rendah':
        return 'Butuh Bantuan';
      default:
        return '-';
    }
  }

  String _getCategoryDescription() {
    switch (overallCategory) {
      case 'Tinggi':
        return 'Perkembangan aspek HIFZ anak relatif baik. Pertahankan konsistensi dalam pendampingan! 🎉';
      case 'Sedang':
        return 'Ada beberapa area yang perlu ditingkatkan. Fokus pada aspek yang membutuhkan perhatian khusus. 💪';
      case 'Rendah':
        return 'Perlu pendampingan intensif pada aspek spiritual, jiwa, pola asuh, atau ekonomi. 🌱';
      default:
        return 'Terus pantau perkembangan anak secara berkala.';
    }
  }

  // ===== REMINDER METHODS =====
  Future<void> _setupReminders() async {
    if (!hasPrayerReminder || reminderScheduled) return;
    try {
      await ReminderService.initialize();
      await ReminderService.schedulePrayerReminders();
      if (!mounted) return;
      setState(() => reminderScheduled = true);
      _showReminderConfirmation();
    } catch (e) {
      _showReminderError();
    }
  }

  Future<void> _loadScheduledReminders({bool fromInit = false}) async {
    if (!mounted) return;
    setState(() => _isLoadingReminders = true);
    try {
      final rawReminders = await ReminderService.getScheduledReminders();
      if (!mounted) return;
      final mapped = rawReminders
          .map<ScheduledReminder>(
            (reminder) => ScheduledReminder(
              id: reminder['id'] as int,
              title: reminder['title'] as String? ?? '',
              body: reminder['body'] as String? ?? '',
              type: reminder['type'] as String? ?? '',
              scheduledTime: reminder['scheduledTime'] as String? ?? '',
            ),
          )
          .toList();
      final hasAny = mapped.isNotEmpty;
      setState(() {
        _scheduledReminders = mapped;
        reminderScheduled = hasAny;
      });
      if (fromInit && hasPrayerReminder && !hasAny) {
        await _setupReminders();
      }
    } catch (e) {
      debugPrint('❌ Gagal memuat scheduled reminders: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingReminders = false);
      }
    }
  }

  Future<void> _refreshReminders() async {
    await _loadScheduledReminders();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reminder diperbarui'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showReminderConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Reminder Doa & Sholat Diaktifkan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Untuk ${widget.child.name}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Lihat Jadwal',
          textColor: Colors.white,
          onPressed: () => _viewReminderSchedule(),
        ),
      ),
    );
  }

  void _showReminderError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Gagal mengaktifkan reminder. Coba lagi nanti.'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _viewReminderSchedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Reminder',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          'Untuk ${widget.child.name}',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.blue.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildScheduleCategory('🕌 Waktu Sholat', [
                    _buildScheduleItem(
                      '05:30',
                      'Subuh',
                      Icons.mosque,
                      Colors.green,
                    ),
                    _buildScheduleItem(
                      '12:00',
                      'Dzuhur',
                      Icons.mosque,
                      Colors.green,
                    ),
                    _buildScheduleItem(
                      '15:30',
                      'Ashar',
                      Icons.mosque,
                      Colors.green,
                    ),
                    _buildScheduleItem(
                      '18:00',
                      'Maghrib',
                      Icons.mosque,
                      Colors.green,
                    ),
                    _buildScheduleItem(
                      '19:30',
                      'Isya',
                      Icons.mosque,
                      Colors.green,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildScheduleCategory('🙏 Waktu Doa', [
                    _buildScheduleItem(
                      '07:00',
                      'Doa Pagi',
                      Icons.wb_sunny,
                      Colors.orange,
                    ),
                    _buildScheduleItem(
                      '18:30',
                      'Doa Sore',
                      Icons.nightlight,
                      Colors.purple,
                    ),
                    _buildScheduleItem(
                      '21:00',
                      'Doa Tidur',
                      Icons.bedtime,
                      Colors.blue,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.celebration,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reminder Aktif!',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.child.name} akan mendapatkan notifikasi sesuai jadwal di atas.',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _manageReminders,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.notifications_off, size: 18),
                        SizedBox(width: 8),
                        Text('Nonaktifkan Semua Reminder'),
                      ],
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

  Widget _buildScheduleCategory(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildScheduleItem(
    String time,
    String activity,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'AKTIF',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _manageReminders() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_off,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nonaktifkan Reminder?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Reminder doa dan sholat untuk ${widget.child.name} akan dinonaktifkan. Anda dapat mengaktifkannya kembali kapan saja.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ReminderService.cancelAllReminders();
                        if (!mounted) return;
                        setState(() {
                          reminderScheduled = false;
                          _scheduledReminders.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Reminder doa & sholat telah dinonaktifkan',
                            ),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Nonaktifkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReminderInfo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.lightBlue.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tentang Reminder',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Reminder doa dan sholat diaktifkan secara otomatis berdasarkan harapan yang tercatat untuk ${widget.child.name}.',
                style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildInfoItem('⏰', 'Jadwal otomatis sesuai waktu sholat'),
              _buildInfoItem('🔔', 'Notifikasi akan muncul tepat waktu'),
              _buildInfoItem('📱', 'Dapat diatur ulang di pengaturan'),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Mengerti',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ===== VIDEO METHODS =====
  void _showVideoDetail(VideoModel video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getCategoryColor(overallCategory).withValues(alpha:0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: _getCategoryColor(overallCategory),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detail Video',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          overallCategory,
                        ).withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              overallCategory,
                            ).withValues(alpha:0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: _getCategoryColor(overallCategory),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      video.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMetaItem(Icons.timer, video.duration),
                        const SizedBox(width: 16),
                        _buildMetaItem(Icons.category, video.category),
                        const SizedBox(width: 16),
                        _buildMetaItem(Icons.emoji_events, overallCategory),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Deskripsi Video',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getVideoDescription(video.title),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _playVideo(video);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getCategoryColor(overallCategory),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 20),
                          SizedBox(width: 6),
                          Text('Putar Video'),
                        ],
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

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _playVideo(VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerPage(video: video)),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.white),
            const SizedBox(width: 8),
            Text('Memutar: ${video.title}'),
          ],
        ),
        backgroundColor: _getCategoryColor(overallCategory),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getVideoDescription(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('doa')) {
      return 'Video ini mengajarkan doa-doa harian yang mudah dihafal oleh anak. Dilengkapi visual menarik dan penjelasan sederhana tentang makna doa.';
    } else if (lower.contains('kisah') || lower.contains('cerita')) {
      return 'Kisah inspiratif dari sejarah Islam yang disajikan dengan animasi. Membantu anak memahami nilai moral dan akhlak mulia.';
    } else {
      return 'Video edukasi Islami yang dirancang khusus untuk anak, dengan pendekatan menyenangkan untuk menanamkan nilai agama sejak dini.';
    }
  }

  // ===== DIAGNOSIS METHODS =====
  Future<void> _saveHifzDiagnosis({
    required String aspectKey,
    required String aspectName,
    required int score,
    required String category,
  }) async {
    final selectedDiagnosis = _hifzSelectedDiagnosis[aspectKey];
    if (selectedDiagnosis == null || selectedDiagnosis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih diagnosa untuk $aspectName terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final note = _hifzNoteControllers[aspectKey]!.text.trim();

    final authState = context.read<AuthCubit>().state;
    String? nurseId;
    String? nurseName;

    if (authState is AuthSuccess) {
      nurseId = authState.user.id;
      nurseName = authState.user.name;
    }

    try {
      await ChildServices().saveHifzDiagnosisForChild(
        parentId: widget.child.parentId,
        child: widget.child,
        aspectKey: aspectKey,
        aspectName: aspectName,
        diagnosis: selectedDiagnosis,
        note: note,
        score: score,
        category: category,
        nurseId: nurseId,
        nurseName: nurseName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Diagnosa $aspectName tersimpan untuk ${widget.child.name}',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan diagnosa $aspectName: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveDiagnosis() async {
    if (_selectedDiagnosis == null || _selectedDiagnosis!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih diagnosa utama terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final note = _nurseNoteController.text.trim();

    final authState = context.read<AuthCubit>().state;
    String? nurseId;
    String? nurseName;

    if (authState is AuthSuccess) {
      nurseId = authState.user.id;
      nurseName = authState.user.name;
    }

    try {
      await ChildServices().saveDiagnosisForChild(
        parentId: widget.child.parentId,
        child: widget.child,
        diagnosis: _selectedDiagnosis!,
        note: note,
        nurseId: nurseId,
        nurseName: nurseName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Diagnosa "${_selectedDiagnosis!}" tersimpan untuk ${widget.child.name}',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan diagnosa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getSuggestedIntervention(String diagnosis) {
    switch (diagnosis) {
      case 'Distres Spiritual (D.0128)':
        return 'Intervensi: Dukungan Spiritual (I.09300).\n'
            'Tujuan: Anak merasa tenang, menemukan makna sakit, dan yakin pada takdir Allah.';
      case 'Risiko Distres Spiritual':
        return 'Intervensi: Pemantauan spiritual & edukasi dasar ibadah saat sakit.\n'
            'Tujuan: Mencegah munculnya kehilangan makna dan hambatan ibadah.';
      case 'Kesiapan Peningkatan Kesejahteraan Spiritual (D.0127)':
        return 'Intervensi: Edukasi Lanjutan tentang ibadah & hikmah sakit (I.06022).\n'
            'Tujuan: Menguatkan perilaku spiritual positif dan kemandirian ibadah.';
      case 'Defisit Pengetahuan (D.0016)':
        return 'Intervensi: Edukasi Kesehatan (I.06021 / I.06030).\n'
            'Tujuan: Anak & keluarga memahami penyakit, pengobatan, dan ibadah saat sakit.';
      case 'Kesiapan Peningkatan Pengetahuan (D.0017)':
        return 'Intervensi: Edukasi Lanjutan (I.06022).\n'
            'Tujuan: Meningkatkan kemandirian kognitif dan spiritual anak.';
      case 'Ketidakpatuhan terhadap Regimen Terapeutik (D.0053)':
        return 'Intervensi: Manajemen Kepatuhan Terapi (I.05243).\n'
            'Tujuan: Anak dan keluarga bersedia mengikuti pengobatan sebagai bentuk ikhtiar.';
      case 'Perilaku Mencari Pengobatan Tidak Efektif (D.0051)':
        return 'Intervensi: Edukasi pengobatan medis & koordinasi rujukan.\n'
            'Tujuan: Keluarga memilih jalur pengobatan yang rasional dan aman.';
      case 'Gangguan Pemeliharaan Spiritual (D.0126)':
        return 'Intervensi: Dukungan Spiritual Keluarga (I.09300).\n'
            'Tujuan: Keluarga membantu anak tetap beribadah selama sakit.';
      case 'Koping Keluarga Tidak Efektif (D.0107)':
        return 'Intervensi: Peningkatan Dukungan Keluarga (I.09102).\n'
            'Tujuan: Keluarga mampu beradaptasi dan mendukung anak secara emosional & spiritual.';
      case 'Risiko Kekerasan Seksual (D.0111)':
        return 'Intervensi: Perlindungan Anak & Edukasi Tubuh Aman.\n'
            'Tujuan: Anak memahami batas aurat dan merasa aman selama dirawat.';
      case 'Risiko Keterlambatan Tumbuh Kembang (D.0109)':
        return 'Intervensi: Stimulasi Spiritual & Sensorik.\n'
            'Tujuan: Meningkatkan stimulasi doa, Al-Qur\'an, dan interaksi positif.';
      case 'Defisit Perawatan Diri (D.0108)':
        return 'Intervensi: Edukasi Perawatan Diri & dukungan keluarga.\n'
            'Tujuan: Anak mampu menjaga kebersihan diri sesuai usia.';
      case 'Pola Komunikasi Keluarga Tidak Efektif (D.0106)':
        return 'Intervensi: Peningkatan Komunikasi Keluarga.\n'
            'Tujuan: Keluarga terbuka membahas perubahan tubuh, reproduksi, dan spiritual.';
      case 'Distres Finansial (D.0110)':
        return 'Intervensi: Manajemen Finansial Keluarga (I.09201).\n'
            'Tujuan: Keluarga mampu mengakses bantuan dan memenuhi kebutuhan dasar anak.';
      case 'Ketidakefektifan Pola Keluarga (D.0103)':
        return 'Intervensi: Peningkatan Dukungan Keluarga (I.09102).\n'
            'Tujuan: Tanggung jawab ekonomi dan pengasuhan lebih seimbang.';
      case 'Risiko Ketidakseimbangan Nutrisi (D.0002)':
        return 'Intervensi: Edukasi Nutrisi (I.06030).\n'
            'Tujuan: Anak mempertahankan status gizi sesuai usia.';
      case 'Risiko Ketidakmampuan Mengakses Pelayanan Kesehatan (D.0105)':
        return 'Intervensi: Koordinasi Pelayanan (I.09112).\n'
            'Tujuan: Keluarga memiliki jaminan kesehatan dan akses terapi berkelanjutan.';
      case 'Kesiapan Peningkatan Manajemen Ekonomi Keluarga (D.0111)':
        return 'Intervensi: Edukasi Manajemen Ekonomi Keluarga (I.09202).\n'
            'Tujuan: Keluarga mampu merencanakan keuangan dan memprioritaskan kebutuhan anak.';
      default:
        return 'Sesuaikan intervensi dan tujuan dengan kondisi klinis anak dan keluarga.';
    }
  }
}
