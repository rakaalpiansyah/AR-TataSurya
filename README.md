# AR Tata Surya

AR Tata Surya adalah aplikasi Flutter untuk media pembelajaran Augmented Reality bertema sistem tata surya. Aplikasi ini menampilkan model 3D tata surya, pilihan planet interaktif, dan informasi edukatif singkat agar pengguna dapat memahami orbit, rotasi, jarak, diameter, serta karakter setiap objek langit.

Project ini dibuat sebagai tugas Ujian Akhir Semester mata kuliah Grafika Komputer / AR dengan fokus pada pengalaman belajar yang modern, rapi, dan mudah digunakan saat presentasi.

## Fitur Utama

- Tampilan 3D tata surya berbasis file GLB.
- Mode AR melalui `model_viewer_plus` untuk melihat model di ruang nyata.
- Navigasi planet horizontal yang mudah digunakan di perangkat mobile.
- Interaksi sentuh pada objek 3D untuk menampilkan informasi planet.
- Kartu informasi planet berisi tipe objek, jarak, diameter, periode rotasi, dan deskripsi.
- Home screen modern dengan ringkasan fitur dan daftar objek yang dipelajari.
- Tema gelap yang nyaman untuk presentasi dan visual model antariksa.

## Teknologi

- Flutter
- Dart
- Material 3
- `model_viewer_plus`
- Asset model 3D GLB

## Struktur Project

```text
lib/
  main.dart
  data/
    planet_data.dart
  models/
    planet.dart
  screens/
    home_screen.dart
    ar_viewer_screen.dart
  widgets/
    planet_info_card.dart
assets/
  models/
    solar-ar.glb
    solar-professional.glb
    solar-withname.glb
tools/
  build_ar_glb.js
  build_professional_glb.js
```

## Cara Menjalankan

Pastikan Flutter SDK sudah terpasang, lalu jalankan:

```bash
flutter pub get
flutter run
```

Untuk pengalaman AR terbaik, gunakan perangkat fisik Android yang mendukung ARCore atau perangkat iOS yang mendukung ARKit. Aplikasi juga dapat dijalankan di web untuk melihat model 3D, tetapi kemampuan AR bergantung pada browser dan perangkat.

## Cara Menggunakan

1. Buka aplikasi.
2. Tekan tombol **Mulai Eksplorasi AR**.
3. Pilih planet dari menu bawah atau sentuh langsung objek pada model 3D.
4. Baca informasi planet pada kartu yang muncul.
5. Tekan tombol ikon AR untuk membuka mode AR jika perangkat mendukung.

## Materi Yang Ditampilkan

Aplikasi memuat informasi edukatif untuk:

- Matahari
- Merkurius
- Venus
- Bumi
- Bulan
- Mars
- Jupiter
- Saturnus
- Uranus
- Neptunus

## Catatan Pengembangan

- File model utama yang digunakan viewer adalah `assets/models/solar-ar.glb`.
- Data planet berada di `lib/data/planet_data.dart`.
- UI home screen berada di `lib/screens/home_screen.dart`.
- UI AR viewer berada di `lib/screens/ar_viewer_screen.dart`.
- Komponen kartu informasi berada di `lib/widgets/planet_info_card.dart`.

## Tujuan Pembelajaran

Project ini menunjukkan penerapan grafika komputer dan Augmented Reality untuk visualisasi edukatif. Pengguna dapat melihat objek 3D, memahami posisi relatif planet, serta mempelajari fakta dasar tata surya melalui antarmuka yang interaktif.
