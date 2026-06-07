# AR Tata Surya

AR Tata Surya adalah aplikasi Flutter berbasis Augmented Reality untuk media pembelajaran sistem tata surya. Aplikasi ini menampilkan model 3D tata surya, kontrol pilihan planet, animasi orbit, dan informasi edukatif agar pengguna dapat memahami karakter objek langit secara visual dan interaktif.

Project ini dibuat sebagai penerapan Augmented Reality pada aplikasi mobile dengan pendekatan visualisasi 3D. Fokus utamanya adalah membantu pengguna melihat representasi tata surya secara lebih nyata dibandingkan hanya melalui gambar 2D atau teks.

## Tema Project

Tema yang digunakan adalah **edukasi tata surya berbasis Augmented Reality**.

Tema ini dipilih karena tata surya merupakan materi yang sangat visual. Objek seperti Matahari, planet, Bulan, orbit, rotasi, dan jarak antarplanet lebih mudah dipahami apabila ditampilkan dalam bentuk model 3D interaktif. Dengan AR, pengguna dapat melihat model tersebut di ruang nyata sehingga pengalaman belajar menjadi lebih menarik, imersif, dan mudah dipresentasikan.

Materi yang divisualisasikan meliputi:

- Matahari sebagai pusat tata surya.
- Planet-planet utama dalam tata surya.
- Bulan sebagai satelit alami Bumi.
- Orbit dan rotasi objek langit.
- Informasi dasar seperti tipe objek, jarak, diameter, periode rotasi, dan deskripsi singkat.

## Metode AR Yang Digunakan

Metode AR yang digunakan pada project ini adalah **markerless Augmented Reality berbasis 3D model viewer**.

Markerless AR adalah metode Augmented Reality yang tidak membutuhkan marker khusus seperti QR code, gambar target, atau pola cetak tertentu. Objek 3D dapat ditampilkan langsung pada lingkungan nyata melalui kamera perangkat, selama perangkat dan browser/platform mendukung kemampuan AR.

Pada project ini, implementasi dilakukan menggunakan package `model_viewer_plus` di Flutter. Package ini memanfaatkan komponen `<model-viewer>` untuk menampilkan model 3D berformat GLB dan menyediakan akses ke mode AR pada perangkat yang mendukung.

Model 3D utama yang digunakan adalah:

```text
assets/models/solar-ar.glb
```

Model tersebut berisi representasi tata surya yang dapat dilihat, diputar, diperbesar, serta digunakan pada mode AR.

## Penjelasan Metode

Alur metode AR pada aplikasi ini adalah sebagai berikut:

1. Aplikasi Flutter menampilkan antarmuka utama melalui `HomeScreen`.
2. Pengguna menekan tombol **Mulai Eksplorasi AR**.
3. Aplikasi membuka `ArViewerScreen` yang memuat komponen `ModelViewer`.
4. `ModelViewer` membaca file GLB dari folder `assets/models/`.
5. Model tata surya ditampilkan dalam bentuk 3D dengan kontrol kamera.
6. Pengguna dapat memilih planet melalui menu bawah atau menyentuh objek 3D.
7. Aplikasi menampilkan informasi edukatif sesuai objek yang dipilih.
8. Jika perangkat mendukung, pengguna dapat menekan tombol AR untuk menempatkan model 3D ke lingkungan nyata.

Interaksi objek dilakukan dengan JavaScript yang dikirim ke komponen `model-viewer`. Ketika objek pada model disentuh, aplikasi mencoba membaca nama mesh atau material, lalu mencocokkannya dengan data planet yang tersedia di Flutter. Setelah planet dikenali, kamera diarahkan ke objek tersebut dan kartu informasi ditampilkan.

## Alasan Menggunakan Metode Ini

Metode markerless AR berbasis model 3D dipilih karena beberapa alasan:

- **Tidak membutuhkan marker fisik.** Pengguna tidak perlu mencetak gambar target atau menyiapkan alat tambahan.
- **Lebih praktis untuk demonstrasi.** Model dapat langsung dibuka dari aplikasi dan digunakan pada perangkat mobile.
- **Cocok untuk visualisasi tata surya.** Tata surya lebih efektif ditampilkan sebagai objek 3D yang dapat diamati dari berbagai sudut.
- **Interaktif.** Pengguna dapat memilih planet, menggerakkan kamera, memperbesar model, dan membaca informasi objek.
- **Mendukung pembelajaran visual.** Pengguna dapat memahami konsep orbit, rotasi, dan perbandingan objek dengan lebih mudah.
- **Integrasi Flutter lebih sederhana.** `model_viewer_plus` memungkinkan model GLB ditampilkan dan diaktifkan dalam mode AR tanpa membangun engine AR dari awal.

Dengan metode ini, aplikasi tetap ringan, mudah dijalankan, dan tetap memenuhi konsep utama Augmented Reality yaitu menggabungkan objek virtual 3D dengan lingkungan nyata.

## Fitur Utama

- Tampilan 3D tata surya berbasis file GLB.
- Mode AR melalui `model_viewer_plus`.
- Animasi rotasi dan orbit tata surya.
- Navigasi planet horizontal yang mudah digunakan di perangkat mobile.
- Interaksi sentuh pada objek 3D untuk menampilkan informasi planet.
- Kartu informasi planet berisi tipe objek, jarak, diameter, periode rotasi, dan deskripsi.
- Home screen modern dengan ringkasan fitur.
- Tema gelap yang nyaman untuk visual model antariksa.

## Teknologi

- Flutter
- Dart
- Material 3
- `model_viewer_plus`
- JavaScript channel untuk interaksi objek 3D
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

## Penjelasan File Penting

- `lib/main.dart` mengatur entry point aplikasi dan tema global.
- `lib/screens/home_screen.dart` menampilkan halaman awal aplikasi.
- `lib/screens/ar_viewer_screen.dart` menampilkan model 3D, kontrol AR, pemilihan planet, dan logika interaksi objek.
- `lib/widgets/planet_info_card.dart` menampilkan informasi detail planet.
- `lib/data/planet_data.dart` menyimpan data edukatif setiap objek langit.
- `assets/models/solar-ar.glb` adalah model utama yang digunakan pada AR viewer.

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

## Kelebihan Project

- Antarmuka dibuat sederhana dan mudah digunakan.
- Pengguna dapat belajar melalui visual 3D, bukan hanya teks.
- Aplikasi mendukung eksplorasi model dari berbagai sudut.
- Materi disusun ringkas sehingga cocok untuk pembelajaran interaktif.
- Model dapat digunakan dalam mode AR pada perangkat yang mendukung.

## Batasan Project

- Mode AR bergantung pada dukungan perangkat dan platform.
- Skala planet dan jarak orbit pada model tidak sepenuhnya mengikuti skala astronomi asli, karena disesuaikan agar mudah dilihat dalam satu tampilan.
- Interaksi klik objek bergantung pada nama mesh atau material di file GLB.

## Kesimpulan

Project AR Tata Surya menerapkan metode markerless Augmented Reality untuk menampilkan model 3D tata surya secara interaktif. Metode ini dipilih karena praktis, tidak membutuhkan marker fisik, dan sesuai untuk materi pembelajaran visual. Dengan bantuan Flutter dan `model_viewer_plus`, aplikasi mampu menampilkan model 3D, menyediakan interaksi planet, serta menghadirkan pengalaman belajar yang lebih menarik melalui AR.
