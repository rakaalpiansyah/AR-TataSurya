import '../models/planet.dart';

final List<Planet> planetList = [
  Planet(
    name: "Sistem Tata Surya",
    type: "Sistem planet",
    diameter: "-",
    rotationPeriod: "-",
    distance: "-",
    description:
        "Tata Surya adalah sistem gravitasi yang berpusat pada Matahari, berisi delapan planet utama, satelit alami, asteroid, komet, dan debu antariksa. Model ini disusun sebagai visual edukatif agar perbandingan orbit, posisi, dan karakter planet mudah diamati dalam AR.",
    cameraOrbit: "0deg 30deg 56m",
    cameraTarget: "0m 0m 10m",
  ),
  Planet(
    name: "Matahari",
    type: "Bintang deret utama tipe G",
    diameter: "1.392.700 km",
    rotationPeriod: "Sekitar 25-35 hari",
    distance: "Pusat Tata Surya",
    description:
        "Matahari menyimpan lebih dari 99% massa Tata Surya dan menghasilkan energi melalui fusi hidrogen di intinya. Cahaya dan panasnya mengatur iklim, musim, serta kestabilan orbit planet-planet.",
    cameraOrbit: "28deg 64deg 4.2m",
    cameraTarget: "0m 0m 0m",
  ),
  Planet(
    name: "Merkurius",
    type: "Planet kebumian",
    diameter: "4.879 km",
    rotationPeriod: "58,6 hari Bumi",
    distance: "57,9 juta km dari Matahari",
    description:
        "Merkurius adalah planet terkecil sekaligus yang paling dekat dengan Matahari. Permukaannya berbatu dan penuh kawah, dengan perbedaan suhu ekstrem karena atmosfernya sangat tipis.",
    cameraOrbit: "20deg 64deg 2.3m",
    cameraTarget: "0m 0m 7.2m",
  ),
  Planet(
    name: "Venus",
    type: "Planet kebumian",
    diameter: "12.104 km",
    rotationPeriod: "243 hari Bumi, retrograde",
    distance: "108,2 juta km dari Matahari",
    description:
        "Venus memiliki atmosfer karbon dioksida yang sangat tebal sehingga efek rumah kaca membuatnya menjadi planet terpanas. Rotasinya berlawanan arah dibanding sebagian besar planet lain.",
    cameraOrbit: "35deg 64deg 2.6m",
    cameraTarget: "0m 0m 9.4m",
  ),
  Planet(
    name: "Bumi",
    type: "Planet kebumian",
    diameter: "12.742 km",
    rotationPeriod: "23 jam 56 menit",
    distance: "149,6 juta km dari Matahari",
    description:
        "Bumi adalah satu-satunya planet yang diketahui memiliki kehidupan. Lautan cair, atmosfer kaya nitrogen-oksigen, medan magnet, dan jarak ideal dari Matahari membuatnya stabil untuk ekosistem kompleks.",
    cameraOrbit: "55deg 64deg 2.7m",
    cameraTarget: "0m 0m 11.8m",
  ),
  Planet(
    name: "Bulan",
    type: "Satelit alami Bumi",
    diameter: "3.474 km",
    rotationPeriod: "27,3 hari Bumi",
    distance: "384.400 km dari Bumi",
    description:
        "Bulan adalah satelit alami Bumi yang terkunci pasang surut, sehingga sisi yang sama selalu menghadap Bumi. Gravitasinya membantu membentuk pasang surut laut dan menstabilkan kemiringan sumbu Bumi.",
    cameraOrbit: "70deg 62deg 1.6m",
    cameraTarget: "1.35m 0m 11.8m",
  ),
  Planet(
    name: "Mars",
    type: "Planet kebumian",
    diameter: "6.779 km",
    rotationPeriod: "24 jam 37 menit",
    distance: "227,9 juta km dari Matahari",
    description:
        "Mars dikenal sebagai Planet Merah karena permukaannya kaya besi oksida. Planet ini memiliki lembah raksasa, tudung es kutub, dan Olympus Mons, gunung berapi terbesar yang diketahui di Tata Surya.",
    cameraOrbit: "100deg 64deg 2.4m",
    cameraTarget: "0m 0m 14.4m",
  ),
  Planet(
    name: "Jupiter",
    type: "Raksasa gas",
    diameter: "139.820 km",
    rotationPeriod: "9 jam 56 menit",
    distance: "778,5 juta km dari Matahari",
    description:
        "Jupiter adalah planet terbesar dengan atmosfer hidrogen-helium yang dinamis. Bintik Merah Raksasa merupakan badai antiklonik berukuran sangat besar yang telah diamati selama berabad-abad.",
    cameraOrbit: "140deg 64deg 4.6m",
    cameraTarget: "0m 0m 18.6m",
  ),
  Planet(
    name: "Saturnus",
    type: "Raksasa gas bercincin",
    diameter: "116.460 km",
    rotationPeriod: "10 jam 42 menit",
    distance: "1,43 miliar km dari Matahari",
    description:
        "Saturnus memiliki sistem cincin paling mencolok, tersusun dari partikel es dan batuan. Kerapatannya rendah, tetapi sistem satelit dan cincinnya menjadikannya salah satu objek paling kompleks di Tata Surya.",
    cameraOrbit: "190deg 64deg 4.8m",
    cameraTarget: "0m 0m 22.6m",
  ),
  Planet(
    name: "Uranus",
    type: "Raksasa es",
    diameter: "50.724 km",
    rotationPeriod: "17 jam 14 menit, retrograde",
    distance: "2,87 miliar km dari Matahari",
    description:
        "Uranus adalah raksasa es dengan sumbu rotasi miring sekitar 98 derajat, membuatnya tampak berputar menyamping. Atmosfer metana memberi warna biru kehijauan yang khas.",
    cameraOrbit: "240deg 64deg 3.6m",
    cameraTarget: "0m 0m 26.2m",
  ),
  Planet(
    name: "Neptunus",
    type: "Raksasa es",
    diameter: "49.244 km",
    rotationPeriod: "16 jam 6 menit",
    distance: "4,50 miliar km dari Matahari",
    description:
        "Neptunus adalah planet terjauh dari Matahari dan dikenal dengan angin atmosfer yang sangat cepat. Warna birunya berasal dari metana, sementara cuacanya menunjukkan badai gelap yang berubah seiring waktu.",
    cameraOrbit: "300deg 64deg 3.6m",
    cameraTarget: "0m 0m 29.6m",
  ),
];
