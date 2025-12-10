// pages/hifz_detail_page.dart

import 'package:flutter/material.dart';
import 'package:e_spirit_care/models/child_model.dart';

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
    final video = hifzData['video'] as String;
    final answers = hifzData['answers'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareHifzDetails(context, child, hifzData),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                border: Border(
                  bottom: BorderSide(color: color.withValues(alpha:0.2)),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: color.withValues(alpha:0.2),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: color.withValues(alpha:0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Stats Overview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Skor',
                        '$score',
                        Icons.score,
                        color,
                      ),
                      _buildStatItem(
                        'Kategori',
                        category,
                        Icons.category,
                        color,
                      ),
                      _buildStatItem(
                        'Status',
                        _getStatusText(category),
                        Icons.assessment,
                        color,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Video Recommendation
            if (video.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
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
                          children: [
                            Icon(
                              Icons.video_library,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Rekomendasi Video:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          video,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Answers Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Jawaban Kuesioner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Berikut adalah jawaban untuk pertanyaan dalam aspek ini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Questions and Answers
            ...answers.map((qa) => _buildQuestionCard(qa, color)),

            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAnalysis(context, child, hifzData);
        },
        icon: const Icon(Icons.analytics),
        label: const Text('Analisis'),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> qa, Color color) {
    final question = qa['question'] as String;
    final answers = qa['answers'] as List<String>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha:0.1)),
        ),
        child: ExpansionTile(
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: answers.map((answer) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha:0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withValues(alpha:0.1),
                              ),
                            ),
                            child: Text(
                              answer,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
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
      ),
    );
  }

  String _getStatusText(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('aman') ||
        lower.contains('baik') ||
        lower.contains('sejahteraan') ||
        lower.contains('perkembangan baik') ||
        lower.contains('pola asuh baik') ||
        lower.contains('kecukupan ekonomi baik')) {
      return 'Baik';
    } else if (lower.contains('risiko')) {
      return 'Perhatian';
    } else if (lower.contains('distres') ||
        lower.contains('gangguan') ||
        lower.contains('buruk') ||
        lower.contains('ketidakcukupan')) {
      return 'Perlu Intervensi';
    }
    return 'Sedang';
  }

  void _shareHifzDetails(BuildContext context, ChildModel child, Map<String, dynamic> hifzData) {
    final title = hifzData['title'] as String;
    // final score = hifzData['score'] as int;
    // final category = hifzData['category'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bagikan Detail Hifz'),
        content: Text('Bagikan detail $title untuk ${child.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement share functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Detail $title telah disalin'),
                  backgroundColor: hifzData['color'] as Color,
                ),
              );
            },
            child: const Text('Bagikan'),
          ),
        ],
      ),
    );
  }

  void _showAnalysis(BuildContext context, ChildModel child, Map<String, dynamic> hifzData) {
    final title = hifzData['title'] as String;
    final score = hifzData['score'] as int;
    final category = hifzData['category'] as String;
    final video = hifzData['video'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analisis $title',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _getAnalysisText(category, score, title),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (video.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📹 Rekomendasi Tindakan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(video),
                    ],
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: hifzData['color'] as Color,
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAnalysisText(String category, int score, String title) {
    if (category.toLowerCase().contains('aman') ||
        category.toLowerCase().contains('baik')) {
      return 'Aspek $title dalam kondisi baik (skor: $score). ${child.name} menunjukkan perkembangan yang optimal dalam aspek ini. Pertahankan dan konsisten dalam memberikan dukungan.';
    } else if (category.toLowerCase().contains('risiko')) {
      return 'Aspek $title memerlukan perhatian (skor: $score). Terdapat beberapa indikasi risiko yang perlu dipantau. Disarankan untuk memberikan intervensi dini.';
    } else {
      return 'Aspek $title memerlukan intervensi segera (skor: $score). Kondisi ini menunjukkan adanya masalah yang perlu ditangani dengan serius. Disarankan konsultasi dengan profesional.';
    }
  }
}