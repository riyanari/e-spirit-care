import 'package:flutter/material.dart';
import 'package:e_spirit_care/models/child_model.dart';
import 'package:e_spirit_care/pages/video_player_page.dart';
import 'package:e_spirit_care/models/video_model.dart';
import 'hifz_scoring_system.dart';

class HifzDetailPage extends StatelessWidget {
  final ChildModel child;
  final String hifzKey;

  const HifzDetailPage({
    super.key,
    required this.child,
    required this.hifzKey,
  });

  @override
  Widget build(BuildContext context) {
    final hifzData = child.getHifzData(hifzKey);
    final title = hifzData['title'] as String;
    final subtitle = hifzData['subtitle'] as String;
    final icon = hifzData['icon'] as IconData;
    final color = hifzData['color'] as Color;
    final score = hifzData['score'] as int;
    final category = hifzData['category'] as String;
    final description = hifzData['description'] as String;
    final videos = hifzData['videos'] as List<HifzVideo>;
    final answers = hifzData['answers'] as List<Map<String, dynamic>>;
    final maxScore = (hifzData['maxScore'] as int?) ?? 20;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _shareHifzDetails(context, child, hifzData),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withAlpha(230),
                    color.withAlpha(180),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(80),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withAlpha(220),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Stats Overview
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Responsive Stats Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmallScreen = constraints.maxWidth < 400;

                          if (isSmallScreen) {
                            // Vertical layout for small screens
                            return Column(
                              children: [
                                _buildStatItem('Skor', '$score/$maxScore', Icons.score_rounded, color),
                                const SizedBox(height: 16),
                                _buildStatItem('Kategori', category, Icons.category_rounded,
                                    HifzScoringSystem.getCategoryColor(category)),
                                const SizedBox(height: 16),
                                _buildStatItem('Status', _getStatusText(score, maxScore),
                                    Icons.assessment_rounded, _getStatusColor(score, maxScore)),
                              ],
                            );
                          } else {
                            // Horizontal layout for larger screens
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Flexible(
                                  child: _buildStatItem('Skor', '$score/$maxScore',
                                      Icons.score_rounded, color),
                                ),
                                Flexible(
                                  child: _buildStatItem('Kategori', category,
                                      Icons.category_rounded, HifzScoringSystem.getCategoryColor(category)),
                                ),
                                Flexible(
                                  child: _buildStatItem('Status', _getStatusText(score, maxScore),
                                      Icons.assessment_rounded, _getStatusColor(score, maxScore)),
                                ),
                              ],
                            );
                          }
                        },
                      ),

                      // Progress Section
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tingkat Risiko',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${((score / maxScore) * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getProgressColor(score / maxScore),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: score / maxScore,
                            backgroundColor: color.withAlpha(50),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(score / maxScore),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            minHeight: 12,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rendah',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                'Sedang',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                'Tinggi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Description
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: Colors.blue, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Video Recommendations Section
          if (videos.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.video_library_rounded,
                              color: color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Video Rekomendasi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${videos.length} video edukasi tersedia',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

          if (videos.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final video = videos[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      index == 0 ? 0 : 8,
                      20,
                      index == videos.length - 1 ? 20 : 8,
                    ),
                    child: _buildVideoCard(video, color, context),
                  );
                },
                childCount: videos.length,
              ),
            ),

          // Answers Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.question_answer_rounded,
                        color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jawaban Kuesioner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${answers.length} pertanyaan terjawab',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Questions and Answers List
          if (answers.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final qa = answers[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      index == 0 ? 0 : 8,
                      20,
                      index == answers.length - 1 ? 40 : 8,
                    ),
                    child: _buildQuestionCard(qa, color),
                  );
                },
                childCount: answers.length,
              ),
            ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _showAnalysis(context, child, hifzData),
      //   icon: const Icon(Icons.analytics_rounded),
      //   label: const Text('Analisis'),
      //   backgroundColor: color,
      //   foregroundColor: Colors.white,
      //   elevation: 4,
      // ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(HifzVideo video, Color color, BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return GestureDetector(
          onTap: () => _playVideo(video, context),
          onTapDown: (_) => setState(() => isHovered = true),
          onTapUp: (_) => setState(() => isHovered = false),
          onTapCancel: () => setState(() => isHovered = false),
          child: MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHovered
                      ? [
                    color.withAlpha(20),
                    Colors.white,
                    color.withAlpha(10),
                  ]
                      : [
                    Colors.white,
                    color.withAlpha(5),
                  ],
                ),
                border: Border.all(
                  color: isHovered
                      ? color.withAlpha(60)
                      : color.withAlpha(30),
                  width: isHovered ? 1.5 : 1,
                ),
                boxShadow: isHovered
                    ? [
                  BoxShadow(
                    color: color.withAlpha(30),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: color.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.grey.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Play Button with Hover Effect
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: isHovered
                            ? LinearGradient(
                          colors: [
                            color,
                            color.withAlpha(220),
                          ],
                        )
                            : LinearGradient(
                          colors: [
                            color.withAlpha(30),
                            color.withAlpha(20),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isHovered
                            ? [
                          BoxShadow(
                            color: color.withAlpha(80),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                            : [],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background Circle
                          Container(
                            width: isHovered ? 45 : 40,
                            height: isHovered ? 45 : 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(isHovered ? 240 : 230),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Play Icon with Hover Effect
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: Matrix4.identity()
                              ..scale(isHovered ? 1.2 : 1.0),
                            child: Icon(
                              isHovered
                                  ? Icons.play_arrow_rounded
                                  : Icons.play_circle_filled_rounded,
                              color: color,
                              size: isHovered ? 30 : 28,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Video Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Badge
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(isHovered ? 25 : 15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withAlpha(isHovered ? 50 : 30),
                              ),
                            ),
                            child: Text(
                              video.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          // Title with Hover Effect
                          Text(
                            video.title,
                            style: TextStyle(
                              fontSize: isHovered ? 16 : 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // Description with Duration
                          Text(
                            video.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),

                          // Hover Indicator Text
                          if (isHovered)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 12,
                                    color: color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tonton video',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Chevron with Hover Effect
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? color.withAlpha(20)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: isHovered ? color : Colors.grey[400],
                        size: isHovered ? 20 : 18,
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

  Widget _buildQuestionCard(Map<String, dynamic> qa, Color color) {
    final question = qa['question'] as String;
    final answers = qa['answers'] as List<String>;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(20)),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.question_mark_rounded,
            size: 16,
            color: color,
          ),
        ),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: answers.map((answer) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withAlpha(25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          answer,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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

  Color _getProgressColor(double value) {
    if (value <= 0.3) return Colors.green;
    if (value <= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _playVideo(HifzVideo video, BuildContext context) {
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

  void _shareHifzDetails(BuildContext context, ChildModel child, Map<String, dynamic> hifzData) {
    final title = hifzData['title'] as String;
    final score = hifzData['score'] as int;
    final category = hifzData['category'] as String;
    final color = hifzData['color'] as Color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.share_rounded, color: color),
            const SizedBox(width: 12),
            const Text('Bagikan Detail'),
          ],
        ),
        content: Text(
          'Bagikan detail $title untuk ${child.name}?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Detail $title telah disalin'),
                  backgroundColor: color,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
            ),
            child: const Text(
              'Bagikan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnalysis(BuildContext context, ChildModel child, Map<String, dynamic> hifzData) {
    final title = hifzData['title'] as String;
    final score = hifzData['score'] as int;
    final category = hifzData['category'] as String;
    final description = hifzData['description'] as String;
    final videos = hifzData['videos'] as List<HifzVideo>;
    final maxScore = (hifzData['maxScore'] as int?) ?? 20;
    final color = hifzData['color'] as Color;

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
                color: color.withAlpha(10),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.analytics_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analisis $title',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rekomendasi berdasarkan skor $score/$maxScore',
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analysis Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assessment_rounded, color: color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status: $_getStatusText(score, maxScore)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                    Text(
                                      'Kategori: $category',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Video Recommendations
                    if (videos.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        '📹 Rekomendasi Tindakan:',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...videos.take(3).map((video) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.video_library_rounded,
                                color: color, size: 20),
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
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey[400],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _playVideo(video, context);
                          },
                        ),
                      )).toList(),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}