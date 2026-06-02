import '../models/pc_part.dart';

final List<PcPart> pcPartList = [
  const PcPart(
    name: 'PC Futuristik',
    category: 'Sistem komputer',
    spec: 'Tower PC ringan untuk AR',
    function:
        'Model ini memperlihatkan tower PC futuristik yang sudah diberi nama part agar cocok untuk edukasi AR. Tekan Bongkar untuk melihat susunan casing, panel, papan utama, cooling, memori, grafis, power bay, dan rear I/O.',
    cameraOrbit: '35deg 63deg 13m',
    cameraTarget: '0m 0m 5m',
  ),
  const PcPart(
    name: 'Futuristic Case',
    category: 'Struktur utama',
    spec: 'Rangka tower dan cover luar',
    function:
        'Casing melindungi seluruh komponen internal, menjaga posisi part tetap rapi, dan membentuk jalur airflow dari bagian depan, samping, hingga belakang tower.',
    cameraOrbit: '36deg 62deg 9m',
    cameraTarget: '0m 0m 5m',
  ),
  const PcPart(
    name: 'Side Panel',
    category: 'Panel akses',
    spec: 'Panel samping dan ruang servis',
    function:
        'Panel samping memberi akses ke area internal PC untuk pemasangan, pengecekan, dan perawatan komponen. Pada mode bongkar, panel dipisahkan agar isi tower terlihat jelas.',
    cameraOrbit: '42deg 61deg 7.2m',
    cameraTarget: '-0.8m -1.2m 3.2m',
  ),
  const PcPart(
    name: 'Motherboard',
    category: 'Papan utama',
    spec: 'Pusat koneksi hardware',
    function:
        'Motherboard menghubungkan processor, memori, grafis, storage, port, dan sistem daya. Semua komunikasi data antar komponen utama melewati papan ini.',
    cameraOrbit: '35deg 58deg 6.4m',
    cameraTarget: '0.25m -0.8m 4.2m',
  ),
  const PcPart(
    name: 'Cooling System',
    category: 'Pendinginan',
    spec: 'Kipas dan blok pendingin',
    function:
        'Cooling system mengalirkan panas keluar dari komponen yang bekerja berat. Pendinginan yang baik menjaga performa tetap stabil saat gaming, rendering, atau komputasi panjang.',
    cameraOrbit: '30deg 58deg 5.8m',
    cameraTarget: '-0.3m 0.2m 5.8m',
  ),
  const PcPart(
    name: 'Memory Module',
    category: 'Memory',
    spec: 'Modul kerja sementara',
    function:
        'Memori menyimpan data sementara yang sedang dipakai aplikasi. Kapasitas dan kecepatan memori memengaruhi respons sistem saat multitasking dan menjalankan aplikasi berat.',
    cameraOrbit: '38deg 58deg 5.2m',
    cameraTarget: '-0.65m 0.55m 6.25m',
  ),
  const PcPart(
    name: 'Graphics Unit',
    category: 'Pemrosesan grafis',
    spec: 'Unit visual internal',
    function:
        'Graphics unit menangani tampilan 3D, video, rendering visual, dan beban komputasi paralel. Komponen ini penting untuk kualitas grafis dan performa visual.',
    cameraOrbit: '40deg 60deg 5.6m',
    cameraTarget: '0.8m -1.1m 3.45m',
  ),
  const PcPart(
    name: 'Power Bay',
    category: 'Daya',
    spec: 'Ruang distribusi power',
    function:
        'Power bay adalah area distribusi daya untuk komponen internal. Bagian ini membantu menjaga jalur power tetap terorganisir dan memisahkan panas dari komponen utama.',
    cameraOrbit: '38deg 62deg 6.2m',
    cameraTarget: '-0.2m -3.9m 4.2m',
  ),
  const PcPart(
    name: 'Rear I/O',
    category: 'Konektivitas',
    spec: 'Area port belakang',
    function:
        'Rear I/O menjadi area koneksi perangkat eksternal seperti monitor, keyboard, mouse, audio, jaringan, dan storage tambahan.',
    cameraOrbit: '42deg 60deg 5.8m',
    cameraTarget: '0.2m -1.2m 7.45m',
  ),
];
