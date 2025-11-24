// services/video_service.dart
import '../models/child_model.dart';
import '../models/video_model.dart';

class VideoService {
  // Data video berdasarkan kategori perkembangan anak dengan YouTube links
  final Map<String, List<VideoModel>> videoDatabase = {
    'Tinggi': [
      VideoModel(
        id: 'v1',
        title: 'Doa Harian Lengkap untuk Anak Pintar',
        category: 'Edukasi doa',
        url: 'https://www.youtube.com/watch?v=ABC123', // Ganti dengan YouTube ID yang sesuai
        duration: '5:00',
        description: 'Belajar doa sehari-hari dengan cara menyenangkan',
        thumbnail: 'https://img.youtube.com/vi/ABC123/hqdefault.jpg',
        youtubeId: 'ABC123',
      ),
      VideoModel(
        id: 'v2',
        title: 'Doa Spesifik Situasi Penting',
        category: 'Edukasi doa',
        url: 'https://www.youtube.com/watch?v=DEF456',
        duration: '4:30',
        description: 'Doa untuk berbagai situasi dalam kehidupan',
        thumbnail: 'https://img.youtube.com/vi/DEF456/hqdefault.jpg',
        youtubeId: 'DEF456',
      ),
      VideoModel(
        id: 'v3',
        title: 'Kisah Nabi Muhammad SAW - Perjalanan Hidup',
        category: 'Cerita Islam',
        url: 'https://www.youtube.com/watch?v=GHI789',
        duration: '7:00',
        description: 'Kisah inspiratif Nabi Muhammad sejak kecil',
        thumbnail: 'https://img.youtube.com/vi/GHI789/hqdefault.jpg',
        youtubeId: 'GHI789',
      ),
      VideoModel(
        id: 'v4',
        title: 'Kisah Sahabat Nabi yang Mulia',
        category: 'Cerita Islam',
        url: 'https://www.youtube.com/watch?v=JKL012',
        duration: '6:30',
        description: 'Teladan dari para sahabat Rasulullah',
        thumbnail: 'https://img.youtube.com/vi/JKL012/hqdefault.jpg',
        youtubeId: 'JKL012',
      ),
      VideoModel(
        id: 'v5',
        title: 'Doa sebelum dan sesudah Belajar',
        category: 'Edukasi doa',
        url: 'https://www.youtube.com/watch?v=MNO345',
        duration: '3:45',
        description: 'Doa untuk keberkahan dalam menuntut ilmu',
        thumbnail: 'https://img.youtube.com/vi/MNO345/hqdefault.jpg',
        youtubeId: 'MNO345',
      ),
      VideoModel(
        id: 'v6',
        title: 'Kisah Nabi Ibrahim dan Ismail',
        category: 'Cerita Islam',
        url: 'https://www.youtube.com/watch?v=PQR678',
        duration: '8:15',
        description: 'Kisah keteladanan dan ketaatan',
        thumbnail: 'https://img.youtube.com/vi/PQR678/hqdefault.jpg',
        youtubeId: 'PQR678',
      ),
    ],
    'Sedang': [
      VideoModel(
        id: 'v7',
        title: 'Doa Dasar Harian untuk Pemula',
        category: 'Edukasi doa',
        url: 'https://www.youtube.com/watch?v=STU901',
        duration: '4:00',
        description: 'Doa-doa penting untuk kegiatan sehari-hari',
        thumbnail: 'https://img.youtube.com/vi/STU901/hqdefault.jpg',
        youtubeId: 'STU901',
      ),
      VideoModel(
        id: 'v8',
        title: 'Doa Makan, Minum, dan Tidur',
        category: 'Edukasi doa',
        url: 'https://www.youtube.com/watch?v=VWX234',
        duration: '3:30',
        description: 'Doa untuk aktivitas rutin harian',
        thumbnail: 'https://img.youtube.com/vi/VWX234/hqdefault.jpg',
        youtubeId: 'VWX234',
      ),
      VideoModel(
        id: 'v9',
        title: 'Doa Sebelum dan Sesudah Wudhu',
        category: 'Edukasi doa',
        url: 'https://www.youtube.com/watch?v=YZA567',
        duration: '4:30',
        description: 'Doa menyempurnakan wudhu',
        thumbnail: 'https://img.youtube.com/vi/YZA567/hqdefault.jpg',
        youtubeId: 'YZA567',
      ),
      VideoModel(
        id: 'v10',
        title: 'Kisah Nabi Adam - Manusia Pertama',
        category: 'Cerita Islam',
        url: 'https://www.youtube.com/watch?v=BCD890',
        duration: '6:00',
        description: 'Kisah penciptaan manusia pertama',
        thumbnail: 'https://img.youtube.com/vi/BCD890/hqdefault.jpg',
        youtubeId: 'BCD890',
      ),
      VideoModel(
        id: 'v11',
        title: 'Kisah Nabi Ibrahim Mencari Tuhan',
        category: 'Cerita Islam',
        url: 'https://www.youtube.com/watch?v=CDE123',
        duration: '5:30',
        description: 'Perjalanan spiritual Nabi Ibrahim',
        thumbnail: 'https://img.youtube.com/vi/CDE123/hqdefault.jpg',
        youtubeId: 'CDE123',
      ),
      VideoModel(
        id: 'v12',
        title: 'Kisah Nabi Musa dan Fir\'aun',
        category: 'Cerita Islam',
        url: 'https://www.youtube.com/watch?v=EFG456',
        duration: '6:30',
        description: 'Kisah keberanian melawan kezaliman',
        thumbnail: 'https://img.youtube.com/vi/EFG456/hqdefault.jpg',
        youtubeId: 'EFG456',
      ),
    ],
    'Rendah': [
      VideoModel(
        id: 'v13',
        title: 'Doa Sangat Dasar - Bismillah',
        category: 'Edukasi doa',
        url: 'https://www.youtube.com/watch?v=HIJ789',
        duration: '3:00',
        description: 'Mengenal kalimat Bismillah',
        thumbnail: 'https://img.youtube.com/vi/HIJ789/hqdefault.jpg',
        youtubeId: 'HIJ789',
      ),
      VideoModel(
        id: 'v14',
        title: 'Doa Alhamdulillah dan Masya Allah',
        category: 'Edukasi doa',
        url: 'https://www.youtube.com/watch?v=KLM012',
        duration: '3:30',
        description: 'Doa syukur dan kekaguman',
        thumbnail: 'https://img.youtube.com/vi/KLM012/hqdefault.jpg',
        youtubeId: 'KLM012',
      ),
      VideoModel(
        id: 'v15',
        title: 'Doa Subhanallah dan Astaghfirullah',
        category: 'Edukasi doa',
        url: 'https://www.youtube.com/watch?v=NOP345',
        duration: '4:00',
        description: 'Doa tasbih dan istighfar',
        thumbnail: 'https://img.youtube.com/vi/NOP345/hqdefault.jpg',
        youtubeId: 'NOP345',
      ),
      VideoModel(
        id: 'v16',
        title: 'Cerita Islami Dasar - Si Kecil yang Jujur',
        category: 'Cerita Islam',
        url: 'https://www.youtube.com/watch?v=QRS678',
        duration: '5:00',
        description: 'Kisah tentang kejujuran dalam Islam',
        thumbnail: 'https://img.youtube.com/vi/QRS678/hqdefault.jpg',
        youtubeId: 'QRS678',
      ),
      VideoModel(
        id: 'v17',
        title: 'Cerita Islami - Berbagi itu Indah',
        category: 'Cerita Islam',
        url: 'https://www.youtube.com/watch?v=TUV901',
        duration: '5:30',
        description: 'Kisah tentang pentingnya berbagi',
        thumbnail: 'https://img.youtube.com/vi/TUV901/hqdefault.jpg',
        youtubeId: 'TUV901',
      ),
      VideoModel(
        id: 'v18',
        title: 'Cerita Islami - Menghormati Orang Tua',
        category: 'Cerita Islam',
        url: 'https://www.youtube.com/watch?v=VWX234',
        duration: '6:00',
        description: 'Kisah tentang bakti kepada orang tua',
        thumbnail: 'https://img.youtube.com/vi/VWX234/hqdefault.jpg',
        youtubeId: 'VWX234',
      ),
    ],
  };

  // Method untuk mendapatkan rekomendasi video berdasarkan child
  List<VideoModel> getVideoRecommendations(ChildModel child) {
    final List<VideoModel> recommendations = [];

    // Dapatkan semua video untuk kategori perkembangan anak
    final allVideos = videoDatabase[child.kategori] ?? [];

    // Filter video berdasarkan harapan yang dipilih
    if (child.harapan.isNotEmpty) {
      for (String harapan in child.harapan) {
        // Konversi harapan ke kategori video yang sesuai
        final videoCategory = _mapHarapanToCategory(harapan);

        // Ambil video dengan kategori yang sesuai
        final categoryVideos = allVideos
            .where((video) => video.category == videoCategory)
            .toList();

        // Tentukan jumlah video berdasarkan kategori perkembangan
        final int videosToTake = _getVideosCount(child.kategori, categoryVideos.length);

        // Ambil video secara acak untuk variasi
        final selectedVideos = categoryVideos.take(videosToTake).toList();
        recommendations.addAll(selectedVideos);
      }
    }

    // Jika tidak ada rekomendasi spesifik, berikan video default
    if (recommendations.isEmpty) {
      return _getBalancedDefaultVideos(child.kategori, allVideos);
    }

    // Pastikan ada keseimbangan antara edukasi doa dan cerita islam
    return _balanceVideoCategories(recommendations, child.kategori);
  }

  // Map harapan ke kategori video
  String _mapHarapanToCategory(String harapan) {
    if (harapan.toLowerCase().contains('doa') ||
        harapan.toLowerCase().contains('pengingat')) {
      return 'Edukasi doa';
    } else {
      return 'Cerita Islam';
    }
  }

  int _getVideosCount(String kategori, int availableCount) {
    switch (kategori) {
      case 'Tinggi':
        return availableCount >= 2 ? 2 : availableCount;
      case 'Sedang':
        return availableCount >= 3 ? 3 : availableCount;
      case 'Rendah':
        return availableCount >= 4 ? 4 : availableCount;
      default:
        return 2;
    }
  }

  List<VideoModel> _getBalancedDefaultVideos(String kategori, List<VideoModel> allVideos) {
    final int defaultCount = _getDefaultVideoCount(kategori);

    // Pisahkan video berdasarkan kategori
    final edukasiDoaVideos = allVideos.where((v) => v.category == 'Edukasi doa').toList();
    final ceritaIslamVideos = allVideos.where((v) => v.category == 'Cerita Islam').toList();

    // Ambil secara seimbang
    final edukasiCount = (defaultCount / 2).ceil();
    final ceritaCount = (defaultCount / 2).floor();

    final List<VideoModel> defaultVideos = [];

    // Tambahkan video edukasi doa
    if (edukasiDoaVideos.isNotEmpty) {
      defaultVideos.addAll(edukasiDoaVideos.take(edukasiCount));
    }

    // Tambahkan video cerita islam
    if (ceritaIslamVideos.isNotEmpty) {
      defaultVideos.addAll(ceritaIslamVideos.take(ceritaCount));
    }

    // Jika masih kurang, tambahkan dari kategori mana saja
    if (defaultVideos.length < defaultCount) {
      final remaining = defaultCount - defaultVideos.length;
      defaultVideos.addAll(allVideos.take(remaining));
    }

    return defaultVideos;
  }

  int _getDefaultVideoCount(String kategori) {
    switch (kategori) {
      case 'Tinggi':
        return 4;
      case 'Sedang':
        return 6;
      case 'Rendah':
        return 8;
      default:
        return 4;
    }
  }

  List<VideoModel> _balanceVideoCategories(List<VideoModel> videos, String kategori) {
    final edukasiCount = videos.where((v) => v.category == 'Edukasi doa').length;
    final ceritaCount = videos.where((v) => v.category == 'Cerita Islam').length;

    final totalTarget = _getDefaultVideoCount(kategori);
    final targetEach = (totalTarget / 2).ceil();

    // Jika sudah seimbang, return as is
    if (edukasiCount >= targetEach ~/ 2 && ceritaCount >= targetEach ~/ 2) {
      return videos.take(totalTarget).toList();
    }

    // Jika tidak seimbang, ambil lebih banyak dari kategori yang kurang
    final allVideos = videoDatabase[kategori] ?? [];
    final List<VideoModel> balancedVideos = List.from(videos);

    if (edukasiCount < targetEach) {
      final needed = targetEach - edukasiCount;
      final additionalEdukasi = allVideos
          .where((v) => v.category == 'Edukasi doa')
          .where((v) => !videos.contains(v))
          .take(needed)
          .toList();
      balancedVideos.addAll(additionalEdukasi);
    }

    if (ceritaCount < targetEach) {
      final needed = targetEach - ceritaCount;
      final additionalCerita = allVideos
          .where((v) => v.category == 'Cerita Islam')
          .where((v) => !videos.contains(v))
          .take(needed)
          .toList();
      balancedVideos.addAll(additionalCerita);
    }

    return balancedVideos.take(totalTarget).toList();
  }

  // Method untuk mendapatkan semua video berdasarkan kategori perkembangan
  List<VideoModel> getVideosByDevelopmentCategory(String kategori) {
    return videoDatabase[kategori] ?? [];
  }

  // Method untuk mencari video berdasarkan judul
  List<VideoModel> searchVideos(String query, String kategori) {
    final allVideos = videoDatabase[kategori] ?? [];
    return allVideos
        .where((video) =>
    video.title.toLowerCase().contains(query.toLowerCase()) ||
        video.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Method untuk mendapatkan video berdasarkan kategori spesifik
  List<VideoModel> getVideosByCategory(String developmentCategory, String videoCategory) {
    final allVideos = videoDatabase[developmentCategory] ?? [];
    return allVideos
        .where((video) => video.category == videoCategory)
        .toList();
  }

  // Method untuk mendapatkan video YouTube ID dari URL
  String? getYouTubeId(String url) {
    final regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
    );
    final match = regExp.firstMatch(url);
    return (match != null && match.group(7)!.length == 11) ? match.group(7) : null;
  }

  // Method untuk mendapatkan thumbnail URL dari YouTube ID
  String getYouTubeThumbnail(String youtubeId) {
    return 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
  }
}