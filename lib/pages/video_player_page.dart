// pages/video_player_page.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import '../theme/theme.dart';

class VideoPlayerPage extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();

    final videoId = widget.video.effectiveYoutubeId;

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'id',
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      // Handle player state changes jika diperlukan
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.video.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // YouTube Player
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: kPrimaryColor,
            progressColors: const ProgressBarColors(
              playedColor: kPrimaryColor,
              handleColor: kPrimaryColor,
            ),
            onReady: () {
              setState(() {
                _isPlayerReady = true;
              });
            },
            onEnded: (data) {
              // Optional: Handle when video ends
            },
          ),

          // Video Info Section
          Expanded(
            child: Container(
              color: kBackgroundColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Meta Info
                    Row(
                      children: [
                        _buildMetaItem(Icons.timer, widget.video.duration),
                        const SizedBox(width: 16),
                        _buildMetaItem(Icons.category, widget.video.category),
                        const SizedBox(width: 16),
                        _buildMetaItem(Icons.play_circle_filled, 'YouTube'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Deskripsi Video',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.description.isNotEmpty
                          ? widget.video.description
                          : _getDefaultDescription(widget.video),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Learning Tips
                    _buildLearningTips(widget.video),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kPrimaryColor),
        const SizedBox(width: 4),
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

  String _getDefaultDescription(VideoModel video) {
    if (video.category == 'Edukasi doa') {
      return 'Video edukasi doa yang disajikan dengan cara yang menyenangkan dan mudah dipahami oleh anak. Dilengkapi dengan visualisasi menarik dan pengucapan yang jelas untuk membantu anak dalam menghafal doa-doa harian.';
    } else {
      return 'Kisah inspiratif dari sejarah Islam yang dikemas dalam format video animasi menarik. Membantu anak memahami nilai-nilai moral dan akhlak mulia melalui cerita yang edukatif.';
    }
  }

  Widget _buildLearningTips(VideoModel video) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: kPrimaryColor),
              const SizedBox(width: 8),
              Text(
                'Tips Belajar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Ajak anak untuk mengikuti dan mengulang doa\n• Tanyakan pemahaman anak tentang cerita\n• Diskusikan nilai moral yang dapat dipelajari',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}