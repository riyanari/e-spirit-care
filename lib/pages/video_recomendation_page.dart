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

  // Data Hifz dengan jawaban
  late Map<String, Map<String, dynamic>> _hifzData = {};

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
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade100.withValues(alpha:0.8),
                  Colors.purple.shade200.withValues(alpha:0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha:0.2),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.question_answer,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ringkasan Jawaban Kuesioner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Completion Progress
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
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: completionPercentage / 100,
                            backgroundColor: Colors.white.withValues(alpha:0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                completionPercentage >= 80 ? Colors.green :
                                completionPercentage >= 50 ? Colors.orange : Colors.red
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$totalAnswers',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'terjawab',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha:0.8),
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
                      'Lihat Semua Jawaban',
                      Icons.list,
                      Colors.white,
                          () => _showAllAnswers(allAnswers),
                    ),
                    _buildQuickActionButton(
                      'Rangkuman',
                      Icons.summarize,
                      Colors.white,
                          () => _showSummary(allAnswers),
                    ),
                    if (widget.child.harapan.isNotEmpty)
                      _buildQuickActionButton(
                        'Harapan: ${widget.child.harapan.length}',
                        Icons.flag,
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
      icon: Icon(icon, size: 14),
      label: Text(text, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha:0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha:0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.question_answer, color: kPrimaryColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Semua Jawaban Kuesioner',
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
              child: filteredAnswers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text('Belum ada jawaban'),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredAnswers.length,
                itemBuilder: (context, index) {
                  final entry = filteredAnswers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pertanyaan ${entry.key}:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
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

  void _showSummary(Map<String, String> allAnswers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rangkuman Jawaban'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Nama: ${widget.child.name}'),
            Text('📊 Total Pertanyaan: ${allAnswers.length}'),
            Text('✅ Pertanyaan Terjawab: ${widget.child.getFilledAnswersCount()}'),
            Text('📈 Kelengkapan: ${widget.child.getAnswerCompletionPercentage().round()}%'),
            const SizedBox(height: 16),
            const Text(
              'Analisis Singkat:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _getAnalysisSummary(),
              style: const TextStyle(fontSize: 12),
            ),
          ],
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

  String _getAnalysisSummary() {
    final percentage = widget.child.getAnswerCompletionPercentage();
    if (percentage >= 80) return 'Jawaban sangat lengkap dan detail. Data yang tersedia cukup untuk analisis mendalam.';
    if (percentage >= 50) return 'Jawaban cukup lengkap untuk analisis dasar. Beberapa area mungkin memerlukan klarifikasi tambahan.';
    return 'Jawaban masih terbatas. Disarankan untuk melengkapi data untuk analisis yang lebih akurat.';
  }

  void _showHarapan() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Harapan Orang Tua',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${widget.child.harapan.length} harapan',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...widget.child.harapan.map((harapan) => ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(harapan),
            )).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
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
                              const Icon(
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
                  const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
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
                            color: Colors.white.withValues(alpha:0.9),
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

                const SizedBox(height: 16),
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
                      const Icon(
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
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha:0.9),
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

                // Tampilkan semua aspek Hifz
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
    final totalQuestions = answers.length;

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

          // BAGIAN UNTUK SEMUA ROLE: Tampilkan jumlah jawaban + button lihat detail
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jawaban Kuesioner',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      '$totalQuestions pertanyaan terjawab',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showHifzAnswersQuickView(
                    hifzKey,
                    title,
                    color,
                    icon,
                  ),
                  icon: Icon(Icons.visibility, size: 14, color: color),
                  label: Text(
                    'Lihat',
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withValues(alpha:0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BAGIAN KHUSUS UNTUK NURSE: Diagnosa & Catatan
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

            // Dropdown untuk memilih diagnosa
            GestureDetector(
              onTap: () => _showDiagnosisBottomSheet(aspectKey),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services, size: 20, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _hifzSelectedDiagnosis[aspectKey] ?? 'Pilih diagnosa SDKI',
                        style: TextStyle(
                          color: _hifzSelectedDiagnosis[aspectKey] != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
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
              child: ElevatedButton.icon(
                onPressed: () => _saveHifzDiagnosis(
                  aspectKey: aspectKey,
                  aspectName: title,
                  score: score,
                  category: category,
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Simpan Diagnosa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            // UNTUK ORANG TUA/ANAK: Tampilkan diagnosa yang sudah ada jika ada
            if ((_hifzSelectedDiagnosis[aspectKey] ?? '').isNotEmpty ||
                (_hifzNoteControllers[aspectKey]?.text.isNotEmpty ?? false))
              ...[
                const SizedBox(height: 12),
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
                        'Catatan Perawat',
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
                      if (_hifzNoteControllers[aspectKey]?.text.isNotEmpty ?? false) ...[
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
        ],
      ),
    );
  }

  void _showHifzAnswersQuickView(
      String hifzKey,
      String aspectName,
      Color color,
      IconData icon,
      ) {
    final hifzData = _hifzData[hifzKey] ?? {};
    final answers = (hifzData['answers'] as List<Map<String, dynamic>>?) ?? [];
    final score = hifzData['score'] as int? ?? 0;
    final category = hifzData['category'] as String? ?? '';
    final video = hifzData['video'] as String? ?? '';

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
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aspectName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'Detail Jawaban Kuesioner',
                          style: TextStyle(
                            fontSize: 14,
                            color: color.withValues(alpha:0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Stats Overview
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickViewStat('Skor', '$score', Icons.score, color),
                  _buildQuickViewStat('Kategori', category, Icons.category, color),
                  _buildQuickViewStat(
                    'Pertanyaan',
                    '${answers.length}',
                    Icons.question_answer,
                    color,
                  ),
                ],
              ),
            ),

            // Video Recommendation if available
            if (video.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.video_library, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekomendasi Video:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              video,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Content
            Expanded(
              child: answers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada data jawaban',
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
                itemCount: answers.length,
                itemBuilder: (context, index) {
                  final qa = answers[index];
                  final question = qa['question'] as String;
                  final answerList = qa['answers'] as List<String>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...answerList.map((answer) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      answer,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToHifzDetail(hifzKey, aspectName, color, icon);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Detail Lengkap',
                        style: TextStyle(color: Colors.white),
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

  Widget _buildQuickViewStat(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _navigateToHifzDetail(String hifzKey, String aspectName, Color color, IconData icon) {
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

  // ===== HELPER METHODS =====
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

              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _buildModernProfileCard(),
                  _buildAnswerSummaryCard(), // Card ringkasan jawaban
                  _buildModernScoreOverview(),
                  _buildModernHifzAspectsCard(isNurse),

                  // Tambahkan komponen reminder jika diperlukan
                  if (hasPrayerReminder) _buildModernReminderCard(),

                  // Tambahkan komponen video
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

  // ===== REMINDER METHODS (disertakan untuk kelengkapan) =====
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
      ),
    );
  }

  // Komponen reminder (disertakan untuk kelengkapan)
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
            Colors.blue.withValues(alpha:0.9),
            Colors.blue.withValues(alpha:0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                'Pengingat Doa & Sholat',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Reminder aktif berdasarkan harapan orang tua',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Komponen video (disertakan untuk kelengkapan)
  Widget _buildModernVideoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Rekomendasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          recommendations.isEmpty
              ? const Center(child: Text('Belum ada video rekomendasi'))
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  Widget _buildModernVideoCard(VideoModel video) {
    return GestureDetector(
      onTap: () => _playVideo(video),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(child: Icon(Icons.play_arrow, size: 50, color: Colors.grey[600])),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playVideo(VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerPage(video: video)),
    );
  }
}