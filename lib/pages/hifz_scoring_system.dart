import 'package:flutter/material.dart';

class HifzScoringSystem {
  // Rentang skor untuk setiap kategori HIFZ
  static final Map<String, Map<String, List<int>>> scoreRanges = {
    'ad_diin': {
      'Kesejahteraan Spiritual': [0, 3],
      'Risiko Distres Spiritual': [4, 7],
      'Distres Spiritual': [8, 16],
    },
    'an_nafs': {
      'Aman / risiko minimal': [0, 4],
      'Risiko sedang': [5, 8],
      'Risiko tinggi / perlu intervensi segera': [9, 22],
    },
    'al_aql': {
      'Perkembangan baik': [0, 3],
      'Risiko keterlambatan / stimulasi kurang': [4, 6],
      'Gangguan perkembangan, butuh evaluasi lanjutan': [7, 14],
    },
    'an_nasl': {
      'Pola asuh baik': [0, 4],
      'Risiko pola asuh tidak adekuat': [5, 8],
      'Pola asuh buruk / risiko perlakuan salah': [9, 26],
    },
    'al_mal': {
      'Kecukupan ekonomi baik': [0, 3],
      'Risiko ketidakcukupan ekonomi': [4, 6],
      'Ketidakcukupan berat / perlu rujukan sosial': [7, 12],
    },
  };

  // Video links berdasarkan kategori (LENGKAP untuk semua HIFZ)
  static final Map<String, Map<String, List<HifzVideo>>> videosByCategory = {
    'ad_diin': {
      'Kesejahteraan Spiritual': [
        HifzVideo(
          title: 'Panduan sholat saat sakit (ringan)',
          url: 'https://youtu.be/sDQrXd8JsM8?si=bOOkCpxhcScAQq83',
          category: 'Spiritual',
          description: 'Panduan melaksanakan sholat saat kondisi sakit ringan',
        ),
        HifzVideo(
          title: 'Dzikir anak',
          url: 'https://youtu.be/xRgbVLhDmf8?si=vOpl6IcqtZsN_22v',
          category: 'Spiritual',
          description: 'Kumpulan dzikir yang bisa diajarkan kepada anak',
        ),
      ],
      'Risiko Distres Spiritual': [
        HifzVideo(
          title: 'Cara tayamum yang benar',
          url: 'https://youtu.be/ooCwvFXsAxw?si=M3K9jJoaMbxrHbVR',
          category: 'Spiritual',
          description: 'Tutorial tayamum sebagai pengganti wudhu saat tidak ada air',
        ),
        HifzVideo(
          title: 'Sholat sambil duduk/tidur',
          url: 'https://youtu.be/H7ILGINAemA?si=puQWR_Fax6TwvotN',
          category: 'Spiritual',
          description: 'Tata cara sholat dalam kondisi duduk atau berbaring',
        ),
        HifzVideo(
          title: 'Cara mendampingi anak beribadah',
          url: 'https://youtu.be/zeyNPZ3Vyz4?si=YXUx4ib_NXVGCG8q',
          category: 'Spiritual',
          description: 'Panduan bagi orang tua mendampingi anak dalam beribadah',
        ),
      ],
      'Distres Spiritual': [
        HifzVideo(
          title: 'Makna sakit dalam Islam',
          url: 'https://youtube.com/shorts/bbAml_Husus?si=XcEXHymjFZzkIwS5',
          category: 'Spiritual',
          description: 'Penjelasan filosofi sakit menurut ajaran Islam',
        ),
        HifzVideo(
          title: 'Pentingnya doa dalam kesembuhan',
          url: 'https://youtu.be/X6y3ehdL8CI?si=mjnIqD-CpplknLp1',
          category: 'Spiritual',
          description: 'Peran doa dalam proses penyembuhan penyakit',
        ),
        HifzVideo(
          title: 'Pendampingan keluarga dalam ibadah',
          url: 'https://youtu.be/MROj3NBs7Xo?si=ImAfcdyuV-9Hqg-q',
          category: 'Spiritual',
          description: 'Cara keluarga mendukung spiritualitas anak yang sakit',
        ),
        HifzVideo(
          title: 'Kepercayaan pada takdir Allah',
          url: 'https://youtu.be/nhaTgntD5wU?si=L-lLh_dwf1VaNqdA',
          category: 'Spiritual',
          description: 'Memahami hikmah sakit sebagai bagian dari takdir',
        ),
      ],
    },
    'an_nafs': {
      'Aman / risiko minimal': [
        HifzVideo(
          title: 'Cara menjaga kesehatan anak secara umum',
          url: 'https://www.youtube.com/watch?v=tdXqmUxYhaE',
          category: 'Kesehatan',
          description: 'Tips menjaga kesehatan fisik anak sehari-hari',
        ),
        HifzVideo(
          title: 'Nutrisi dan hygiene untuk anak',
          url: 'https://www.youtube.com/watch?v=IQXHSBrMMN8',
          category: 'Kesehatan',
          description: 'Panduan nutrisi dan kebersihan untuk tumbuh kembang optimal',
        ),
      ],
      'Risiko sedang': [
        HifzVideo(
          title: 'Pencegahan cedera pada anak',
          url: 'https://www.youtube.com/shorts/bGpIhiciB8M',
          category: 'Keselamatan',
          description: 'Tips mencegah kecelakaan dan cedera pada anak',
        ),
        HifzVideo(
          title: 'Pencegahan kekerasan pada anak',
          url: 'https://www.youtube.com/shorts/mC8dd0_1odI',
          category: 'Keselamatan',
          description: 'Cara melindungi anak dari potensi kekerasan',
        ),
        HifzVideo(
          title: 'Cara memantau anak sakit',
          url: 'https://youtu.be/XkWfZokIRIE?si=MMnU5sWvsEfhrQVn',
          category: 'Kesehatan',
          description: 'Monitoring dan perawatan anak yang sedang sakit',
        ),
      ],
      'Risiko tinggi / perlu intervensi segera': [
        HifzVideo(
          title: 'Edukasi kekerasan & penelantaran',
          url: 'https://www.youtube.com/watch?v=YX2hHwArmJU',
          category: 'Keselamatan',
          description: 'Pengenalan tanda-tanda kekerasan dan penelantaran pada anak',
        ),
        HifzVideo(
          title: 'Keamanan rumah untuk anak',
          url: 'https://www.youtube.com/watch?v=juaHiZzvRug',
          category: 'Keselamatan',
          description: 'Tips mengamankan lingkungan rumah untuk anak',
        ),
        HifzVideo(
          title: 'Tanda darurat pada anak',
          url: 'https://www.youtube.com/watch?v=V_pZLB4jazE',
          category: 'Kesehatan',
          description: 'Tanda-tanda darurat yang perlu penanganan medis segera',
        ),
        HifzVideo(
          title: 'Pencegahan kecelakaan rumah tangga',
          url: 'https://www.youtube.com/watch?v=CqH2QYt6oOc',
          category: 'Keselamatan',
          description: 'Cara mencegah kecelakaan di lingkungan rumah',
        ),
        HifzVideo(
          title: 'Perlindungan anak dari bahaya',
          url: 'https://www.youtube.com/watch?v=P5D2C2wNKjs',
          category: 'Keselamatan',
          description: 'Strategi melindungi anak dari berbagai ancaman',
        ),
        HifzVideo(
          title: 'Penanganan keadaan darurat',
          url: 'https://www.youtube.com/watch?v=NiE6vRQQz7U',
          category: 'Kesehatan',
          description: 'Langkah-langkah penanganan pertama pada keadaan darurat',
        ),
      ],
    },
    'al_aql': {
      'Perkembangan baik': [
        HifzVideo(
          title: 'Stimulasi sesuai usia',
          url: 'https://www.youtube.com/watch?v=ct7Zs3_jjjs',
          category: 'Perkembangan',
          description: 'Teknik stimulasi yang sesuai dengan usia perkembangan anak',
        ),
        HifzVideo(
          title: 'Permainan edukatif untuk anak',
          url: 'https://www.youtube.com/watch?v=pon3cpLKlvM',
          category: 'Perkembangan',
          description: 'Ide permainan yang mendukung perkembangan kognitif anak',
        ),
      ],
      'Risiko keterlambatan / stimulasi kurang': [
        HifzVideo(
          title: 'Stimulasi otak anak',
          url: 'https://www.youtube.com/watch?v=CNjPo4FVb4A&list=RDCNjPo4FVb4A&start_radio=1',
          category: 'Perkembangan',
          description: 'Cara menstimulasi perkembangan otak anak secara optimal',
        ),
        HifzVideo(
          title: 'Manajemen screen time untuk anak',
          url: 'https://www.youtube.com/watch?v=NBO4eeCDsRo',
          category: 'Perkembangan',
          description: 'Mengatur penggunaan gadget agar tidak mengganggu perkembangan',
        ),
        HifzVideo(
          title: 'Cara bicara dengan anak',
          url: 'https://www.youtube.com/shorts/CWxmS2Lc0NY',
          category: 'Perkembangan',
          description: 'Teknik komunikasi yang efektif dengan anak',
        ),
      ],
      'Gangguan perkembangan, butuh evaluasi lanjutan': [
        HifzVideo(
          title: 'Deteksi dini keterlambatan perkembangan',
          url: 'https://www.youtube.com/watch?v=sbBN96dPu0o',
          category: 'Perkembangan',
          description: 'Tanda-tanda keterlambatan perkembangan yang perlu diperhatikan',
        ),
        HifzVideo(
          title: 'Kapan ke dokter tumbuh kembang',
          url: 'https://www.youtube.com/watch?v=8FuO_PbJc2g',
          category: 'Perkembangan',
          description: 'Indikasi untuk berkonsultasi dengan dokter spesialis tumbuh kembang',
        ),
        HifzVideo(
          title: 'Penyebab gangguan perkembangan',
          url: 'https://www.youtube.com/watch?v=Fx2TgLfPJZo',
          category: 'Perkembangan',
          description: 'Faktor-faktor yang dapat menyebabkan gangguan perkembangan',
        ),
        HifzVideo(
          title: 'Terapi untuk anak dengan gangguan perkembangan',
          url: 'https://www.youtube.com/watch?v=cz-DOmYApKk',
          category: 'Perkembangan',
          description: 'Jenis terapi yang dapat membantu anak dengan gangguan perkembangan',
        ),
      ],
    },
    'an_nasl': {
      'Pola asuh baik': [
        HifzVideo(
          title: 'Bonding ibu–bayi',
          url: 'https://www.youtube.com/watch?v=709FtCidEIk',
          category: 'Pola Asuh',
          description: 'Membangun ikatan emosional yang kuat antara ibu dan bayi',
        ),
        HifzVideo(
          title: 'Sentuhan kasih sayang',
          url: 'https://www.youtube.com/watch?v=WjOowWxOXCg',
          category: 'Pola Asuh',
          description: 'Pentingnya sentuhan fisik dalam pengasuhan anak',
        ),
        HifzVideo(
          title: 'Komunikasi efektif dengan anak',
          url: 'https://www.youtube.com/watch?v=Dt6hKGgnjeE',
          category: 'Pola Asuh',
          description: 'Cara berkomunikasi yang baik dengan anak',
        ),
      ],
      'Risiko pola asuh tidak adekuat': [
        HifzVideo(
          title: 'Pola asuh positif',
          url: 'https://www.youtube.com/watch?v=uae4f_8xyW0',
          category: 'Pola Asuh',
          description: 'Prinsip-prinsip pengasuhan yang positif dan efektif',
        ),
        HifzVideo(
          title: 'Cara merespons tantrum',
          url: 'https://www.youtube.com/watch?v=gxtVnU2hUmY',
          category: 'Pola Asuh',
          description: 'Strategi menghadapi tantrum pada anak',
        ),
        HifzVideo(
          title: 'Menjaga kebersihan reproduksi anak',
          url: 'https://www.youtube.com/watch?v=EqpEAEqLYL4',
          category: 'Kesehatan',
          description: 'Edukasi kebersihan organ reproduksi untuk anak',
        ),
        HifzVideo(
          title: 'Disiplin positif untuk anak',
          url: 'https://www.youtube.com/watch?v=BbXQkis2P4k',
          category: 'Pola Asuh',
          description: 'Menerapkan disiplin tanpa kekerasan',
        ),
      ],
      'Pola asuh buruk / risiko perlakuan salah': [
        HifzVideo(
          title: 'Edukasi pencegahan kekerasan pada anak',
          url: 'https://www.youtube.com/watch?v=YX2hHwArmJU',
          category: 'Keselamatan',
          description: 'Mencegah dan mengenali tanda-tanda kekerasan pada anak',
        ),
        HifzVideo(
          title: 'Hak anak yang harus dilindungi',
          url: 'https://www.youtube.com/watch?v=P5D2C2wNKjs',
          category: 'Hukum',
          description: 'Hak-hak dasar anak yang perlu diketahui dan dilindungi',
        ),
        HifzVideo(
          title: 'Keamanan tubuh anak',
          url: 'https://www.youtube.com/watch?v=NiE6vRQQz7U',
          category: 'Keselamatan',
          description: 'Mengajarkan anak tentang keamanan tubuh dan privasi',
        ),
        HifzVideo(
          title: 'Perlindungan anak dari pelecehan',
          url: 'https://www.youtube.com/watch?v=V_pZLB4jazE',
          category: 'Keselamatan',
          description: 'Strategi melindungi anak dari potensi pelecehan',
        ),
      ],
    },
    'al_mal': {
      'Kecukupan ekonomi baik': [
        HifzVideo(
          title: 'Manajemen keuangan keluarga sederhana',
          url: 'https://www.youtube.com/watch?v=004MJMykO-s',
          category: 'Ekonomi',
          description: 'Tips mengatur keuangan keluarga dengan bijak',
        ),
        HifzVideo(
          title: 'Perencanaan keuangan untuk keluarga',
          url: 'https://youtu.be/2dUlPnn6bGg?si=GXBztXuXxRnLiLl8',
          category: 'Ekonomi',
          description: 'Cara membuat perencanaan keuangan keluarga yang efektif',
        ),
      ],
      'Risiko ketidakcukupan ekonomi': [
        HifzVideo(
          title: 'Cara memilih nutrisi murah–bergizi',
          url: 'https://www.youtube.com/watch?v=VrO7hmlcPfk',
          category: 'Nutrisi',
          description: 'Tips memilih makanan bergizi dengan budget terbatas',
        ),
        HifzVideo(
          title: 'Bantuan kesehatan untuk keluarga',
          url: 'https://www.youtube.com/watch?v=MvStFpDvX9k',
          category: 'Kesehatan',
          description: 'Informasi tentang program bantuan kesehatan yang tersedia',
        ),
        HifzVideo(
          title: 'Pengelolaan anggaran rumah tangga',
          url: 'https://www.youtube.com/watch?v=D8jff-f71NE',
          category: 'Ekonomi',
          description: 'Cara mengatur pengeluaran rumah tangga dengan bijak',
        ),
      ],
      'Ketidakcukupan berat / perlu rujukan sosial': [
        HifzVideo(
          title: 'Program bantuan pemerintah untuk keluarga',
          url: 'https://www.youtube.com/watch?v=PDcKN0ht59w',
          category: 'Sosial',
          description: 'Informasi program bantuan sosial dari pemerintah',
        ),
        HifzVideo(
          title: 'Cara mengakses BPJS Kesehatan',
          url: 'https://www.youtube.com/watch?v=XwBX-VHX2Y8',
          category: 'Kesehatan',
          description: 'Panduan lengkap menggunakan BPJS Kesehatan',
        ),
        HifzVideo(
          title: 'Bantuan dari Dinas Sosial',
          url: 'https://www.youtube.com/watch?v=iaZkyzkNOGc',
          category: 'Sosial',
          description: 'Cara mendapatkan bantuan dari Dinas Sosial',
        ),
        HifzVideo(
          title: 'Peran posyandu dalam kesehatan keluarga',
          url: 'https://www.youtube.com/watch?v=84NYkRAJ3xE',
          category: 'Kesehatan',
          description: 'Manfaat dan layanan yang tersedia di posyandu',
        ),
      ],
    },
  };

  // Fungsi untuk mendapatkan kategori berdasarkan skor
  static String getCategory(String hifzKey, int score) {
    final ranges = scoreRanges[hifzKey];
    if (ranges == null) return 'Tidak Diketahui';

    for (final entry in ranges.entries) {
      final range = entry.value;
      if (score >= range[0] && score <= range[1]) {
        return entry.key;
      }
    }

    // Jika skor melebihi maksimum, ambil kategori terakhir
    final lastEntry = ranges.entries.last;
    return lastEntry.key;
  }

  // Fungsi untuk mendapatkan video berdasarkan kategori
  static List<HifzVideo> getVideos(String hifzKey, String category) {
    return videosByCategory[hifzKey]?[category] ?? [];
  }

  // Fungsi untuk menghitung skor dari jawaban
  static int calculateScore(List<Map<String, dynamic>> answers) {
    int totalScore = 0;

    for (final answerMap in answers) {
      final answerList = answerMap['answers'] as List<String>;
      for (final answer in answerList) {
        // Normalisasi jawaban
        final normalizedAnswer = answer.toLowerCase().trim();

        // Skoring berdasarkan sistem 0-2
        if (normalizedAnswer.contains('ya') ||
            normalizedAnswer.contains('yakin') ||
            normalizedAnswer.contains('mengerti') ||
            normalizedAnswer.contains('mampu') ||
            normalizedAnswer.contains('tidak ada masalah') ||
            normalizedAnswer.contains('tahu') ||
            normalizedAnswer.contains('tercukupi') ||
            normalizedAnswer.contains('mandiri') ||
            normalizedAnswer.contains('selalu') ||
            normalizedAnswer.contains('ketetapan dari allah') ||
            normalizedAnswer.contains('jalan allah') ||
            normalizedAnswer.contains('memahami') ||
            normalizedAnswer.contains('mengetahui') ||
            normalizedAnswer.contains('bisa') ||
            normalizedAnswer.contains('sering') ||
            normalizedAnswer.contains('pernah') ||
            normalizedAnswer.contains('baik') ||
            normalizedAnswer.contains('cukup') ||
            normalizedAnswer.contains('aman') ||
            normalizedAnswer.contains('rutin')) {
          totalScore += 0; // Kondisi baik
        } else if (normalizedAnswer.contains('kadang') ||
            normalizedAnswer.contains('ragu') ||
            normalizedAnswer.contains('butuh bantuan') ||
            normalizedAnswer.contains('perlu pendampingan') ||
            normalizedAnswer.contains('hambatan ringan') ||
            normalizedAnswer.contains('sebagian') ||
            normalizedAnswer.contains('pernah') ||
            normalizedAnswer.contains('kurang') ||
            normalizedAnswer.contains('sedikit') ||
            normalizedAnswer.contains('belum') ||
            normalizedAnswer.contains('jarang') ||
            normalizedAnswer.contains('tidak selalu') ||
            normalizedAnswer.contains('tidak yakin') ||
            normalizedAnswer.contains('tidak tahu')) {
          totalScore += 1; // Risiko
        } else if (normalizedAnswer.contains('tidak') ||
            normalizedAnswer.contains('tidak mengerti') ||
            normalizedAnswer.contains('tidak mampu') ||
            normalizedAnswer.contains('belum') ||
            normalizedAnswer.contains('masalah berat') ||
            normalizedAnswer.contains('kesulitan') ||
            normalizedAnswer.contains('tidak yakin') ||
            normalizedAnswer.contains('tidak tahu') ||
            normalizedAnswer.contains('sangat sulit') ||
            normalizedAnswer.contains('sering sakit') ||
            normalizedAnswer.contains('tidak pernah') ||
            normalizedAnswer.contains('tidak bisa') ||
            normalizedAnswer.contains('sulit') ||
            normalizedAnswer.contains('perlu bantuan') ||
            normalizedAnswer.contains('kekurangan') ||
            normalizedAnswer.contains('masalah')) {
          totalScore += 2; // Masalah signifikan
        } else {
          // Default untuk jawaban yang tidak dikenali
          totalScore += 1;
        }
      }
    }

    return totalScore;
  }

  // Fungsi untuk mendapatkan deskripsi kategori
  static String getCategoryDescription(String hifzKey, String category) {
    final descriptions = {
      'ad_diin': {
        'Kesejahteraan Spiritual': 'Kondisi spiritual anak dalam keadaan baik, keyakinan dan ibadah terjaga dengan baik.',
        'Risiko Distres Spiritual': 'Terdapat potensi gangguan spiritual yang perlu perhatian dan edukasi.',
        'Distres Spiritual': 'Kondisi spiritual memerlukan intervensi serius dan pendampingan intensif.',
      },
      'an_nafs': {
        'Aman / risiko minimal': 'Anak dalam kondisi aman dengan risiko minimal terhadap keselamatan jiwa.',
        'Risiko sedang': 'Terdapat beberapa faktor risiko yang perlu pemantauan dan pencegahan.',
        'Risiko tinggi / perlu intervensi segera': 'Kondisi berisiko tinggi yang memerlukan intervensi segera.',
      },
      'al_aql': {
        'Perkembangan baik': 'Perkembangan kognitif anak sesuai dengan usianya.',
        'Risiko keterlambatan / stimulasi kurang': 'Terdapat tanda-tanda risiko keterlambatan perkembangan.',
        'Gangguan perkembangan, butuh evaluasi lanjutan': 'Indikasi gangguan perkembangan yang perlu evaluasi profesional.',
      },
      'an_nasl': {
        'Pola asuh baik': 'Pola pengasuhan yang diterima anak sudah baik dan mendukung.',
        'Risiko pola asuh tidak adekuat': 'Terdapat aspek pola asuh yang perlu diperbaiki.',
        'Pola asuh buruk / risiko perlakuan salah': 'Kondisi pola asuh yang berisiko terhadap perkembangan anak.',
      },
      'al_mal': {
        'Kecukupan ekonomi baik': 'Kebutuhan ekonomi keluarga terpenuhi dengan baik.',
        'Risiko ketidakcukupan ekonomi': 'Terdapat risiko kesulitan ekonomi yang perlu diwaspadai.',
        'Ketidakcukupan berat / perlu rujukan sosial': 'Kondisi ekonomi memerlukan bantuan dan rujukan sosial.',
      },
    };

    return descriptions[hifzKey]?[category] ?? 'Tidak ada deskripsi tersedia.';
  }

  // Fungsi untuk mendapatkan warna berdasarkan kategori
  static Color getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('baik') ||
        lower.contains('aman') ||
        lower.contains('sejahteraan') ||
        lower.contains('kesejahteraan') ||
        lower.contains('tinggi')) {
      return Colors.green;
    } else if (lower.contains('risiko') ||
        lower.contains('sedang') ||
        lower.contains('kurang')) {
      return Colors.orange;
    } else if (lower.contains('distres') ||
        lower.contains('tinggi') ||
        lower.contains('gangguan') ||
        lower.contains('buruk') ||
        lower.contains('berat')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  // Fungsi untuk mendapatkan maksimum skor per Hifz
  static int getMaxScore(String hifzKey) {
    final maxScores = {
      'an_nafs': 22,  // 11 pertanyaan × 2
      'ad_diin': 16,  // 8 pertanyaan × 2
      'al_aql': 14,   // 7 pertanyaan × 2
      'an_nasl': 26,  // 13 pertanyaan × 2
      'al_mal': 12,   // 6 pertanyaan × 2
    };
    return maxScores[hifzKey] ?? 20;
  }
}

class HifzVideo {
  final String title;
  final String url;
  final String category;
  final String description;

  HifzVideo({
    required this.title,
    required this.url,
    required this.category,
    required this.description,
  });
}