import 'package:e_spirit_care/pages/video_player_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/child_model.dart';
import '../models/video_model.dart';
import '../models/scheduled_reminder_model.dart';
import '../services/video_service.dart';
import '../services/reminder_service.dart';
import '../cubit/auth_cubit.dart';
import '../theme/theme.dart';

class ChildDashboardPage extends StatelessWidget {
  final ChildModel? child;

  const ChildDashboardPage({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        ChildModel? currentChild;

        if (child != null) {
          currentChild = child;
        } else if (state is ChildAuthSuccess) {
          currentChild = state.child;
        } else {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is ChildModel) {
            currentChild = args;
          }
        }

        if (currentChild != null) {
          return _ChildDashboardContent(child: currentChild);
        } else if (state is AuthLoading) {
          return _buildLoading();
        } else {
          return _buildError('Data anak tidak ditemukan', context);
        }
      },
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    strokeWidth: 3,
                  ),
                  Icon(
                    Icons.child_care,
                    color: kPrimaryColor,
                    size: 30,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Memuat data anak...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (_) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: const Text('Kembali ke Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildDashboardContent extends StatefulWidget {
  final ChildModel child;

  const _ChildDashboardContent({required this.child});

  @override
  State<_ChildDashboardContent> createState() =>
      _ChildDashboardContentState();
}

class _ChildDashboardContentState extends State<_ChildDashboardContent> {
  final VideoService videoService = VideoService();

  late List<VideoModel> recommendations;

  // ===== HIFZ per aspek (SAMA dengan VideoRecommendationsPage) =====
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
  late String overallCategory; // Tinggi / Sedang / Rendah (berdasarkan HIFZ)

  bool hasPrayerReminder = false;
  bool reminderScheduled = false;
  List<ScheduledReminder> _scheduledReminders = [];
  bool _isLoadingReminders = false;

  @override
  void initState() {
    super.initState();

    // ==== ambil data HIFZ dari ChildModel ====
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

    // total skor gabungan (pakai 5 skor HIFZ, bukan lagi child.totalSkor)
    totalScore = hifzNafsScore +
        hifzDiinScore +
        hifzAqlScore +
        hifzNaslScore +
        hifzMalScore;

    // kategori overall dari kombinasi 5 aspek
    overallCategory = _getOverallCategory();

    // rekomendasi video berdasarkan kategori perkembangan anak (Tinggi/Sedang/Rendah)
    // ini tetap pakai child.kategori seperti di VideoService
    recommendations = videoService.getVideoRecommendations(widget.child);

    hasPrayerReminder = _checkPrayerReminder();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupReminders();
      _loadScheduledReminders();
    });
  }

  // =========================================================
  // LOGIC HIFZ / KATEGORI OVERALL (copy dari VideoRecommendationsPage)
  // =========================================================

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

  /// Konversi kategori per HIFZ menjadi level numerik:
  /// 2 = baik/aman/sejahtera, 1 = risiko, 0 = masalah berat
  int _aspectLevel(String category) {
    final text = category.toLowerCase();

    // kondisi baik
    if (text.contains('aman') ||
        text.contains('kesejahteraan') ||
        text.contains('perkembangan baik') ||
        text.contains('pola asuh baik') ||
        text.contains('kecukupan ekonomi baik')) {
      return 2;
    }

    // risiko sedang
    if (text.contains('risiko')) {
      return 1;
    }

    // kondisi berat (distres, gangguan, buruk, ketidakcukupan berat, dll.)
    return 0;
  }

  bool _checkPrayerReminder() {
    return widget.child.harapan.any((harapan) =>
    harapan.toLowerCase().contains('pengingat') ||
        harapan.toLowerCase().contains('doa'));
  }

  Future<void> _setupReminders() async {
    if (hasPrayerReminder && !reminderScheduled) {
      try {
        await ReminderService.initialize();
        await ReminderService.schedulePrayerReminders();

        if (!mounted) return;

        setState(() {
          reminderScheduled = true;
        });

        _showReminderConfirmation();
      } catch (e) {
        _showReminderError();
      }
    }
  }

  Future<void> _loadScheduledReminders() async {
    if (!mounted) return;

    setState(() {
      _isLoadingReminders = true;
    });

    try {
      final reminders = await ReminderService.getScheduledReminders();
      if (!mounted) return;

      setState(() {
        _scheduledReminders = reminders
            .map<ScheduledReminder>(
              (reminder) => ScheduledReminder(
            id: reminder['id'] as int,
            title: reminder['title']?.toString() ?? '',
            body: reminder['body']?.toString() ?? '',
            type: reminder['type']?.toString() ?? '',
            scheduledTime: reminder['scheduledTime']?.toString() ?? '',
          ),
        )
            .toList();

        reminderScheduled = _scheduledReminders.isNotEmpty;
      });
    } catch (e) {
      debugPrint('❌ Gagal memuat scheduled reminders: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReminders = false;
        });
      }
    }
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
                      color: Colors.white.withValues(alpha: 0.9),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
          children: const [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Gagal mengaktifkan reminder. Coba lagi nanti.'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _refreshReminders() async {
    await _loadScheduledReminders();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reminder diperbarui'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Halo, ${widget.child.name}!',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          _buildAnimatedRefreshButton(),
          const SizedBox(width: 8),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is ChildAuthSuccess) {
                return _buildLogoutButton(context);
              }
              return const SizedBox();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReminders,
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChildHeader(),
              const SizedBox(height: 24),

              // Pakai totalScore & overallCategory hasil perhitungan HIFZ
              _buildScoreCard(totalScore, overallCategory),
              const SizedBox(height: 24),

              // LIST HIFZ per aspek (tambahan baru)
              _buildHifzAspectsCard(),
              const SizedBox(height: 24),

              if (hasPrayerReminder) _buildReminderControlSection(),
              if (hasPrayerReminder) const SizedBox(height: 24),

              _buildVideoSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedRefreshButton() {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoadingReminders
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.refresh_rounded),
      ),
      onPressed: _isLoadingReminders ? null : _refreshReminders,
      tooltip: 'Refresh Reminders',
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout, size: 20),
        ),
        onPressed: () => _showLogoutConfirmation(context),
        tooltip: 'Logout',
      ),
    );
  }

  Widget _buildChildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor.withValues(alpha: 0.8),
            kPrimaryColor.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.child_care,
              color: Colors.white,
              size: 35,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.child.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.child.umur} tahun • ${widget.child.harapan.length} harapan',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                if (hasPrayerReminder && reminderScheduled) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Reminder aktif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int totalScore, String category) {
    Color getCategoryColor() {
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

    String getCategoryDescription() {
      switch (category) {
        case 'Tinggi':
          return 'Perkembangan aspek HIFZ anak relatif baik. Pertahankan! 🎉';
        case 'Sedang':
          return 'Ada beberapa area yang perlu ditingkatkan. Tetap semangat mendampingi anak 💪';
        case 'Rendah':
          return 'Perlu perhatian lebih pada aspek spiritual, jiwa, pola asuh, atau ekonomi. 🌱';
        default:
          return '';
      }
    }

    IconData getCategoryIcon() {
      switch (category) {
        case 'Tinggi':
          return Icons.emoji_events;
        case 'Sedang':
          return Icons.trending_up;
        case 'Rendah':
          return Icons.lightbulb_outline;
        default:
          return Icons.assessment;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            getCategoryColor().withValues(alpha: 0.9),
            getCategoryColor().withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: getCategoryColor().withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreItem(
                  'Total Skor', '$totalScore', Icons.assessment_outlined),
              _buildScoreItem('Kategori', category, getCategoryIcon()),
              _buildScoreItem(
                  'Level', _getLevel(category), Icons.star_rate_rounded),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    getCategoryDescription(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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

  // ==========================
  // CARD RINGKASAN HIFZ (baru)
  // ==========================
  Widget _buildHifzAspectsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aspek HIFZ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildHifzAspectItem(
            title: 'Hifz Ad-Diin',
            subtitle: 'Spiritual & Keagamaan',
            score: hifzDiinScore,
            category: hifzDiinCategory,
            icon: Icons.mosque,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildHifzAspectItem(
            title: 'Hifz An-Nafs',
            subtitle: 'Jiwa & Keselamatan',
            score: hifzNafsScore,
            category: hifzNafsCategory,
            icon: Icons.health_and_safety,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildHifzAspectItem(
            title: "Hifz Al-'Aql",
            subtitle: 'Akal & Perkembangan',
            score: hifzAqlScore,
            category: hifzAqlCategory,
            icon: Icons.psychology,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildHifzAspectItem(
            title: 'Hifz An-Nasl',
            subtitle: 'Keturunan & Pola Asuh',
            score: hifzNaslScore,
            category: hifzNaslCategory,
            icon: Icons.family_restroom,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildHifzAspectItem(
            title: 'Hifz Al-Mal',
            subtitle: 'Ekonomi Keluarga',
            score: hifzMalScore,
            category: hifzMalCategory,
            icon: Icons.savings,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildHifzAspectItem({
    required String title,
    required String subtitle,
    required int score,
    required String category,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                category,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================
  // REMINDER SECTION
  // ==========================

  Widget _buildReminderControlSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: reminderScheduled
              ? [Colors.green.shade50, Colors.lightGreen.shade50]
              : [Colors.blue.shade50, Colors.lightBlue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
          reminderScheduled ? Colors.green.shade100 : Colors.blue.shade100,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (reminderScheduled ? Colors.green : Colors.blue)
                .withValues(alpha: 0.1),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: reminderScheduled
                      ? Colors.green
                      : Colors.blue.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminderScheduled
                          ? 'Reminder Aktif 🎯'
                          : 'Mengaktifkan Reminder...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: reminderScheduled
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Berdasarkan harapan "Pengingat Doa"',
                      style: TextStyle(
                        color: reminderScheduled
                            ? Colors.green.shade600
                            : Colors.blue.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!reminderScheduled) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildReminderChip('Sholat 5 Waktu', Icons.mosque, Colors.green),
              _buildReminderChip('Doa Pagi', Icons.wb_sunny, Colors.orange),
              _buildReminderChip('Doa Sore', Icons.nightlight, Colors.purple),
              _buildReminderChip('Baca Quran', Icons.menu_book, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                  reminderScheduled ? () => _viewReminderSchedule() : null,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('Lihat Jadwal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    reminderScheduled ? Colors.green : Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showReminderInfo(),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderChip(String text, IconData icon, Color color) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      avatar: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12, color: color),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showReminderInfo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                    child: const Icon(Icons.info,
                        color: Colors.white, size: 24),
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
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
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
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 13,
              ),
            ),
          ),
        ],
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
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
                    icon:
                    Icon(Icons.close, color: Colors.blue.shade600),
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
                        '05:30', 'Subuh', Icons.mosque, Colors.green),
                    _buildScheduleItem(
                        '12:00', 'Dzuhur', Icons.mosque, Colors.green),
                    _buildScheduleItem(
                        '15:30', 'Ashar', Icons.mosque, Colors.green),
                    _buildScheduleItem(
                        '18:00', 'Maghrib', Icons.mosque, Colors.green),
                    _buildScheduleItem(
                        '19:30', 'Isya', Icons.mosque, Colors.green),
                  ]),
                  const SizedBox(height: 20),
                  _buildScheduleCategory('🙏 Waktu Doa', [
                    _buildScheduleItem(
                        '07:00', 'Doa Pagi', Icons.wb_sunny, Colors.orange),
                    _buildScheduleItem(
                        '18:30', 'Doa Sore', Icons.nightlight, Colors.purple),
                    _buildScheduleItem(
                        '21:00', 'Doa Tidur', Icons.bedtime, Colors.blue),
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
                        const Icon(Icons.celebration,
                            color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Reminder aktif! ${widget.child.name} akan mendapatkan notifikasi sesuai jadwal di atas.',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
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
      String time, String activity, IconData icon, Color color) {
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
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
              color: color.withValues(alpha: 0.1),
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
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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

  // ==========================
  // VIDEO SECTION
  // ==========================
  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Video Rekomendasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 8),
        Text(
          'Konten edukasi berdasarkan perkembangan ${widget.child.name}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        recommendations.isEmpty
            ? _buildEmptyVideos()
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final video = recommendations[index];
            return _buildVideoCard(video, context);
          },
        ),
      ],
    );
  }

  Widget _buildVideoCard(VideoModel video, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerPage(video: video),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            // Thumbnail YouTube
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  image: video.effectiveThumbnail.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(video.effectiveThumbnail),
                    fit: BoxFit.cover,
                  )
                      : null,
                  color: video.effectiveThumbnail.isEmpty
                      ? kPrimaryColor.withValues(alpha: 0.1)
                      : null,
                ),
                child: Stack(
                  children: [
                    if (video.effectiveThumbnail.isNotEmpty)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: kPrimaryColor,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
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
                    if (video.effectiveThumbnail.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              color: kPrimaryColor,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Video YouTube',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info video
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        video.category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.play_circle_outline,
                        size: 12,
                        color: kPrimaryColor,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Putar',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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
  }

  Widget _buildEmptyVideos() {
    return Container(
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada video rekomendasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Video akan muncul berdasarkan perkembangan dan kategori ${widget.child.name}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: aksi jika ingin cari video lain
            },
            icon: const Icon(Icons.search, size: 16),
            label: const Text('Cari Video Lainnya'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logout?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah kamu yakin ingin logout dari akun ${widget.child.name}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side:
                        BorderSide(color: Colors.grey.shade300),
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
                        context.read<AuthCubit>().signOut();
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil(
                            '/login', (_) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Logout'),
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
}
