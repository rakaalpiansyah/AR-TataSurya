# AR Tata Surya

AR Tata Surya adalah aplikasi Flutter untuk media pembelajaran astronomi interaktif. Aplikasi ini menampilkan model 3D tata surya, pilihan planet, informasi edukatif, animasi orbit, dan mode Augmented Reality bawaan perangkat melalui viewer 3D.

## Tema Project

Tema yang digunakan adalah **edukasi tata surya berbasis Augmented Reality**.

Tema ini dipilih karena tata surya merupakan materi yang sangat visual. Objek seperti Matahari, planet, Bulan, orbit, rotasi, dan karakter tiap planet lebih mudah dipahami apabila ditampilkan melalui model 3D interaktif dibanding hanya menggunakan teks atau gambar statis.

## Metode AR Yang Digunakan

Metode AR yang digunakan adalah **markerless Augmented Reality berbasis model viewer**.

Markerless AR adalah metode AR yang tidak membutuhkan marker fisik seperti QR code, gambar target, atau pola cetak. Pada project ini, pengguna dapat melihat model 3D terlebih dahulu di aplikasi, lalu membuka mode AR perangkat melalui tombol AR putih bawaan dari `model_viewer_plus`.

Pendekatan ini dipilih karena lebih stabil untuk perangkat Android modern, tidak membutuhkan dependency native AR tambahan, dan tetap memungkinkan model tata surya ditampilkan di ruang nyata apabila perangkat mendukung AR.

Model utama yang digunakan:

```text
assets/models/solar-ar.glb
```

## Penjelasan Metode

Alur metode pada aplikasi:

1. Aplikasi menampilkan halaman awal melalui `HomeScreen`.
2. Pengguna menekan tombol **Mulai Eksplorasi AR**.
3. Aplikasi membuka `ArViewerScreen` yang menampilkan model 3D tata surya.
4. Pengguna dapat memilih planet melalui menu bawah atau menyentuh objek pada model 3D.
5. Aplikasi membaca nama mesh atau material objek yang disentuh.
6. Data tersebut dicocokkan dengan daftar planet di `planet_data.dart`.
7. Informasi planet ditampilkan melalui card edukatif di atas viewer.
8. Pengguna dapat menekan tombol AR putih di kanan bawah viewer untuk membuka mode AR perangkat.

Interaksi penjelasan planet berada pada layer aplikasi Flutter, bukan ditanam langsung di dalam file model 3D. Dengan cara ini, informasi planet lebih mudah diperbarui, tampilan UI tetap rapi, dan model GLB tetap fokus sebagai aset visual.

## Alasan Menggunakan Metode Ini

Metode markerless berbasis model viewer digunakan karena:

- **Tidak membutuhkan marker fisik.** Pengguna dapat langsung membuka aplikasi tanpa mencetak marker.
- **Lebih stabil untuk demo UAS.** Aplikasi tidak bergantung pada plugin native AR tambahan yang berisiko tidak kompatibel dengan perangkat tertentu.
- **Mendukung eksplorasi 3D.** Model dapat diputar, diperbesar, dan dipilih sebelum masuk ke mode AR.
- **Tetap menyediakan mode AR.** Tombol AR bawaan viewer dapat membuka pengalaman AR perangkat jika tersedia.
- **Mudah dipahami pengguna.** Alur penggunaan sederhana: buka aplikasi, pilih planet, baca informasi, lalu aktifkan AR.
- **Cocok untuk edukasi visual.** Orbit, rotasi, dan bentuk planet dapat diamati secara langsung melalui model 3D.

## Fitur Utama

- Home screen modern dan rapi.
- Model 3D tata surya berbasis file GLB.
- Animasi rotasi dan orbit tata surya.
- Menu planet horizontal yang ringkas.
- Interaksi sentuh objek 3D untuk menampilkan informasi planet.
- Card informasi berisi tipe objek, jarak, diameter, rotasi, dan deskripsi.
- Mode AR markerless melalui tombol AR bawaan `model_viewer_plus`.
- Tombol bantuan untuk menjelaskan fungsi mode AR.

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

## Cara Menjalankan

```bash
flutter pub get
flutter run
```

Gunakan perangkat fisik Android untuk mencoba tombol AR. Mode AR bergantung pada dukungan AR perangkat dan layanan Google Play Services for AR.

## Cara Menggunakan

1. Buka aplikasi.
2. Tekan **Mulai Eksplorasi AR**.
3. Pilih planet dari menu bawah atau sentuh objek pada model 3D.
4. Baca informasi planet pada card.
5. Tekan tombol AR putih di kanan bawah viewer untuk membuka mode AR perangkat.
6. Gunakan tombol bantuan di kanan atas jika ingin melihat keterangan fungsi mode AR.

## Materi Yang Ditampilkan

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

## Batasan Project

- Mode AR hanya aktif jika perangkat mendukung AR.
- Beberapa perangkat dapat membuka viewer 3D tetapi tidak membuka mode AR.
- Card informasi Flutter tidak ikut tampil di layar AR bawaan perangkat karena mode AR ditangani oleh viewer/platform.
- Skala planet dan jarak orbit disesuaikan agar semua objek mudah dilihat dalam satu model.
- Interaksi klik objek bergantung pada nama mesh atau material di file GLB.

## Kesimpulan

Project AR Tata Surya menerapkan metode markerless AR berbasis model viewer untuk menghadirkan pembelajaran tata surya yang interaktif, stabil, dan mudah digunakan. Pendekatan ini cocok untuk kebutuhan Ujian Akhir Semester karena tetap menampilkan visual 3D yang menarik, informasi edukatif yang jelas, serta mode AR perangkat tanpa dependency native tambahan yang berisiko mengganggu kompatibilitas.
