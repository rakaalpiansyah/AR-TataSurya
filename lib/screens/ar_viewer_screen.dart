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

  @override
  Widget build(BuildContext context) {
    Planet selectedPlanet = planetList[selectedIndex];
    bool isOverview = selectedIndex == 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edukasi Tata Surya AR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // LAYER 1: Mesin AR 3D
          ModelViewer(
            src: 'assets/models/solar-professional.glb',
            ar: true,
            autoPlay: true,
            autoRotate: false,
            cameraControls: true,
            disableZoom: false,
            cameraOrbit: planetList[0].cameraOrbit,
            cameraTarget: planetList[0].cameraTarget,
            exposure: 1.2,
            shadowIntensity: 0.8,
            shadowSoftness: 0.5,
            animationName: 'Rotasi dan orbit tata surya',
            interactionPrompt: InteractionPrompt.none,
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            // Kirim nama mesh objek yang diklik ke Flutter
            relatedJs: '''
              const viewer = document.querySelector('model-viewer');
              const playSolarAnimation = () => {
                viewer.animationName = 'Rotasi dan orbit tata surya';
                viewer.timeScale = 0.65;
                viewer.currentTime = Math.max(viewer.currentTime || 0, 0.01);
                const result = viewer.play({ repetitions: Infinity });
                if (result && typeof result.catch === 'function') {
                  result.catch(() => {});
                }
              };

              viewer.addEventListener('load', () => {
                viewer.cameraOrbit = '${planetList[0].cameraOrbit}';
                viewer.cameraTarget = '${planetList[0].cameraTarget}';
                viewer.interpolationDecay = 80;
                playSolarAnimation();
                setTimeout(playSolarAnimation, 250);
              });

              viewer.addEventListener('finished', () => {
                viewer.currentTime = 0.01;
                playSolarAnimation();
              });

              viewer.addEventListener('click', (event) => {
                const rect = viewer.getBoundingClientRect();
                const x = event.clientX - rect.left;
                const y = event.clientY - rect.top;
                let name = '';
                const material = viewer.materialFromPoint?.(event.clientX, event.clientY);
                if (material && material.name) {
                  name = material.name;
                }
                const hit = viewer.queryHitTest?.(x, y);
                if (!name && hit && hit.object) {
                  name = hit.object.name || hit.object.material?.name || '';
                }
                if (window.PlanetClickChannel && name) {
                  window.PlanetClickChannel.postMessage(name);
                }
              });
            ''',
            javascriptChannels: {
              JavascriptChannel(
                'PlanetClickChannel',
                onMessageReceived: (message) {
                  final name = message.message;
                  int index = _getPlanetIndexFromName(name);
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

  void _focusPlanet(int index) {
    final planet = planetList[index];

    setState(() {
      selectedIndex = index;
    });

    if (_webViewController == null) return;

    // Arahkan kamera ke planet — animasi tetap berjalan tanpa pause
    _webViewController!.runJavaScript("""
      const v = document.querySelector('model-viewer');
      v.animationName = 'Rotasi dan orbit tata surya';
      v.timeScale = 0.65;
      v.interpolationDecay = 80;
      v.cameraOrbit = '${planet.cameraOrbit}';
      v.cameraTarget = '${planet.cameraTarget}';
      const playResult = v.play({ repetitions: Infinity });
      if (playResult && typeof playResult.catch === 'function') {
        playResult.catch(() => {});
      }
    """);
  }

  Widget _buildPlanetList() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: planetList.length,
        itemBuilder: (context, index) {
          if (index == 0) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.only(
              left: index == 1 ? 16.0 : 0.0,
              right: 12.0,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4), width: 1.2),
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
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 15),
              ),
            ),
          );
        },
      ),
    );
  }

  // Deteksi planet dari nama mesh/material/node di solar-professional.glb.
  int _getPlanetIndexFromName(String rawName) {
    final name = rawName.toLowerCase();
    // Nama mesh Bahasa Indonesia dari model profesional.
    if (name.contains('merkurius')) return 2;
    if (name.contains('venus')) return 3;
    if (name.contains('bumi')) return 4;
    if (name.contains('bulan')) return 5;
    if (name.contains('mars')) return 6;
    if (name.contains('jupiter')) return 7;
    if (name.contains('saturnus')) return 8;
    if (name.contains('uranus')) return 9;
    if (name.contains('neptunus') || name.contains('neptune')) return 10;
    // Nama material/node Matahari
    if (name == 'sun' ||
        name.contains('matahari') ||
        name.contains('emisi') ||
        name.contains('solar')) {
      return 1;
    }
    // Fallback nama Inggris
    if (name.contains('mercury')) return 2;
    if (name.contains('earth')) return 4;
    if (name.contains('moon')) return 5;
    if (name.contains('saturn')) return 8;
    return -1;
  }
}
