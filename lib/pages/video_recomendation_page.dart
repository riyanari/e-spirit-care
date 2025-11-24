// pages/video_recommendations_page.dart
import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../models/scheduled_reminder_model.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import '../services/reminder_service.dart';
import '../theme/theme.dart';

class VideoRecommendationsPage extends StatefulWidget {
  final ChildModel child;

  const VideoRecommendationsPage({super.key, required this.child});

  @override
  State<VideoRecommendationsPage> createState() => _VideoRecommendationsPageState();
}

class _VideoRecommendationsPageState extends State<VideoRecommendationsPage> {
  final VideoService videoService = VideoService();
  late List<VideoModel> recommendations;
  late int totalScore;
  late String category;
  bool hasPrayerReminder = false;
  bool reminderScheduled = false;
  List<ScheduledReminder> _scheduledReminders = [];
  bool _isLoadingReminders = false;

  @override
  void initState() {
    super.initState();

    recommendations = videoService.getVideoRecommendations(widget.child);
    totalScore = widget.child.totalSkor;
    category = widget.child.kategori;
    hasPrayerReminder = _checkPrayerReminder();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupReminders();
      _loadScheduledReminders();
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
        _scheduledReminders = reminders.map((reminder) => ScheduledReminder(
          id: reminder['id'] as int,
          title: reminder['title'] as String,
          body: reminder['body'] as String,
          type: reminder['type'] as String,
          scheduledTime: reminder['scheduledTime'] as String,
        )).toList();
        reminderScheduled = reminders.isNotEmpty;
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
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
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
        duration: Duration(seconds: 4),
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
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Gagal mengaktifkan reminder. Coba lagi nanti.'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _refreshReminders() async {
    await _loadScheduledReminders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder diperbarui'),
        duration: Duration(seconds: 1),
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
          'Rekomendasi Video',
          style: TextStyle(
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
          SizedBox(width: 8),
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
              // Header dengan informasi anak - SAMA dengan ChildDashboardPage
              _buildChildHeader(),
              const SizedBox(height: 24),

              // Card informasi skor dan kategori - SAMA dengan ChildDashboardPage
              _buildScoreCard(totalScore, category),
              const SizedBox(height: 24),

              // Section reminder jika ada pengingat doa - SAMA dengan ChildDashboardPage
              if (hasPrayerReminder) _buildReminderControlSection(),
              const SizedBox(height: 24),

              // Video Rekomendasi dengan tampilan yang ditingkatkan
              _buildVideoRecommendations(),
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
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(Icons.refresh_rounded),
      ),
      onPressed: _isLoadingReminders ? null : _refreshReminders,
      tooltip: 'Refresh Reminders',
    );
  }

  // METHOD-METHOD YANG SAMA PERSIS DENGAN ChildDashboardPage

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
              border: Border.all(color: Colors.white.withValues(alpha:0.3), width: 2),
            ),
            child: Icon(
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
                    color: Colors.white.withValues(alpha:0.9),
                    fontSize: 14,
                  ),
                ),
                if (hasPrayerReminder && reminderScheduled) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_active, size: 12, color: Colors.white),
                      ),
                      SizedBox(width: 6),
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
          return 'Perkembangan agama anak sudah baik. Pertahankan! 🎉';
        case 'Sedang':
          return 'Perkembangan agama anak cukup baik. Tingkatkan lagi! 💪';
        case 'Rendah':
          return 'Perlu perhatian lebih untuk pendidikan agama anak. 🌱';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreItem('Total Skor', '$totalScore', Icons.assessment_outlined),
              _buildScoreItem('Kategori', category, getCategoryIcon()),
              _buildScoreItem('Level', _getLevel(category), Icons.star_rate_rounded),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
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
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.2),
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
            color: Colors.white.withValues(alpha:0.9),
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

  Widget _buildReminderControlSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
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
          color: reminderScheduled ? Colors.green.shade100 : Colors.blue.shade100,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (reminderScheduled ? Colors.green : Colors.blue).withValues(alpha:0.1),
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
                duration: Duration(milliseconds: 500),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: reminderScheduled ? Colors.green : Colors.blue.shade700,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminderScheduled ? 'Reminder Aktif 🎯' : 'Mengaktifkan Reminder...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: reminderScheduled ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Berdasarkan harapan "Pengingat Doa"',
                      style: TextStyle(
                        color: reminderScheduled ? Colors.green.shade600 : Colors.blue.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!reminderScheduled) ...[
                SizedBox(width: 8),
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
          SizedBox(height: 16),
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
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: reminderScheduled ? () => _viewReminderSchedule() : null,
                  icon: Icon(Icons.schedule, size: 18),
                  label: Text('Lihat Jadwal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: reminderScheduled ? Colors.green : Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  icon: Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showReminderInfo(),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          if (reminderScheduled) ...[
            SizedBox(height: 12),
            Divider(color: Colors.green.shade200),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 6),
                GestureDetector(
                  onTap: _manageReminders,
                  child: Text(
                    'Kelola Pengaturan Reminder',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderChip(String text, IconData icon, Color color) {
    return Chip(
      label: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
          padding: EdgeInsets.all(24),
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
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 12),
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
              SizedBox(height: 16),
              Text(
                'Reminder doa dan sholat diaktifkan secara otomatis berdasarkan harapan yang tercatat untuk ${widget.child.name}.',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              _buildInfoItem('⏰', 'Jadwal otomatis sesuai waktu sholat'),
              _buildInfoItem('🔔', 'Notifikasi akan muncul tepat waktu'),
              _buildInfoItem('📱', 'Dapat diatur ulang di pengaturan'),
              SizedBox(height: 20),
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
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 12),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
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
                padding: EdgeInsets.all(16),
                children: [
                  _buildScheduleCategory('🕌 Waktu Sholat', [
                    _buildScheduleItem('05:30', 'Subuh', Icons.mosque, Colors.green),
                    _buildScheduleItem('12:00', 'Dzuhur', Icons.mosque, Colors.green),
                    _buildScheduleItem('15:30', 'Ashar', Icons.mosque, Colors.green),
                    _buildScheduleItem('18:00', 'Maghrib', Icons.mosque, Colors.green),
                    _buildScheduleItem('19:30', 'Isya', Icons.mosque, Colors.green),
                  ]),
                  SizedBox(height: 20),
                  _buildScheduleCategory('🙏 Waktu Doa', [
                    _buildScheduleItem('07:00', 'Doa Pagi', Icons.wb_sunny, Colors.orange),
                    _buildScheduleItem('18:30', 'Doa Sore', Icons.nightlight, Colors.purple),
                    _buildScheduleItem('21:00', 'Doa Tidur', Icons.bedtime, Colors.blue),
                  ]),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.celebration, color: Colors.green, size: 24),
                        SizedBox(width: 12),
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
                              SizedBox(height: 4),
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
                  SizedBox(height: 16),
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
                      children: [
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
        SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildScheduleItem(String time, String activity, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          SizedBox(width: 16),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
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
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
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
                child: Icon(
                  Icons.notifications_off,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Nonaktifkan Reminder?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Reminder doa dan sholat untuk ${widget.child.name} akan dinonaktifkan. Anda dapat mengaktifkannya kembali kapan saja.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text('Batal'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ReminderService.cancelAllReminders();
                        setState(() {
                          reminderScheduled = false;
                          _scheduledReminders.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reminder doa & sholat telah dinonaktifkan'),
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
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Nonaktifkan'),
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

  // BAGIAN VIDEO REKOMENDASI YANG DIPERBARUI
  Widget _buildVideoRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        SizedBox(height: 8),
        Text(
          'Konten edukasi berdasarkan perkembangan ${widget.child.name}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 20),
        recommendations.isEmpty
            ? _buildEmptyVideos()
            : GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
        _showVideoDetail(video);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha:0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withValues(alpha:0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withValues(alpha:0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: _getCategoryColor(category),
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          video.duration,
                          style: TextStyle(
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
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.category_outlined, size: 12, color: Colors.grey.shade500),
                      SizedBox(width: 4),
                      Text(
                        video.category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
            child: Icon(Icons.video_library, size: 40, color: Colors.grey.shade400),
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
        ],
      ),
    );
  }

  void _showVideoDetail(VideoModel video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Header dengan close button
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withValues(alpha:0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_filled, color: _getCategoryColor(category), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detail Video',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video thumbnail besar
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category).withValues(alpha:0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: _getCategoryColor(category),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Video info
                    Text(
                      video.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Meta info
                    Row(
                      children: [
                        _buildMetaItem(Icons.timer, '${video.duration}'),
                        SizedBox(width: 16),
                        _buildMetaItem(Icons.category, video.category),
                        SizedBox(width: 16),
                        _buildMetaItem(Icons.emoji_events, category),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Deskripsi
                    Text(
                      'Deskripsi Video',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _getVideoDescription(video.title),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text('Tutup'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _playVideo(video);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getCategoryColor(category),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
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
        Icon(icon, size: 16, color: Colors.grey.shade500),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getVideoDescription(String title) {
    if (title.toLowerCase().contains('doa')) {
      return 'Video ini mengajarkan doa-doa harian yang mudah dihafal oleh anak. Dilengkapi dengan visualisasi yang menarik dan penjelasan sederhana tentang makna setiap doa. Cocok untuk anak usia dini yang sedang belajar berdoa. Setiap doa diucapkan dengan pelafalan yang jelas dan diulang beberapa kali untuk memudahkan anak dalam menghafal.';
    } else if (title.toLowerCase().contains('kisah') || title.toLowerCase().contains('cerita')) {
      return 'Kisah inspiratif dari sejarah Islam yang disajikan dengan animasi menarik. Membantu anak memahami nilai-nilai moral dan akhlak mulia melalui cerita para nabi dan sahabat. Dilengkapi dengan pesan moral yang mudah dipahami anak-anak dan aplikasinya dalam kehidupan sehari-hari.';
    } else {
      return 'Video edukasi Islami yang dirancang khusus untuk anak. Menggunakan pendekatan yang menyenangkan dan mudah dipahami, membantu menanamkan nilai-nilai agama sejak usia dini. Konten disesuaikan dengan tingkat perkembangan anak dan disajikan dengan visual yang menarik.';
    }
  }

  void _playVideo(VideoModel video) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.play_circle_filled, color: Colors.white),
            SizedBox(width: 8),
            Text('Memutar: ${video.title}'),
          ],
        ),
        backgroundColor: _getCategoryColor(category),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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
}