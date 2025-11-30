// services/video_service.dart
import '../models/child_model.dart';
import '../models/video_model.dart';

class VideoService {
  // Data video berdasarkan kategori perkembangan anak dengan YouTube links dari klien
  final Map<String, List<VideoModel>> videoDatabase = {
    // Kategori TINGGI
    'Tinggi': [
      VideoModel(
        id: 't1',
        title: 'Lagu Doa Harian Anak Kecil Terbaru 2024',
        category: 'Edukasi doa',
        url: 'https://youtu.be/pf89qr1rnrQ',
        duration: '4:30',
        description:
        'Kumpulan doa harian dengan irama yang mudah diikuti anak.',
      ),
      VideoModel(
        id: 't2',
        title: 'Kenapa Kita Harus Sholat?',
        category: 'Cerita Islam',
        url: 'https://youtu.be/wY3hX4R7rF0',
        duration: '6:30',
        description:
        'Penjelasan sederhana dan menyentuh tentang pentingnya sholat bagi anak.',
      ),
    ],

    // Kategori SEDANG
    'Sedang': [
      VideoModel(
        id: 's1',
        title: 'Kumpulan Doa dengan Lagu',
        category: 'Edukasi doa',
        url: 'https://youtu.be/6auN-MKWFqQ',
        duration: '5:00',
        description:
        'Doa harian dalam bentuk lagu ceria agar anak mudah menghafal.',
      ),
      VideoModel(
        id: 's2',
        title: 'Animasi Anak Islami - Hana Sakit',
        category: 'Cerita Islam',
        url: 'https://youtu.be/XkWfZokIRIE',
        duration: '7:30',
        description:
        'Kisah Hana yang sakit dan belajar tentang kesabaran serta doa.',
      ),
      VideoModel(
        id: 's3',
        title: 'Cerita Ubay - Kenapa Harus Sholat?',
        category: 'Cerita Islam',
        url: 'https://youtu.be/nhaTgntD5wU',
        duration: '8:00',
        description:
        'Cerita tentang Ubay yang belajar pentingnya sholat sejak kecil.',
      ),
      VideoModel(
        id: 's4',
        title: 'Tidur Lebih Cepat, Bangun Lebih Awal - Kisah Teladan Nabi',
        category: 'Cerita Islam',
        url: 'https://youtu.be/qaOlUjqq1pk',
        duration: '7:00',
        description:
        'Kisah teladan Nabi tentang pentingnya menjaga waktu tidur dan bangun.',
      ),
    ],

    // Kategori RENDAH
    'Rendah': [
      VideoModel(
        id: 'r1',
        title: 'Hafalan Surah Pendek untuk Bacaan Sholat Anak',
        category: 'Edukasi doa',
        url: 'https://youtu.be/ONswHTlUH-0',
        duration: '6:00',
        description:
        'Mengenalkan dan menghafal surat-surat pendek yang dipakai untuk sholat.',
      ),
      VideoModel(
        id: 'r2',
        title: 'Belajar Doa Sehari-hari',
        category: 'Edukasi doa',
        url: 'https://youtu.be/90vW_DpBLrI',
        duration: '5:30',
        description:
        'Doa-doa dasar sehari-hari yang diajarkan dengan cara menyenangkan.',
      ),
      VideoModel(
        id: 'r3',
        title: 'Cerita Ubay - Kenapa Harus Sholat?',
        category: 'Cerita Islam',
        url: 'https://youtu.be/nhaTgntD5wU',
        duration: '8:00',
        description:
        'Cerita tentang Ubay yang belajar pentingnya sholat sejak kecil.',
      ),
      VideoModel(
        id: 'r4',
        title: 'Animasi Anak Islami - Hana Sakit',
        category: 'Cerita Islam',
        url: 'https://youtu.be/XkWfZokIRIE',
        duration: '7:30',
        description:
        'Kisah Hana yang sakit dan belajar tentang kesabaran serta doa.',
      ),
      VideoModel(
        id: 's5',
        title: 'Tidur Lebih Cepat, Bangun Lebih Awal - Kisah Teladan Nabi',
        category: 'Cerita Islam',
        url: 'https://youtu.be/qaOlUjqq1pk',
        duration: '7:00',
        description:
        'Kisah teladan Nabi tentang pentingnya menjaga waktu tidur dan bangun.',
      ),
      VideoModel(
        id: 's6',
        title: 'Kumpulan Doa dengan Lagu',
        category: 'Edukasi doa',
        url: 'https://youtu.be/6auN-MKWFqQ',
        duration: '5:00',
        description:
        'Doa harian dalam bentuk lagu ceria agar anak mudah menghafal.',
      ),
    ],
  };

  /// Rekomendasi video berdasarkan kategori perkembangan anak.
  /// Sekarang **langsung ambil semua video** dari kategori tersebut.
  List<VideoModel> getVideoRecommendations(ChildModel child) {
    return videoDatabase[child.kategori] ?? [];
  }

  // Kalau masih mau dipakai di tempat lain:
  List<VideoModel> getVideosByDevelopmentCategory(String kategori) {
    return videoDatabase[kategori] ?? [];
  }

  List<VideoModel> searchVideos(String query, String kategori) {
    final allVideos = videoDatabase[kategori] ?? [];
    return allVideos
        .where((video) =>
    video.title.toLowerCase().contains(query.toLowerCase()) ||
        video.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<VideoModel> getVideosByCategory(
      String developmentCategory, String videoCategory) {
    final allVideos = videoDatabase[developmentCategory] ?? [];
    return allVideos.where((video) => video.category == videoCategory).toList();
  }
}
