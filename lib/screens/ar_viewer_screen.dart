import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../models/planet.dart';
import '../data/planet_data.dart';
import '../widgets/planet_info_card.dart';

class ArViewerScreen extends StatefulWidget {
  const ArViewerScreen({super.key});

  @override
  State<ArViewerScreen> createState() => _ArViewerScreenState();
}

class _ArViewerScreenState extends State<ArViewerScreen> {
  int selectedIndex = 0; 
  dynamic _webViewController;
  
  // Variabel baru untuk Mode Statis
  bool isStaticMode = false; 

  @override
  Widget build(BuildContext context) {
    Planet selectedPlanet = planetList[selectedIndex];
    bool isOverview = selectedIndex == 0; 

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edukasi Tata Surya AR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // TOMBOL TOGGLE MODE STATIS (PLAY / PAUSE)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isStaticMode ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isStaticMode ? Colors.blueAccent : Colors.white.withValues(alpha: 0.3),
                width: 1,
              )
            ),
            child: IconButton(
              icon: Icon(
                isStaticMode ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: isStaticMode ? Colors.blueAccent : Colors.white,
              ),
              tooltip: isStaticMode ? 'Jalankan Animasi' : 'Mode Statis',
              onPressed: _toggleStaticMode,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // LAYER 1: Mesin AR 3D
          // PENTING: Property widget (cameraOrbit, cameraTarget, autoPlay) hanya dibaca SEKALI
          // saat HTML di-build. Semua perubahan dinamis HARUS dilakukan via JavaScript.
          ModelViewer(
            src: 'assets/models/solar_system_animation.glb',
            ar: true,
            autoPlay: true,  // Nilai awal, kontrol selanjutnya via JS
            autoRotate: false, 
            cameraControls: true,
            disableZoom: false,
            cameraOrbit: planetList[0].cameraOrbit,   // Nilai awal (overview)
            cameraTarget: planetList[0].cameraTarget,  // Nilai awal (overview)
            // Pengaturan visual realistis
            exposure: 1.2,
            shadowIntensity: 0.8,
            shadowSoftness: 0.5,
            // Hapus prompt interaksi bawaan agar UI lebih bersih
            interactionPrompt: InteractionPrompt.none,
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            relatedJs: '''
              const viewer = document.querySelector('model-viewer');
              viewer.addEventListener('click', (event) => {
                const material = viewer.materialFromPoint(event.clientX, event.clientY);
                if (material != null && material.name != null) {
                  if (window.PlanetClickChannel) {
                    window.PlanetClickChannel.postMessage(material.name);
                  }
                }
              });
            ''',
            javascriptChannels: {
              JavascriptChannel(
                'PlanetClickChannel',
                onMessageReceived: (message) {
                  final materialName = message.message;
                  int index = _getPlanetIndexFromMaterial(materialName);
                  if (index != -1 && index != selectedIndex) {
                    _focusPlanet(index);
                  }
                },
              ),
            },
          ),

          // LAYER 2: UI Bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isOverview 
                    ? _buildPlanetList() 
                    : PlanetInfoCard(
                        key: ValueKey(selectedPlanet.name),
                        planet: selectedPlanet,
                        onClose: () {
                          _focusPlanet(0);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi khusus untuk menangani Mode Statis
  void _toggleStaticMode() {
    setState(() {
      isStaticMode = !isStaticMode;
    });

    if (_webViewController == null) return;

    if (isStaticMode) {
      // Mode statis diaktifkan: pause + reset ke detik 0
      _webViewController!.runJavaScript("""
        const v = document.querySelector('model-viewer');
        if (window._pt) clearTimeout(window._pt);
        v.pause();
        window._pt = setTimeout(() => { v.pause(); v.currentTime = 0; }, 100);
      """);
    } else {
      // Mode statis dimatikan: play animasi HANYA jika sedang di overview
      if (selectedIndex == 0) {
        _webViewController!.runJavaScript("""
          const v = document.querySelector('model-viewer');
          if (window._pt) { clearTimeout(window._pt); window._pt = null; }
          v.play();
          setTimeout(() => { v.play(); }, 120);
        """);
      }
    }
  }

  void _focusPlanet(int index) {
    final planet = planetList[index];

    setState(() {
      selectedIndex = index;
    });

    if (_webViewController == null) return;

    if (index == 0) {
      // Kembali ke overview — semua dalam SATU panggilan JS
      if (!isStaticMode) {
        _webViewController!.runJavaScript("""
          const v = document.querySelector('model-viewer');
          if (window._pt) { clearTimeout(window._pt); window._pt = null; }
          v.cameraOrbit = '${planet.cameraOrbit}';
          v.cameraTarget = '${planet.cameraTarget}';
          v.play();
          setTimeout(() => { v.play(); }, 120);
        """);
      } else {
        _webViewController!.runJavaScript("""
          const v = document.querySelector('model-viewer');
          if (window._pt) clearTimeout(window._pt);
          v.cameraOrbit = '${planet.cameraOrbit}';
          v.cameraTarget = '${planet.cameraTarget}';
          v.pause();
          window._pt = setTimeout(() => { v.pause(); v.currentTime = 0; }, 100);
        """);
      }
    } else {
      // Fokus ke planet tertentu: pause + reset + arahkan kamera
      _webViewController!.runJavaScript("""
        const v = document.querySelector('model-viewer');
        if (window._pt) clearTimeout(window._pt);
        v.pause();
        window._pt = setTimeout(() => {
          v.pause();
          v.currentTime = 0;
          v.cameraOrbit = '${planet.cameraOrbit}';
          v.cameraTarget = '${planet.cameraTarget}';
        }, 100);
      """);
    }
  }

  Widget _buildPlanetList() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: planetList.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          if (index == 0) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15), 
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: () {
                _focusPlanet(index);
              },
              child: Text(
                planetList[index].name,
                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5, fontSize: 15),
              ),
            ),
          );
        },
      ),
    );
  }

  int _getPlanetIndexFromMaterial(String materialName) {
    String name = materialName.toLowerCase();
    if (name.contains('mercury')) return 2;
    if (name.contains('venus')) return 3;
    if (name.contains('earth')) return 4;
    if (name.contains('moon')) return 5;    // Bulan
    if (name.contains('mars')) return 6;    // Geser +1 karena Bulan di index 5
    if (name.contains('jupiter')) return 7;
    if (name.contains('saturn')) return 8;
    if (name.contains('uranus')) return 9;
    if (name.contains('neptune')) return 10;
    if (name.contains('material')) return 1; // Matahari
    return -1;
  }
}