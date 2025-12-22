import 'package:e_spirit_care/pages/video_player_page.dart';
import 'package:e_spirit_care/pages/hifz_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/child_model.dart';
import '../models/video_model.dart';
import '../models/scheduled_reminder_model.dart';
import '../services/child_services.dart';
import '../services/video_service.dart';
import '../services/reminder_service.dart';
import '../cubit/auth_cubit.dart';
import '../theme/theme.dart';
import 'hifz_scoring_system.dart';

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
                color: kPrimaryColor.withValues(alpha:0.1),
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
                    Icons.child_care_rounded,
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
                color: Colors.red.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
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

  // ===== Scroll Controller =====
  final ScrollController _scrollController = ScrollController();

  // ===== Reminder State =====
  bool hasPrayerReminder = false;
  bool reminderScheduled = false;
  List<ScheduledReminder> _scheduledReminders = [];
  bool _isLoadingReminders = false;

  // ===== Hifz Diagnoses =====
  final Map<String, String> _hifzDiagnoses = {
    'adDiin': '',
    'anNafs': '',
    'alAql': '',
    'anNasl': '',
    'alMal': '',
  };

  final Map<String, String> _hifzNotes = {
    'adDiin': '',
    'anNafs': '',
    'alAql': '',
    'anNasl': '',
    'alMal': '',
  };

  // ===== Hifz Data =====
  late Map<String, Map<String, dynamic>> _hifzData = {};

  // ===== Key for Refresh Indicator =====
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadHifzData();
    _loadExistingHifzDiagnoses();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupReminders();
      _loadScheduledReminders();
    });
  }

  void _initializeData() {
    // Ambil data dari ChildModel
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

    recommendations = videoService.getVideoRecommendations(widget.child);
    hasPrayerReminder = _checkPrayerReminder();
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
            _hifzDiagnoses[aspectKey] = diagnosis;
          }
          if (note != null && note.isNotEmpty) {
            _hifzNotes[aspectKey] = note;
          }
        });
      });
    } catch (e) {
      debugPrint('❌ Gagal load HIFZ diagnosis di dashboard anak: $e');
    }
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
            const Icon(Icons.notifications_active_rounded, color: Colors.white),
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
            Icon(Icons.error_outline_rounded, color: Colors.white),
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
        key: _refreshIndicatorKey,
        onRefresh: _refreshReminders,
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Header Profil Anak
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildChildHeader(),
              ),
            ),

            // Skor Overview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildScoreCard(totalScore, overallCategory),
              ),
            ),

            // HIFZ Aspects Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Text(
                  'Aspek HIFZ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),

            // List HIFZ per aspek
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final aspects = [
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

                  final aspect = aspects[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      index == 0 ? 8 : 4,
                      16,
                      index == aspects.length - 1 ? 16 : 8,
                    ),
                    child: _buildHifzAspectItem(
                      aspectKey: aspect['key'] as String,
                      title: aspect['title'] as String,
                      subtitle: aspect['subtitle'] as String,
                      score: aspect['score'] as int,
                      category: aspect['category'] as String,
                      icon: aspect['icon'] as IconData,
                      color: aspect['color'] as Color,
                    ),
                  );
                },
                childCount: 5,
              ),
            ),

            // Reminder Section (jika ada)
            if (hasPrayerReminder)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildReminderControlSection(),
                ),
              ),

            // Video Recommendations Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha:0.1),
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
              ),
            ),

            // Video Grid
            if (recommendations.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final video = recommendations[index];
                      return _buildVideoCard(video, context);
                    },
                    childCount: recommendations.length,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                  child: _buildEmptyVideos(),
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
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
            color: Colors.white.withValues(alpha:0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout_rounded, size: 20),
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
            kPrimaryColor.withValues(alpha:0.8),
            kPrimaryColor.withValues(alpha:0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha:0.3),
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
              color: Colors.white.withValues(alpha:0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha:0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.child_care_rounded,
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
                    color: Colors.white.withValues(alpha:0.9),
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
                          color: Colors.white.withValues(alpha:0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
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
          return Icons.emoji_events_rounded;
        case 'Sedang':
          return Icons.trending_up_rounded;
        case 'Rendah':
          return Icons.lightbulb_outline_rounded;
        default:
          return Icons.assessment_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            getCategoryColor().withValues(alpha:0.9),
            getCategoryColor().withValues(alpha:0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: getCategoryColor().withValues(alpha:0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stats Row dengan responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 350;

              if (isSmallScreen) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildScoreItem('Total Skor', '$totalScore', Icons.score_rounded, Colors.white),
                    const SizedBox(height: 16),
                    _buildScoreItem('Kategori', category, getCategoryIcon(), Colors.white),
                    const SizedBox(height: 16),
                    _buildScoreItem('Level', _getLevel(category), Icons.star_rate_rounded, Colors.white),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreItem('Total Skor', '$totalScore', Icons.score_rounded, Colors.white),
                    _buildScoreItem('Kategori', category, getCategoryIcon(), Colors.white),
                    _buildScoreItem('Level', _getLevel(category), Icons.star_rate_rounded, Colors.white),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  color: Colors.amber.shade300,
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

  Widget _buildScoreItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: color.withValues(alpha:0.9),
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

  Widget _buildHifzAspectItem({
    required String aspectKey,
    required String title,
    required String subtitle,
    required int score,
    required String category,
    required IconData icon,
    required Color color,
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
    final diagnosis = _hifzDiagnoses[aspectKey] ?? '';
    final note = _hifzNotes[aspectKey] ?? '';

    return GestureDetector(
      onTap: () => _showHifzDetails(hifzKey, title, color, icon),
      child: StatefulBuilder(
        builder: (context, setState) {
          bool isHovered = false;

          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHovered
                      ? [
                    color.withValues(alpha:0.1),
                    color.withValues(alpha:0.05),
                  ]
                      : [
                    color.withValues(alpha:0.05),
                    color.withValues(alpha:0.02),
                  ],
                ),
                border: Border.all(
                  color: isHovered
                      ? color.withValues(alpha:0.3)
                      : color.withValues(alpha:0.1),
                  width: isHovered ? 1.5 : 1,
                ),
                boxShadow: isHovered
                    ? [
                  BoxShadow(
                    color: color.withValues(alpha:0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [
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
                  // Header dengan icon dan skor
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha:isHovered ? 0.15 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: isHovered ? 26 : 24,
                        ),
                      ),
                      const SizedBox(width: 16),
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: color,
                                    ),
                                  ),
                                ),
                                if (isHovered)
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: color,
                                  ),
                              ],
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha:isHovered ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: isHovered ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              'Skor',
                              style: TextStyle(
                                color: color.withValues(alpha:0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar dengan kategori
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category).withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getCategoryColor(category).withValues(alpha:0.3),
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(category),
                              ),
                            ),
                          ),
                          Text(
                            '${(score / 20 * 100).round()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: score / 20,
                        backgroundColor: color.withValues(alpha:0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info Jawaban dan Tombol Detail
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
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isHovered ? color.withValues(alpha:0.15) : color.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.visibility_rounded, size: 12, color: color),
                              const SizedBox(width: 6),
                              Text(
                                'Lihat Detail',
                                style: TextStyle(fontSize: 12, color: color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Preview Jawaban (jika ada)
                  if (answers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.question_answer_rounded, size: 16, color: color),
                              const SizedBox(width: 8),
                              Text(
                                'Preview Jawaban',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...answers.take(2).map((qa) {
                            final question = qa['question'] as String? ?? '';
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
                                      question,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          if (answers.length > 2) ...[
                            const SizedBox(height: 4),
                            Text(
                              '...dan ${answers.length - 2} pertanyaan lainnya',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Feedback & Diagnosa Perawat
                  if (diagnosis.isNotEmpty || note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medical_services_rounded, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Catatan Perawat',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (diagnosis.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              diagnosis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              note,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
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
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Aman':
        return Colors.green;
      case 'Perhatian':
        return Colors.orange;
      case 'Risiko':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showHifzDetails(String hifzKey, String aspectName, Color color, IconData icon) {
    final hifzData = _hifzData[hifzKey] ?? {};
    final answers = (hifzData['answers'] as List<Map<String, dynamic>>?) ?? [];
    final score = hifzData['score'] as int? ?? 0;
    final category = hifzData['category'] as String? ?? '';
    final videos = (hifzData['videos'] as List<HifzVideo>?) ?? [];
    final maxScore = (hifzData['maxScore'] as int?) ?? 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aspectName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'Detail Analisis HIFZ',
                          style: TextStyle(
                            fontSize: 14,
                            color: color.withValues(alpha:0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Stats Overview dengan Wrap untuk responsif
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  // _buildHifzDetailStat('Skor', '$score/$maxScore', Icons.score_rounded, color),
                  // _buildHifzDetailStat('Kategori', category, Icons.category_rounded, color),
                  _buildHifzDetailStat('Status', _getStatusText(score, maxScore), Icons.assessment_rounded, _getStatusColor(score, maxScore)),
                ],
              ),
            ),

            // Video Recommendation (if available)
            if (videos.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.video_library_rounded, color: Colors.blue, size: 22),
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
                                fontSize: 14,
                              ),
                            ),
                            ...videos.take(1).map((video) => Text(
                              video.title,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Content
            Expanded(
              child: answers.isEmpty
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
                      'Belum ada data jawaban',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kuesioner untuk aspek ini belum diisi',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...answers.map((qa) {
                      final question = qa['question'] as String;
                      final answerList = qa['answers'] as List<String>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha:0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${answers.indexOf(qa) + 1}',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      question,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (answerList.isNotEmpty) ...[
                                ...answerList.map((answer) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(top: 6),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            answer,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToHifzDetailPage(hifzKey, aspectName, color, icon);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Detail Lengkap',
                            style: TextStyle(color: Colors.white),
                          ),
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

  Widget _buildHifzDetailStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
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

  void _navigateToHifzDetailPage(String hifzKey, String aspectName, Color color, IconData icon) {
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
                .withValues(alpha:0.1),
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
                  Icons.notifications_active_rounded,
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
              _buildReminderChip('Sholat 5 Waktu', Icons.mosque_rounded, Colors.green),
              _buildReminderChip('Doa Pagi', Icons.wb_sunny_rounded, Colors.orange),
              _buildReminderChip('Doa Sore', Icons.nightlight_rounded, Colors.purple),
              _buildReminderChip('Baca Quran', Icons.menu_book_rounded, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                  reminderScheduled ? () => _viewReminderSchedule() : null,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
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
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
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
          color: color.withValues(alpha:0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12, color: color),
      ),
      backgroundColor: color.withValues(alpha:0.1),
      side: BorderSide(color: color.withValues(alpha:0.3)),
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
                    child: const Icon(Icons.info_rounded,
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
                  const Icon(Icons.schedule_rounded, color: Colors.blue, size: 28),
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
                    Icon(Icons.close_rounded, color: Colors.blue.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildScheduleCategory('🕌 Waktu Sholat', [
                      _buildScheduleItem(
                          '05:30', 'Subuh', Icons.mosque_rounded, Colors.green),
                      _buildScheduleItem(
                          '12:00', 'Dzuhur', Icons.mosque_rounded, Colors.green),
                      _buildScheduleItem(
                          '15:30', 'Ashar', Icons.mosque_rounded, Colors.green),
                      _buildScheduleItem(
                          '18:00', 'Maghrib', Icons.mosque_rounded, Colors.green),
                      _buildScheduleItem(
                          '19:30', 'Isya', Icons.mosque_rounded, Colors.green),
                    ]),
                    const SizedBox(height: 20),
                    _buildScheduleCategory('🙏 Waktu Doa', [
                      _buildScheduleItem(
                          '07:00', 'Doa Pagi', Icons.wb_sunny_rounded, Colors.orange),
                      _buildScheduleItem(
                          '18:30', 'Doa Sore', Icons.nightlight_rounded, Colors.purple),
                      _buildScheduleItem(
                          '21:00', 'Doa Tidur', Icons.bedtime_rounded, Colors.blue),
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
                          const Icon(Icons.celebration_rounded,
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
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  // ==========================
  // VIDEO SECTION
  // ==========================

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
      child: StatefulBuilder(
        builder: (context, setState) {
          bool isHovered = false;

          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isHovered
                    ? [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha:0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha:0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            ? kPrimaryColor.withValues(alpha:0.1)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          if (video.effectiveThumbnail.isNotEmpty)
                            Container(
                              color: Colors.black.withValues(alpha:isHovered ? 0.4 : 0.3),
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: isHovered ? 60 : 50,
                                  height: isHovered ? 60 : 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha:isHovered ? 1.0 : 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: isHovered
                                        ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha:0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                        : [],
                                  ),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: kPrimaryColor,
                                    size: isHovered ? 35 : 30,
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
                                color: Colors.black.withValues(alpha:0.7),
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
                                    Icons.play_circle_filled_rounded,
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isHovered ? 14 : 13,
                            color: Colors.black87,
                            height: 1.3,
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
                            Icon(
                              Icons.play_circle_outline_rounded,
                              size: 12,
                              color: kPrimaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
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
        },
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
              Icons.video_library_rounded,
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
            icon: const Icon(Icons.search_rounded, size: 16),
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
                  color: Colors.red.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}