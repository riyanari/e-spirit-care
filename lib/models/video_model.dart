// models/video_model.dart
class VideoModel {
  final String id;
  final String title;
  final String category;
  final String url;
  final String duration;
  final String description;
  final String thumbnail;
  final String? youtubeId;

  VideoModel({
    required this.id,
    required this.title,
    required this.category,
    required this.url,
    required this.duration,
    this.description = '',
    this.thumbnail = '',
    this.youtubeId,
  });

  // Method untuk mendapatkan YouTube ID
  String get effectiveYoutubeId {
    if (youtubeId != null && youtubeId!.isNotEmpty) {
      return youtubeId!;
    }
    return _extractYouTubeId(url);
  }

  String _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
    );
    final match = regExp.firstMatch(url);
    return (match != null && match.group(7) != null && match.group(7)!.length == 11)
        ? match.group(7)!
        : '';
  }

  // Method untuk mendapatkan thumbnail URL
  String get effectiveThumbnail {
    if (thumbnail.isNotEmpty) return thumbnail;
    final ytId = effectiveYoutubeId;
    return ytId.isNotEmpty
        ? 'https://img.youtube.com/vi/$ytId/hqdefault.jpg'
        : '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VideoModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}