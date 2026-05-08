import '../models/planet.dart';

final List<Planet> planetList = [
  Planet(
    name: "Sistem Tata Surya",
    description: "Sistem Tata Surya kita terdiri dari Matahari dan segala sesuatu yang terikat padanya oleh gravitasi.",
    distance: "-",
    cameraOrbit: "0deg 60deg 20m", // Zoom out maksimal untuk melihat semua planet
    cameraTarget: "0m 0m 0m", // Fokus di tengah (Matahari)
  ),
  Planet(
    name: "Matahari",
    description: "Bintang di pusat Tata Surya. Merupakan bola gas panas raksasa yang menjadi sumber cahaya dan panas utama bagi Bumi.",
    distance: "0 km",
    cameraOrbit: "0deg 75deg 2.0m", // Sedikit lebih dekat
    cameraTarget: "0m 0m 0m",
  ),
  Planet(
    name: "Merkurius",
    description: "Planet terkecil dan terdekat dengan Matahari. Permukaannya dipenuhi kawah mirip Bulan dan mengalami perubahan suhu yang sangat ekstrem.",
    distance: "57.9 juta km",
    cameraOrbit: "45deg 75deg 0.5m", // Radius zoom 
    cameraTarget: "0m 0m 9.69m", // Koordinat asli dari GLB pada t=0
  ),
  Planet(
    name: "Venus",
    description: "Planet terpanas di Tata Surya karena efek rumah kaca dari atmosfer tebalnya yang beracun. Sering disebut sebagai 'Bintang Kejora'.",
    distance: "108.2 juta km",
    cameraOrbit: "90deg 75deg 0.6m", 
    cameraTarget: "0m 0m 12.23m", // Koordinat asli
  ),
  Planet(
    name: "Bumi",
    description: "Planet ketiga dari Matahari dan satu-satunya tempat di alam semesta yang diketahui memiliki kehidupan. Sekitar 71% permukaannya tertutup air.",
    distance: "149.6 juta km",
    cameraOrbit: "135deg 75deg 0.6m", 
    cameraTarget: "0m 0m 16.11m", // Koordinat asli
  ),
  Planet(
    name: "Bulan",
    description: "Satelit alami satu-satunya milik Bumi. Bulan adalah objek terterang kedua di langit malam dan berpengaruh besar terhadap pasang surut air laut di Bumi.",
    distance: "384.400 km dari Bumi",
    cameraOrbit: "140deg 70deg 0.3m", // Zoom dekat ke Bulan
    cameraTarget: "0m 0.5m 17m", // Dekat Bumi, sedikit di atas bidang orbit
  ),
  Planet(
    name: "Mars",
    description: "Dijuluki Planet Merah karena debu besi oksida (karat) di permukaannya. Mars memiliki gunung berapi terbesar di Tata Surya bernama Olympus Mons.",
    distance: "227.9 juta km",
    cameraOrbit: "180deg 75deg 0.5m", 
    cameraTarget: "0m 0m 20.45m", // Koordinat asli
  ),
  Planet(
    name: "Jupiter",
    description: "Planet terbesar di Tata Surya. Merupakan raksasa gas yang terkenal dengan 'Bintik Merah Raksasa', sebuah badai besar yang telah berlangsung ratusan tahun.",
    distance: "778.5 juta km",
    cameraOrbit: "225deg 75deg 1.5m", 
    cameraTarget: "0m 0m 28.77m", // Koordinat asli
  ),
  Planet(
    name: "Saturnus",
    description: "Planet raksasa gas yang terkenal dengan sistem cincinnya yang menakjubkan dan kompleks, sebagian besar terbuat dari bongkahan es dan batuan.",
    distance: "1.43 miliar km",
    cameraOrbit: "270deg 75deg 2.5m", 
    cameraTarget: "0m 0m 36.61m", // Koordinat asli
  ),
  Planet(
    name: "Uranus",
    description: "Planet es raksasa yang berputar miring (hampir 90 derajat) di porosnya. Uranus memiliki suhu atmosfer paling dingin di antara planet lainnya.",
    distance: "2.87 miliar km",
    cameraOrbit: "315deg 75deg 1.2m", 
    cameraTarget: "0m 0m 44.26m", // Koordinat asli
  ),
  Planet(
    name: "Neptunus",
    description: "Planet terjauh dari Matahari. Merupakan planet es raksasa yang gelap, sangat dingin, dan memiliki angin puyuh supersonik tercepat di Tata Surya.",
    distance: "4.50 miliar km",
    cameraOrbit: "360deg 75deg 1.2m", 
    cameraTarget: "0m 0m 49.92m", // Koordinat asli
  ),
];