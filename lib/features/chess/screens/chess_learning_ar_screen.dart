import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ChessLearningArScreen extends StatelessWidget {
  const ChessLearningArScreen({super.key});

  static const _lessons = [
    ('Sejarah', 'Catur berasal dari permainan India kuno Chaturanga, lalu berkembang ke Persia, dunia Islam, Eropa, hingga menjadi catur modern.'),
    ('Tujuan', 'Tujuan utama catur adalah membuat Raja lawan skakmat: Raja diserang dan tidak punya langkah aman untuk menyelamatkan diri.'),
    ('Susunan Awal', 'Setiap pemain punya 16 bidak: 8 pion, 2 benteng, 2 kuda, 2 gajah, 1 menteri, dan 1 raja. Ratu berada di warna sendiri.'),
    ('Cara Bermain', 'Pemain bergiliran. Putih selalu bergerak lebih dulu. Satu giliran digunakan untuk memindahkan satu bidak sesuai aturan geraknya.'),
    ('Pion', 'Maju satu petak. Dari posisi awal boleh maju dua petak. Menangkap diagonal. Jika sampai baris akhir, pion promosi.'),
    ('Benteng', 'Bergerak lurus horizontal atau vertikal sejauh petak masih kosong. Kuat untuk menguasai lajur dan baris terbuka.'),
    ('Kuda', 'Bergerak membentuk huruf L: dua petak lalu satu petak menyamping. Kuda dapat melompati bidak lain.'),
    ('Gajah', 'Bergerak diagonal sejauh petak masih kosong. Gajah selalu bertahan di warna petak yang sama sepanjang permainan.'),
    ('Menteri', 'Bidak terkuat. Bergerak seperti gabungan benteng dan gajah: lurus atau diagonal sejauh petak masih kosong.'),
    ('Raja', 'Bergerak satu petak ke semua arah. Raja tidak boleh masuk ke petak yang sedang diserang lawan.'),
    ('Skak', 'Skak terjadi saat Raja sedang diserang. Pemain wajib menyelamatkan Raja dengan pindah, menutup serangan, atau menangkap penyerang.'),
    ('Skakmat', 'Skakmat terjadi saat Raja terkena skak dan tidak ada langkah legal untuk keluar dari serangan. Pemain yang memberi skakmat menang.'),
    ('Rokade', 'Gerakan khusus Raja dan Benteng. Syarat: keduanya belum bergerak, jalur kosong, Raja tidak sedang skak, dan tidak melewati petak diserang.'),
    ('En Passant', 'Tangkap khusus pion. Jika pion lawan maju dua petak dan melewati area serang pion kita, pion itu bisa ditangkap pada giliran berikutnya.'),
    ('Promosi', 'Jika pion mencapai baris terakhir, pion dapat berubah menjadi Menteri, Benteng, Gajah, atau Kuda. Biasanya dipilih Menteri.'),
    ('Remis: Pat', 'Pat terjadi saat pemain tidak sedang skak, tetapi tidak punya langkah legal. Permainan berakhir seri/remis.'),
    ('Remis Lain', 'Remis bisa terjadi karena materi tidak cukup, pengulangan posisi tiga kali, aturan 50 langkah, atau kesepakatan kedua pemain.'),
    ('Contoh Animasi', 'Animasi AR menampilkan contoh skakmat cepat: e4, e5, Qh5, Nc6, Bc4, Nf6, lalu Qxf7#.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070706),
      appBar: AppBar(
        title: const Text('Mode Belajar AR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF11110F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const ModelViewer(
            src: 'assets/models/chess-learning.glb',
            ar: true,
            autoPlay: true,
            animationName: 'Skakmat putih',
            autoRotate: false,
            cameraControls: true,
            disableZoom: false,
            cameraOrbit: '0deg 28deg 7.8m',
            cameraTarget: '0m 0m 0m',
            exposure: 1.1,
            shadowIntensity: 1,
            shadowSoftness: 0.35,
            interactionPrompt: InteractionPrompt.none,
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xE6171711),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: .45)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belajar catur lewat AR',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Gunakan tombol AR untuk menaruh papan catur di meja. Animasi menunjukkan contoh skakmat putih yang rapi tanpa label 3D yang mengganggu ukuran papan.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Geser kartu materi di bawah untuk membaca sejarah, aturan bidak, skakmat, rokade, promosi, dan syarat remis.',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 92,
            child: SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _lessons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final lesson = _lessons[index];
                  return _LessonCard(title: lesson.$1, body: lesson.$2);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String title;
  final String body;

  const _LessonCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
    width: 246,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xEE171711),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.amberAccent, fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.22),
        ),
      ],
    ),
  );
}
