import '../models/child_model.dart';
import '../models/video_model.dart';
import '../pages/hifz_scoring_system.dart';

class VideoService {
  /// VIDEO DATABASE untuk sistem baru berdasarkan HIFZ
  /// Menggunakan data video dari HifzScoringSystem

  /// Mendapatkan semua video rekomendasi untuk seorang anak
  /// berdasarkan semua aspek HIFZ mereka
  List<VideoModel> getVideoRecommendations(ChildModel child) {
    final recommendations = <VideoModel>{};

    // Ambil video untuk setiap HIFZ berdasarkan kategori
    final hifzKeys = ['ad_diin', 'an_nafs', 'al_aql', 'an_nasl', 'al_mal'];

    for (final key in hifzKeys) {
      final hifzData = child.getHifzData(key);
      final category = hifzData['category'] as String;
      final hifzVideos = HifzScoringSystem.getVideos(key, category);

      // Konversi HifzVideo ke VideoModel
      for (final hifzVideo in hifzVideos) {
        final videoModel = VideoModel(
          id: hifzVideo.url.hashCode.toString(),
          title: hifzVideo.title,
          description: hifzVideo.description,
          url: hifzVideo.url,
          category: hifzVideo.category,
          thumbnail: '',
          duration: '5:00', // Default duration
        );

        // Gunakan Set untuk menghindari duplikat
        recommendations.add(videoModel);
      }
    }

    return recommendations.toList();
  }

  /// Mendapatkan video untuk HIFZ spesifik
  List<VideoModel> getVideosForHifz(String hifzKey, String category) {
    final hifzVideos = HifzScoringSystem.getVideos(hifzKey, category);

    return hifzVideos.map((hifzVideo) => VideoModel(
      id: hifzVideo.url.hashCode.toString(),
      title: hifzVideo.title,
      description: hifzVideo.description,
      url: hifzVideo.url,
      category: hifzVideo.category,
      thumbnail: '',
      duration: '5:00',
    )).toList();
  }

  /// Untuk backward compatibility - mendapatkan video berdasarkan kategori lama
  /// (Tinggi, Sedang, Rendah)
  List<VideoModel> getVideosByDevelopmentCategory(String kategori) {
    // Map kategori lama ke HIFZ tertentu untuk memberikan rekomendasi
    switch (kategori) {
      case 'Tinggi':
      // Untuk kategori tinggi, ambil video dari semua HIFZ dengan kategori baik
        return [
          ...getVideosForHifz('ad_diin', 'Kesejahteraan Spiritual'),
          ...getVideosForHifz('an_nafs', 'Aman / risiko minimal'),
          ...getVideosForHifz('al_aql', 'Perkembangan baik'),
          ...getVideosForHifz('an_nasl', 'Pola asuh baik'),
          ...getVideosForHifz('al_mal', 'Kecukupan ekonomi baik'),
        ].take(4).toList(); // Ambil maksimal 4 video

      case 'Sedang':
      // Untuk kategori sedang, ambil video dari HIFZ dengan kategori risiko
        return [
          ...getVideosForHifz('ad_diin', 'Risiko Distres Spiritual'),
          ...getVideosForHifz('an_nafs', 'Risiko sedang'),
          ...getVideosForHifz('al_aql', 'Risiko keterlambatan / stimulasi kurang'),
          ...getVideosForHifz('an_nasl', 'Risiko pola asuh tidak adekuat'),
          ...getVideosForHifz('al_mal', 'Risiko ketidakcukupan ekonomi'),
        ].take(6).toList(); // Ambil maksimal 6 video

      case 'Rendah':
      // Untuk kategori rendah, ambil video dari HIFZ dengan kategori masalah
        return [
          ...getVideosForHifz('ad_diin', 'Distres Spiritual'),
          ...getVideosForHifz('an_nafs', 'Risiko tinggi / perlu intervensi segera'),
          ...getVideosForHifz('al_aql', 'Gangguan perkembangan, butuh evaluasi lanjutan'),
          ...getVideosForHifz('an_nasl', 'Pola asuh buruk / risiko perlakuan salah'),
          ...getVideosForHifz('al_mal', 'Ketidakcukupan berat / perlu rujukan sosial'),
        ].take(8).toList(); // Ambil maksimal 8 video

      default:
        return [];
    }
  }

  /// Pencarian video (untuk fitur search jika diperlukan)
  List<VideoModel> searchVideos(String query, List<VideoModel> videos) {
    return videos
        .where((video) =>
    video.title.toLowerCase().contains(query.toLowerCase()) ||
        video.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Filter video berdasarkan kategori video (untuk tampilan grid)
  List<VideoModel> getVideosByVideoCategory(
      List<VideoModel> videos, String videoCategory) {
    return videos.where((video) => video.category == videoCategory).toList();
  }

  /// Video khusus untuk reminder/prayer (jika masih diperlukan)
  List<VideoModel> getPrayerReminderVideos() {
    // Video khusus untuk pengingat sholat/doa
    return [
      VideoModel(
        id: 'prayer1',
        title: 'Lagu Doa Harian Anak Kecil Terbaru 2024',
        category: 'Edukasi doa',
        url: 'https://youtu.be/pf89qr1rnrQ',
        duration: '4:30',
        description: 'Kumpulan doa harian dengan irama yang mudah diikuti anak.',
      ),
      VideoModel(
        id: 'prayer2',
        title: 'Kenapa Kita Harus Sholat?',
        category: 'Cerita Islam',
        url: 'https://youtu.be/wY3hX4R7rF0',
        duration: '6:30',
        description: 'Penjelasan sederhana dan menyentuh tentang pentingnya sholat bagi anak.',
      ),
      VideoModel(
        id: 'prayer3',
        title: 'Kumpulan Doa dengan Lagu',
        category: 'Edukasi doa',
        url: 'https://youtu.be/6auN-MKWFqQ',
        duration: '5:00',
        description: 'Doa harian dalam bentuk lagu ceria agar anak mudah menghafal.',
      ),
    ];
  }
}