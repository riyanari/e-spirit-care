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
import 'hifz_detail_page.dart';
import 'hifz_scoring_system.dart';

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

  // ===== Scroll Controller =====
  final ScrollController _scrollController = ScrollController();

  // ===== Reminder State =====
  bool hasPrayerReminder = false;
  bool reminderScheduled = false;
  List<ScheduledReminder> _scheduledReminders = [];
  bool _isLoadingReminders = false;

  // ===== Nurse feedback state =====
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

  // ===== Hifz Data =====
  late Map<String, Map<String, dynamic>> _hifzData = {};

  // ===== Expanded States for Video Cards =====
  final Map<String, bool> _videoExpandedStates = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
    _loadExistingHifzDiagnoses();
    _loadHifzData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduledReminders(fromInit: true);
    });
  }

  void _loadHifzData() {
    setState(() {
      _hifzData = {
        'an_nafs': widget.child.getHifzData('an_nafs'),
        'ad_diin': widget.child.getHifzData('ad_diin'),
        'al_aql': widget.child.getHifzData('al_aql'),
        'an_nasl': widget.child.getHifzData('an_nasl'),
        'al_mal': widget.child.getHifzData('al_mal'),
      };
    });
  }

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

    totalScore = widget.child.totalHifzScore;
    overallCategory = widget.child.hifzOverallCategory;

    recommendations = _generateVideoRecommendations();
    hasPrayerReminder = _checkPrayerReminder();
  }

  List<VideoModel> _generateVideoRecommendations() {
    final allHifzVideos = widget.child.getAllHifzVideos();
    return allHifzVideos.map((hifzVideo) => VideoModel(
      id: hifzVideo.url.hashCode.toString(),
      title: hifzVideo.title,
      description: hifzVideo.description,
      url: hifzVideo.url,
      category: hifzVideo.category,
      thumbnail: '',
      duration: '5:00',
    )).toList();
  }

  // ===== UI COMPONENTS =====

  Widget _buildAnswerSummaryCard() {
    final totalAnswers = widget.child.getFilledAnswersCount();
    final completionPercentage = widget.child.getAnswerCompletionPercentage();
    final allAnswers = widget.child.getAllAnswers();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade100.withAlpha(200),
                  Colors.purple.shade200.withAlpha(150),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.question_answer_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ringkasan Jawaban',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelengkapan: ${completionPercentage.round()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: completionPercentage / 100,
                            backgroundColor: Colors.white.withAlpha(80),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                completionPercentage >= 80 ? Colors.green :
                                completionPercentage >= 50 ? Colors.orangeAccent : Colors.red.shade300
                            ),
                            borderRadius: BorderRadius.circular(10),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$totalAnswers',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'terjawab',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quick Actions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickActionButton(
                      'Lihat Jawaban',
                      Icons.list_alt_rounded,
                      Colors.white,
                          () => _showAllAnswers(allAnswers),
                    ),
                    _buildQuickActionButton(
                      'Rangkuman',
                      Icons.summarize_rounded,
                      Colors.white,
                          () => _showSummary(allAnswers),
                    ),
                    if (widget.child.harapan.isNotEmpty)
                      _buildQuickActionButton(
                        'Harapan',
                        Icons.flag_rounded,
                        Colors.white,
                            () => _showHarapan(),
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

  Widget _buildQuickActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withAlpha(50),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
    );
  }

  void _showAllAnswers(Map<String, String> allAnswers) {
    final filteredAnswers = allAnswers.entries
        .where((entry) => entry.value.isNotEmpty && entry.value != '-')
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.question_answer_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Semua Jawaban Kuesioner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredAnswers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada jawaban',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredAnswers.length,
                itemBuilder: (context, index) {
                  final entry = filteredAnswers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: index.isEven ? Colors.grey[50] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryColor.withAlpha(30),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        'Pertanyaan ${entry.key}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 14),
                      ),
                      dense: true,
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSummary(Map<String, String> allAnswers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.summarize_rounded, color: kPrimaryColor),
            SizedBox(width: 10),
            Text('Rangkuman Jawaban'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryItem('👤 Nama Anak', widget.child.name),
              _buildSummaryItem('📊 Total Pertanyaan', '${allAnswers.length}'),
              _buildSummaryItem('✅ Pertanyaan Terjawab', '${widget.child.getFilledAnswersCount()}'),
              _buildSummaryItem('📈 Kelengkapan', '${widget.child.getAnswerCompletionPercentage().round()}%'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Analisis Singkat:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getAnalysisSummary(),
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getAnalysisSummary() {
    final percentage = widget.child.getAnswerCompletionPercentage();
    if (percentage >= 80) return 'Jawaban sangat lengkap dan detail. Data yang tersedia cukup untuk analisis mendalam.';
    if (percentage >= 50) return 'Jawaban cukup lengkap untuk analisis dasar. Beberapa area mungkin memerlukan klarifikasi tambahan.';
    return 'Jawaban masih terbatas. Disarankan untuk melengkapi data untuk analisis yang lebih akurat.';
  }

  void _showHarapan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Harapan Orang Tua',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.child.harapan.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.child.harapan.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada harapan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.child.harapan.length,
                itemBuilder: (context, index) {
                  final harapan = widget.child.harapan[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withAlpha(30),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(harapan),
                      tileColor: Colors.orange.withAlpha(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  kPrimaryColor.withAlpha(230),
                  kPrimaryColor.withAlpha(180),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(80),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
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
                            Colors.white.withAlpha(50),
                            Colors.white.withAlpha(25),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.child_care_rounded,
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
                          color: Colors.white.withAlpha(230),
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
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications_active_rounded,
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernScoreOverview() {
    final categoryColor = widget.child.hifzOverallColor;

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
                  categoryColor.withAlpha(230),
                  categoryColor.withAlpha(180),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: 1 - widget.child.hifzOverallProgress,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withAlpha(80),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                  children: [
                    _buildModernStatItem(
                      'Kategori',
                      overallCategory,
                      Icons.assessment_rounded,
                      Colors.white,
                    ),
                    _buildModernStatItem(
                      'Level',
                      _getLevel(overallCategory),
                      Icons.star_rounded,
                      Colors.white,
                    ),
                    _buildModernStatItem(
                      'Status',
                      _getStatus(overallCategory),
                      Icons.emoji_events_rounded,
                      Colors.white,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: Colors.amber.shade300,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getCategoryDescription(overallCategory),
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
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color.withAlpha(230),
              fontSize: 10,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor.withAlpha(200),
                        kPrimaryColor.withAlpha(150),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analisis Aspek HIFZ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Penilaian komprehensif perkembangan anak',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Grid of HIFZ Aspects
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4, // Adjusted for better proportions
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildHifzAspectGridItem(index, isNurse);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHifzAspectGridItem(int index, bool isNurse) {
    final List<Map<String, dynamic>> hifzItems = [
      {
        'key': 'adDiin',
        'title': 'Hifz Ad-Diin',
        'subtitle': 'Spiritual & Keagamaan',
        'score': hifzDiinScore,
        'category': hifzDiinCategory,
        'icon': Icons.mosque_rounded,
        'color': Colors.green,
      },
      {
        'key': 'anNafs',
        'title': 'Hifz An-Nafs',
        'subtitle': 'Jiwa & Keselamatan',
        'score': hifzNafsScore,
        'category': hifzNafsCategory,
        'icon': Icons.health_and_safety_rounded,
        'color': Colors.red,
      },
      {
        'key': 'alAql',
        'title': "Hifz Al-'Aql",
        'subtitle': 'Akal & Perkembangan',
        'score': hifzAqlScore,
        'category': hifzAqlCategory,
        'icon': Icons.psychology_rounded,
        'color': Colors.purple,
      },
      {
        'key': 'anNasl',
        'title': 'Hifz An-Nasl',
        'subtitle': 'Keturunan & Pola Asuh',
        'score': hifzNaslScore,
        'category': hifzNaslCategory,
        'icon': Icons.family_restroom_rounded,
        'color': Colors.orange,
      },
      {
        'key': 'alMal',
        'title': 'Hifz Al-Mal',
        'subtitle': 'Ekonomi Keluarga',
        'score': hifzMalScore,
        'category': hifzMalCategory,
        'icon': Icons.savings_rounded,
        'color': Colors.blue,
      },
    ];

    final item = hifzItems[index];
    final aspectKey = item['key'] as String;
    final title = item['title'] as String;
    final subtitle = item['subtitle'] as String;
    final score = item['score'] as int;
    final category = item['category'] as String;
    final icon = item['icon'] as IconData;
    final color = item['color'] as Color;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return GestureDetector(
          onTap: () => _showHifzDetailModal(aspectKey, title, color, icon, isNurse),
          onTapDown: (_) => setState(() => isHovered = true),
          onTapUp: (_) => setState(() => isHovered = false),
          onTapCancel: () => setState(() => isHovered = false),
          child: MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHovered
                      ? [
                    color.withAlpha(40),
                    color.withAlpha(25),
                  ]
                      : [
                    color.withAlpha(20),
                    color.withAlpha(10),
                  ],
                ),
                border: Border.all(
                  color: isHovered
                      ? color.withAlpha(60)
                      : color.withAlpha(30),
                  width: isHovered ? 2 : 1.5,
                ),
                boxShadow: isHovered
                    ? [
                  BoxShadow(
                    color: color.withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: color.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: color.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon, Title, and Click Indicator
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isHovered
                                ? color.withAlpha(40)
                                : color.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isHovered
                                ? [
                              BoxShadow(
                                color: color.withAlpha(30),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                                : [],
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: isHovered ? 22 : 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: isHovered ? 1 : 0.7,
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Score with Hover Effect
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? color.withAlpha(30)
                              : color.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: isHovered
                              ? Border.all(
                            color: color.withAlpha(60),
                            width: 1,
                          )
                              : null,
                        ),
                        child: Text(
                          'Skor: $score',
                          style: TextStyle(
                            fontSize: isHovered ? 15 : 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Category Badge with Hover Effect
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withAlpha(
                            isHovered ? 25 : 15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getCategoryColor(category).withAlpha(
                              isHovered ? 70 : 50,
                            ),
                            width: isHovered ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(category),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isHovered) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline_rounded,
                                size: 10,
                                color: _getCategoryColor(category),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Progress Bar with Click Indicator
                    Column(
                      children: [
                        Stack(
                          children: [
                            LinearProgressIndicator(
                              value: _getProgressValue(aspectKey, score),
                              backgroundColor: color.withAlpha(30),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(_getProgressValue(aspectKey, score)),
                              ),
                              borderRadius: BorderRadius.circular(10),
                              minHeight: 4,
                            ),
                            if (isHovered)
                              Positioned(
                                right: 0,
                                top: -2,
                                child: Icon(
                                  Icons.touch_app_rounded,
                                  size: 12,
                                  color: _getProgressColor(_getProgressValue(aspectKey, score)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Risiko',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${(_getProgressValue(aspectKey, score) * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getProgressColor(_getProgressValue(aspectKey, score)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (isHovered)
                                  Text(
                                    '• Ketuk untuk detail',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Click Hint Text (visible on hover)
                    if (isHovered)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            'Klik untuk melihat detail',
                            style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHifzDetailModal(
      String aspectKey,
      String title,
      Color color,
      IconData icon,
      bool isNurse,
      ) {
    final hifzKeyMap = {
      'adDiin': 'ad_diin',
      'anNafs': 'an_nafs',
      'alAql': 'al_aql',
      'anNasl': 'an_nasl',
      'alMal': 'al_mal',
    };

    final hifzKey = hifzKeyMap[aspectKey] ?? aspectKey.toLowerCase();
    final hifzData = _hifzData[hifzKey] ?? {};
    final answers = (hifzData['answers'] as List<Map<String, dynamic>>?) ?? [];
    final videos = (hifzData['videos'] as List<HifzVideo>?) ?? [];
    final description = hifzData['description'] as String? ?? '';
    final maxScore = (hifzData['maxScore'] as int?) ?? 20;
    final score = hifzData['score'] as int? ?? 0;
    final category = hifzData['category'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withAlpha(10),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'Analisis Detail Aspek',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Overview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildModalStatItem('Skor', '$score/$maxScore', Icons.score_rounded, color),
                          _buildModalStatItem('Kategori', category, Icons.category_rounded, _getCategoryColor(category)),
                          _buildModalStatItem('Status', _getStatusText(score, maxScore), Icons.assessment_rounded, _getStatusColor(score, maxScore)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        '📋 Deskripsi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Progress Bar
                    Text(
                      '📊 Tingkat Risiko',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: score / maxScore,
                      backgroundColor: color.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(score / maxScore),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rendah',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${((score / maxScore) * 100).round()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getProgressColor(score / maxScore),
                          ),
                        ),
                        Text(
                          'Tinggi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    // Video Recommendations
                    if (videos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        '🎬 Video Rekomendasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...videos.take(2).map((video) => _buildModalVideoItem(video, color)).toList(),
                      if (videos.length > 2) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () => _showAllVideosForHifz(hifzKey, title, videos),
                            child: Text(
                              '+${videos.length - 2} video lainnya',
                              style: TextStyle(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],

                    // Questionnaire Answers
                    if (answers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        '📝 Jawaban Kuesioner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${answers.length} pertanyaan terjawab',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: answers.map((qa) {
                            final question = qa['question'] as String;
                            final answerList = qa['answers'] as List<String>;

                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withAlpha(10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withAlpha(30)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    answerList.first,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    // Nurse Section
                    if (isNurse) ...[
                      const SizedBox(height: 20),
                      _buildNurseSection(aspectKey, title, color, score, category),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Tutup'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToHifzDetailPage(hifzKey, title, color, icon);
                      },
                      icon: const Icon(Icons.open_in_full_rounded, size: 18),
                      label: const Text('Detail Lengkap'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildModalStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModalVideoItem(HifzVideo video, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
        child: InkWell(
          onTap: () => _playHifzVideo(video),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNurseSection(String aspectKey, String title, Color color, int score, String category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_rounded, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Diagnosa Perawat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Diagnosis Dropdown
          GestureDetector(
            onTap: () => _showDiagnosisBottomSheet(aspectKey),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_services_outlined, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _hifzSelectedDiagnosis[aspectKey] ?? 'Pilih diagnosa SDKI',
                      style: TextStyle(
                        color: _hifzSelectedDiagnosis[aspectKey] != null
                            ? Colors.black
                            : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[500]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _hifzNoteControllers[aspectKey],
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Catatan klinis untuk $title...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 12),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _saveHifzDiagnosis(
                aspectKey: aspectKey,
                aspectName: title,
                score: score,
                category: category,
              ),
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Simpan Diagnosa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHifzDetailPage(String hifzKey, String title, Color color, IconData icon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HifzDetailPage(
          child: widget.child,
          hifzKey: hifzKey,
        ),
      ),
    );
  }

  double _getProgressValue(String aspectKey, int score) {
    final hifzKeyMap = {
      'adDiin': 'ad_diin',
      'anNafs': 'an_nafs',
      'alAql': 'al_aql',
      'anNasl': 'an_nasl',
      'alMal': 'al_mal',
    };

    final hifzKey = hifzKeyMap[aspectKey] ?? aspectKey.toLowerCase();
    final hifzData = _hifzData[hifzKey] ?? {};
    final maxScore = (hifzData['maxScore'] as int?) ?? 20;

    return score / maxScore;
  }

  String _getStatusText(int score, int maxScore) {
    final percentage = score / maxScore;
    if (percentage <= 0.3) return 'Baik';
    if (percentage <= 0.6) return 'Perhatian';
    return 'Perlu Intervensi';
  }

  Color _getStatusColor(int score, int maxScore) {
    final percentage = score / maxScore;
    if (percentage <= 0.3) return Colors.green;
    if (percentage <= 0.6) return Colors.orange;
    return Colors.red;
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

  void _showDiagnosisBottomSheet(String aspectKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_rounded, color: Colors.blue),
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
                    icon: const Icon(Icons.close_rounded),
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
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Diagnosa dipilih: $diagnosis'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
          behavior: SnackBarBehavior.floating,
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
            '✅ Diagnosa $aspectName tersimpan untuk ${widget.child.name}',
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
          content: Text('❌ Gagal menyimpan diagnosa $aspectName: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===== HELPER METHODS =====
  bool _checkPrayerReminder() {
    return widget.child.harapan.any(
          (h) =>
      h.toLowerCase().contains('pengingat') ||
          h.toLowerCase().contains('doa'),
    );
  }

  Color _getCategoryColor(String category) {
    return HifzScoringSystem.getCategoryColor(category);
  }

  Color _getHifzColor(String hifzKey) {
    final colors = {
      'an_nafs': Colors.red,
      'ad_diin': Colors.green,
      'al_aql': Colors.purple,
      'an_nasl': Colors.orange,
      'al_mal': Colors.blue,
    };
    return colors[hifzKey] ?? Colors.grey;
  }

  Color _getProgressColor(double value) {
    if (value <= 0.3) return Colors.green;
    if (value <= 0.6) return Colors.orange;
    return Colors.red;
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

  String _getStatus(String category) {
    switch (category) {
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

  String _getCategoryDescription(String category) {
    switch (category) {
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

  Future<void> _setupReminders() async {
    if (!hasPrayerReminder || reminderScheduled) return;
    try {
      await ReminderService.initialize();
      await ReminderService.schedulePrayerReminders();
      if (!mounted) return;
      setState(() => reminderScheduled = true);
    } catch (e) {
      debugPrint('❌ Gagal setup reminders: $e');
    }
  }

  Future<void> _refreshReminders() async {
    await _loadScheduledReminders();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder diperbarui'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===== VIDEO SECTION =====
  Widget _buildModernVideoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.video_library_rounded,
                  color: kPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Semua Video Rekomendasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Video edukasi berdasarkan analisis aspek HIFZ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${recommendations.length} video',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Video Grid
          recommendations.isEmpty
              ? Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada video rekomendasi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Video akan muncul setelah analisis HIFZ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Better proportion for cards
            ),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final video = recommendations[index];
              final isExpanded = _videoExpandedStates[video.id] ?? false;
              return _buildModernVideoCard(video, isExpanded);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernVideoCard(VideoModel video, bool isExpanded) {
    return GestureDetector(
      onTap: () => _playVideo(video),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getVideoCategoryColor(video.category).withAlpha(50),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail area
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getVideoCategoryColor(video.category),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: _getVideoCategoryColor(video.category),
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: BorderRadius.circular(4),
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

              // Content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getVideoCategoryColor(video.category)
                              .withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getVideoCategoryColor(video.category)
                                .withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          video.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getVideoCategoryColor(video.category),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Title
                      Text(
                        video.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: isExpanded ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Description
                      Expanded(
                        child: Text(
                          video.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: isExpanded ? 4 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Play button
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getVideoCategoryColor(video.category),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tonton',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getVideoCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'spiritual':
        return Colors.green;
      case 'kesehatan':
        return Colors.blue;
      case 'keselamatan':
        return Colors.red;
      case 'perkembangan':
        return Colors.purple;
      case 'pola asuh':
        return Colors.orange;
      case 'ekonomi':
        return Colors.blue.shade700;
      case 'nutrisi':
        return Colors.amber;
      case 'sosial':
        return Colors.teal;
      default:
        return kPrimaryColor;
    }
  }

  void _playVideo(VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerPage(video: video)),
    );
  }

  void _playHifzVideo(HifzVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          video: VideoModel(
            id: video.url.hashCode.toString(),
            title: video.title,
            description: video.description,
            url: video.url,
            category: video.category,
            thumbnail: '',
            duration: '5:00',
          ),
        ),
      ),
    );
  }

  void _showAllVideosForHifz(String hifzKey, String title, List<HifzVideo> videos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getHifzColor(hifzKey).withAlpha(25),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.video_library_rounded,
                    color: _getHifzColor(hifzKey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semua Video Rekomendasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getHifzColor(hifzKey),
                          ),
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Video List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getHifzColor(hifzKey).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: _getHifzColor(hifzKey),
                        ),
                      ),
                      title: Text(
                        video.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        video.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey[400],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _playHifzVideo(video);
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

  // Reminder Card
  Widget _buildModernReminderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withAlpha(230),
            Colors.blue.withAlpha(180),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengingat Doa & Sholat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reminderScheduled
                      ? 'Reminder aktif berdasarkan harapan orang tua'
                      : 'Aktifkan reminder untuk doa dan sholat',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: reminderScheduled,
            onChanged: (value) async {
              if (value) {
                await _setupReminders();
              } else {
                // TODO: Implement cancel reminders
              }
              setState(() {
                reminderScheduled = value;
              });
            },
            activeColor: Colors.white,
            inactiveTrackColor: Colors.white.withAlpha(100),
          ),
        ],
      ),
    );
  }

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
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 180,
                  floating: true,
                  pinned: true,
                  snap: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Rekomendasi Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withAlpha(80),
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
                          colors: [
                            kPrimaryColor,
                            kPrimaryColor.withAlpha(200),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -30,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
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
                                color: Colors.white.withAlpha(25),
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
              ];
            },
            body: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                const SizedBox(height: 8),
                _buildModernProfileCard(),
                if (hasPrayerReminder) _buildModernReminderCard(),
                _buildAnswerSummaryCard(),
                _buildModernScoreOverview(),
                _buildModernHifzAspectsCard(isNurse),

                // Reminder Card


                // Video Section
                // _buildModernVideoSection(),
                // const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _scrollController.dispose();
    for (final c in _hifzNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}