# Bugfix Requirements Document

## Introduction

Dokumen ini mencakup semua bug yang ditemukan dalam proyek Flutter AR Tata Surya (`ar_tatasurya_project`). Aplikasi ini menampilkan model 3D tata surya menggunakan `model_viewer_plus` dengan fitur AR, navigasi planet, dan mode statis/animasi. Investigasi kode menemukan **7 bug** yang tersebar di file `ar_viewer_screen.dart`, `planet_data.dart`, dan `pubspec.yaml`, mencakup: API yang tidak valid, logika deteksi planet yang rapuh, nilai kamera yang ambigu, race condition pada kontrol animasi, dan konfigurasi asset yang tidak lengkap.

---

## Bug Analysis

### Current Behavior (Defect)

**Bug 1 — `materialFromPoint` bukan API resmi `model-viewer`**

1.1 WHEN pengguna mengetuk/mengklik objek planet pada model 3D THEN sistem memanggil `viewer.materialFromPoint(event.clientX, event.clientY)` yang tidak terdefinisi dalam API resmi `model-viewer`, sehingga selalu mengembalikan `undefined` dan fitur klik-untuk-fokus-planet tidak pernah berfungsi.

**Bug 2 — Deteksi material Matahari menggunakan string `'material'` yang terlalu umum**

1.2 WHEN nama material dari model 3D mengandung substring `'material'` (misalnya `"defaultMaterial"`, `"material_0"`, atau material planet lain yang mengandung kata tersebut) THEN sistem salah mengidentifikasi objek tersebut sebagai Matahari (index 1), menyebabkan kamera berpindah ke Matahari secara tidak sengaja.

**Bug 3 — `cameraOrbit` Neptunus menggunakan nilai `360deg` yang identik dengan `0deg`**

1.3 WHEN pengguna memilih planet Neptunus dari daftar planet THEN sistem mengarahkan kamera ke posisi `360deg 75deg 1.2m` yang secara trigonometri identik dengan posisi `0deg` (overview Sistem Tata Surya), sehingga kamera Neptunus tampak berada di posisi yang sama dengan posisi awal overview, bukan di posisi yang berbeda dan dapat dibedakan.

**Bug 4 — Race condition pada `_toggleStaticMode`: `window._pt` tidak selalu di-clear di semua branch**

1.4 WHEN pengguna menekan tombol toggle mode statis secara cepat berulang kali THEN sistem tidak selalu membatalkan (`clearTimeout`) timer `window._pt` yang sedang berjalan sebelum membuat timer baru, sehingga perintah `pause()` atau `play()` yang tertunda dari siklus sebelumnya dapat dieksekusi setelah state sudah berubah, menyebabkan animasi terjebak dalam state yang salah (misalnya tetap pause padahal mode statis sudah dimatikan).

**Bug 5 — `_focusPlanet(index != 0)` tidak membersihkan timer sebelum memanggil `play()` saat kembali ke overview**

1.5 WHEN pengguna menekan tombol close pada `PlanetInfoCard` untuk kembali ke overview THEN sistem memanggil `_focusPlanet(0)` yang menjalankan `v.play()` tanpa memastikan timer `window._pt` dari operasi `pause()` sebelumnya sudah dibatalkan terlebih dahulu, sehingga `pause()` yang tertunda dapat mengeksekusi setelah `play()` dipanggil dan menghentikan animasi secara tidak terduga.

**Bug 6 — `pubspec.yaml` hanya mendaftarkan `assets/models/` tanpa subfolder rekursif**

1.6 WHEN aplikasi Flutter di-build dan mencoba mengakses file di subfolder `assets/models/solar-system/textures/` THEN sistem gagal menemukan file tersebut karena Flutter tidak secara otomatis menyertakan subfolder — hanya file langsung di `assets/models/` yang terdaftar, sehingga texture dan asset di subfolder tidak dapat diakses.

**Bug 7 — `_buildPlanetList` melewati index 0 dengan `SizedBox.shrink()` tanpa padding kiri untuk item pertama yang terlihat**

1.7 WHEN daftar planet ditampilkan dalam mode overview THEN item pertama yang terlihat (Matahari, index 1) tidak memiliki padding kiri yang konsisten karena `SizedBox.shrink()` untuk index 0 tidak menghasilkan spasi, sehingga tombol Matahari muncul terlalu dekat ke tepi kiri layar dibandingkan dengan padding yang didefinisikan.

---

### Expected Behavior (Correct)

**Bug 1 — Klik planet menggunakan API yang valid**

2.1 WHEN pengguna mengetuk/mengklik objek planet pada model 3D THEN sistem SHALL menggunakan API `model-viewer` yang valid (seperti `queryHitTest` atau event `select` bawaan `model-viewer`) untuk mendeteksi objek yang diklik, sehingga fitur klik-untuk-fokus-planet berfungsi dengan benar.

**Bug 2 — Deteksi material Matahari menggunakan string yang spesifik**

2.2 WHEN nama material dari model 3D diperiksa untuk identifikasi Matahari THEN sistem SHALL menggunakan string yang lebih spesifik dan unik (misalnya `'sun'`, `'solar'`, atau nama material yang tepat sesuai file GLB) sebagai kondisi pencocokan, bukan string generik `'material'` yang dapat cocok dengan material apa pun.

**Bug 3 — `cameraOrbit` Neptunus menggunakan nilai yang unik dan berbeda**

2.3 WHEN pengguna memilih planet Neptunus THEN sistem SHALL mengarahkan kamera ke posisi yang secara visual berbeda dari posisi overview, menggunakan nilai `cameraOrbit` yang tidak identik dengan `0deg` (misalnya `350deg` atau nilai lain yang tidak bertabrakan dengan posisi planet lain).

**Bug 4 — `_toggleStaticMode` selalu membatalkan timer sebelumnya**

2.4 WHEN pengguna menekan tombol toggle mode statis THEN sistem SHALL selalu menjalankan `clearTimeout(window._pt)` di awal setiap branch JavaScript sebelum membuat timer baru atau memanggil `play()`/`pause()`, sehingga tidak ada perintah animasi yang tertunda dari siklus sebelumnya yang dapat menginterferensi state saat ini.

**Bug 5 — `_focusPlanet(0)` membatalkan semua timer sebelum memanggil `play()`**

2.5 WHEN pengguna kembali ke overview melalui tombol close THEN sistem SHALL memastikan semua timer `window._pt` yang tertunda dibatalkan sebelum memanggil `v.play()`, sehingga animasi overview berjalan tanpa gangguan dari operasi `pause()` yang tertunda.

**Bug 6 — `pubspec.yaml` mendaftarkan semua subfolder asset yang diperlukan**

2.6 WHEN aplikasi Flutter di-build THEN sistem SHALL berhasil menemukan dan menyertakan semua file asset yang diperlukan, termasuk file di subfolder `assets/models/solar-system/` dan `assets/models/solar-system/textures/`, dengan mendaftarkan setiap subfolder secara eksplisit di `pubspec.yaml`.

**Bug 7 — Item pertama daftar planet memiliki padding kiri yang konsisten**

2.7 WHEN daftar planet ditampilkan dalam mode overview THEN sistem SHALL menampilkan tombol Matahari (item pertama yang terlihat) dengan padding kiri yang konsisten sesuai desain, baik dengan menghapus `SizedBox.shrink()` dan menggunakan logika skip yang berbeda, atau dengan menambahkan padding eksplisit pada item pertama yang terlihat.

---

### Unchanged Behavior (Regression Prevention)

3.1 WHEN pengguna memilih planet selain Neptunus dari daftar (Matahari, Merkurius, Venus, Bumi, Bulan, Mars, Jupiter, Saturnus, Uranus) THEN sistem SHALL CONTINUE TO mengarahkan kamera ke posisi `cameraOrbit` dan `cameraTarget` yang sudah terdefinisi untuk masing-masing planet tanpa perubahan.

3.2 WHEN pengguna berada di mode overview (`selectedIndex == 0`) dan animasi sedang berjalan THEN sistem SHALL CONTINUE TO menampilkan daftar planet horizontal di bagian bawah layar.

3.3 WHEN pengguna memilih sebuah planet dari daftar THEN sistem SHALL CONTINUE TO menampilkan `PlanetInfoCard` dengan nama, jarak, dan deskripsi planet yang benar.

3.4 WHEN pengguna menekan tombol close pada `PlanetInfoCard` THEN sistem SHALL CONTINUE TO kembali ke tampilan overview dengan `selectedIndex = 0` dan menampilkan daftar planet.

3.5 WHEN pengguna menekan tombol toggle mode statis satu kali THEN sistem SHALL CONTINUE TO mengubah ikon tombol antara `play_arrow_rounded` dan `pause_rounded` sesuai state `isStaticMode`.

3.6 WHEN aplikasi pertama kali dibuka THEN sistem SHALL CONTINUE TO memuat model 3D `solar_system_animation.glb` dari path `assets/models/solar_system_animation.glb` dan menampilkan animasi tata surya secara otomatis.

3.7 WHEN pengguna memilih planet tertentu (bukan overview) THEN sistem SHALL CONTINUE TO menghentikan animasi dan mengarahkan kamera ke planet tersebut menggunakan JavaScript melalui `_webViewController`.

3.8 WHEN `_webViewController` bernilai `null` (WebView belum siap) THEN sistem SHALL CONTINUE TO tidak memanggil JavaScript dan hanya memperbarui state UI melalui `setState`.

---

## Bug Condition Pseudocode

### Bug 1 — API `materialFromPoint` Tidak Valid

```pascal
FUNCTION isBugCondition_Bug1(X)
  INPUT: X adalah panggilan JavaScript pada model-viewer
  OUTPUT: boolean
  
  RETURN X menggunakan viewer.materialFromPoint() sebagai metode deteksi klik
END FUNCTION

// Property: Fix Checking
FOR ALL X WHERE isBugCondition_Bug1(X) DO
  result ← handlePlanetClick'(X)
  ASSERT result menggunakan API model-viewer yang valid DAN fitur klik berfungsi
END FOR

// Property: Preservation Checking
FOR ALL X WHERE NOT isBugCondition_Bug1(X) DO
  ASSERT F(X) = F'(X)  // Navigasi via tombol daftar tetap tidak berubah
END FOR
```

### Bug 2 — Deteksi Material Matahari Rapuh

```pascal
FUNCTION isBugCondition_Bug2(X)
  INPUT: X adalah string nama material dari model 3D
  OUTPUT: boolean
  
  RETURN X.contains('material') DAN X bukan nama material Matahari yang sebenarnya
END FUNCTION

// Property: Fix Checking
FOR ALL X WHERE isBugCondition_Bug2(X) DO
  result ← _getPlanetIndexFromMaterial'(X)
  ASSERT result = -1  // Material non-Matahari tidak salah diidentifikasi sebagai Matahari
END FOR
```

### Bug 3 — `cameraOrbit` Neptunus Ambigu

```pascal
FUNCTION isBugCondition_Bug3(X)
  INPUT: X adalah nilai cameraOrbit planet
  OUTPUT: boolean
  
  RETURN X.azimuth = 360deg  // 360deg identik dengan 0deg
END FUNCTION

// Property: Fix Checking
FOR ALL X WHERE isBugCondition_Bug3(X) DO
  result ← cameraPosition'(X)
  ASSERT result.azimuth ≠ 0deg DAN result berbeda dari posisi overview
END FOR
```

### Bug 4 & 5 — Race Condition Timer Animasi

```pascal
FUNCTION isBugCondition_RaceCondition(X)
  INPUT: X adalah urutan pemanggilan toggle/fokus yang cepat
  OUTPUT: boolean
  
  RETURN window._pt masih aktif KETIKA perintah animasi baru dieksekusi
END FUNCTION

// Property: Fix Checking
FOR ALL X WHERE isBugCondition_RaceCondition(X) DO
  result ← animationState'(X)
  ASSERT result.state = expectedState  // State animasi sesuai dengan perintah terakhir
END FOR
```
