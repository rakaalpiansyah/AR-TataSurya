class Planet {
  final String name;
  final String description;
  final String distance;
  final String cameraOrbit;  // Sudut pandang & jarak zoom kamera
  final String cameraTarget; // Titik pusat kamera

  Planet({
    required this.name,
    required this.description,
    required this.distance,
    required this.cameraOrbit,
    required this.cameraTarget,
  });
}