# AR-TataSurya

AR-TataSurya adalah aplikasi Flutter yang menampilkan pengalaman Augmented Reality (AR) untuk eksplorasi tata surya. Aplikasi ini menggabungkan model 3D planet, data edukatif, dan antarmuka interaktif untuk memberikan pengalaman belajar yang imersif pada perangkat mobile dan web.

## Fitur Utama

- Tampilan AR real-time yang menempatkan model planet di lingkungan pengguna.
- Koleksi model 3D planet yang dioptimalkan untuk performa mobile.
- Informasi edukatif untuk setiap planet (massa, jari‑jari, jarak dari Matahari, dan deskripsi singkat).
- Kontrol interaktif untuk memilih planet, memperbesar, dan melihat detail.
- Dukungan multi-platform: Android, iOS, web (tergantung paket dan plugin AR yang digunakan).

## Tujuan Proyek

Memberikan alat pembelajaran visual yang mudah diakses untuk siswa dan penggemar astronomi, sekaligus menjadi contoh implementasi AR dengan Flutter dan integrasi aset 3D.

## Struktur Proyek (ringkas)

- `lib/` – Kode sumber Flutter, termasuk layar, widget, dan model data.
- `assets/` – Aset statis seperti model 3D, tekstur, dan gambar.
- `models/` – Model 3D atau file pendukung yang digunakan di AR viewer.
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` – Konfigurasi platform spesifik.

## Prasyarat

- Flutter SDK (sesuaikan versi dengan `pubspec.yaml`).
- Untuk pengembangan AR di Android/iOS, pasang plugin AR yang sesuai (contoh: `ar_flutter_plugin` atau plugin ARCore/ARKit), serta emulator atau perangkat fisik yang mendukung AR.

## Instalasi & Menjalankan

1. Clone repositori ini.
2. Pastikan Flutter terpasang dan path sudah dikonfigurasi.
3. Ambil dependensi:

```bash
flutter pub get
```

4. Jalankan aplikasi pada perangkat yang mendukung AR atau emulator:

```bash
flutter run
```

Catatan: Untuk pengalaman AR penuh, gunakan perangkat fisik yang mendukung ARCore (Android) atau ARKit (iOS). Untuk web, beberapa fitur AR mungkin terbatas tergantung pada plugin yang digunakan.

## Penggunaan Aset & Model

- Letakkan model 3D dan tekstur yang diperlukan di folder `assets/` dan daftarkan di `pubspec.yaml`.
- Pastikan model dioptimalkan (polycount rendah, tekstur terkompresi) agar kinerja tetap baik di perangkat mobile.

## Kontribusi

Kontribusi diterima — silakan buat issue atau pull request. Jelaskan perubahan yang diusulkan dan sertakan screenshot atau rekaman singkat jika relevan.

## Lisensi

Lisensi belum ditentukan di repositori ini. Jika Anda ingin menambahkan lisensi, tambahkan file `LICENSE` dan perbarui README.

## Kontak

Jika butuh bantuan atau ingin berdiskusi lebih jauh tentang pengembangan fitur AR, hubungi pemilik proyek atau buka issue di repositori.

---

_Dokumentasi ini dibuat otomatis oleh asisten pengembangan untuk memberikan ringkasan profesional proyek._
