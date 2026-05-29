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
              (() => {
              const viewer = document.querySelector('model-viewer');
              if (!viewer) return;
              if (window._solarViewerInitialized && window._solarViewerElement === viewer) return;
              window._solarViewerInitialized = true;
              window._solarViewerElement = viewer;
              const playSolarAnimation = () => {
                viewer.animationName = 'Rotasi dan orbit tata surya';
                viewer.timeScale = 0.65;
                viewer.currentTime = Math.max(viewer.currentTime || 0, 0.01);
                const result = viewer.play({ repetitions: Infinity });
                if (result && typeof result.catch === 'function') {
                  result.catch(() => {});
                }
              };
              const orbitConfig = {
                1: { radius: 0, period: 1 },
                2: { radius: 7.2, period: 24 },
                3: { radius: 9.4, period: 28 },
                4: { radius: 11.8, period: 42 },
                5: { radius: 1.35, period: 14, moon: true },
                6: { radius: 14.4, period: 56 },
                7: { radius: 18.6, period: 84 },
                8: { radius: 22.6, period: 112 },
                9: { radius: 26.2, period: 168 },
                10: { radius: 29.6, period: 168 },
              };
              const earthConfig = orbitConfig[4];
              const orbitPosition = (index, time) => {
                const config = orbitConfig[index];
                if (!config) return { x: 0, y: 0, z: 0 };
                if (index === 1) return { x: 0, y: 0, z: 0 };

                const direction = -1;
                if (config.moon) {
                  const earthAngle = direction * Math.PI * 2 * time / earthConfig.period;
                  const moonAngle = direction * Math.PI * 2 * time / config.period;
                  const earth = {
                    x: -Math.sin(earthAngle) * earthConfig.radius,
                    z: Math.cos(earthAngle) * earthConfig.radius,
                  };
                  return {
                    x: earth.x + Math.cos(moonAngle) * config.radius,
                    y: 0,
                    z: earth.z + Math.sin(moonAngle) * config.radius,
                  };
                }

                const angle = direction * Math.PI * 2 * time / config.period;
                return {
                  x: -Math.sin(angle) * config.radius,
                  y: 0,
                  z: Math.cos(angle) * config.radius,
                };
              };
              const setCameraTarget = (position) => {
                viewer.cameraTarget = `\${position.x.toFixed(2)}m \${position.y.toFixed(2)}m \${position.z.toFixed(2)}m`;
              };
              const updateTrackedCamera = () => {
                if (window._trackedPlanetIndex && window._trackedPlanetIndex !== 0) {
                  setCameraTarget(orbitPosition(window._trackedPlanetIndex, viewer.currentTime || 0));
                }
                requestAnimationFrame(updateTrackedCamera);
              };
              window.setTrackedPlanet = (index) => {
                window._trackedPlanetIndex = index;
                if (index === 0) {
                  viewer.cameraTarget = '${planetList[0].cameraTarget}';
                  return;
                }
                setCameraTarget(orbitPosition(index, viewer.currentTime || 0));
              };
              const planetIndexFromName = (rawName = '') => {
                const name = rawName.toLowerCase();
                if (name.includes('merkurius') || name.includes('mercury')) return 2;
                if (name.includes('venus')) return 3;
                if (name.includes('bumi') || name.includes('earth') || name.includes('erath')) return 4;
                if (name.includes('bulan') || name.includes('moon')) return 5;
                if (name.includes('mars')) return 6;
                if (name.includes('jupiter')) return 7;
                if (name.includes('saturnus') || name.includes('saturn')) return 8;
                if (name.includes('uranus')) return 9;
                if (name.includes('neptunus') || name.includes('neptune')) return 10;
                if (
                  name === 'sun' ||
                  name.includes('matahari') ||
                  name.includes('emisi') ||
                  name.includes('solar')
                ) {
                  return 1;
                }
                return -1;
              };
              const planetIndexFromHit = (hitObject, materialName) => {
                const names = [];
                if (materialName) names.push(materialName);
                let object = hitObject;
                while (object) {
                  if (object.name) names.push(object.name);
                  if (object.material?.name) names.push(object.material.name);
                  object = object.parent;
                }
                for (const item of names) {
                  const index = planetIndexFromName(item);
                  if (index !== -1) return index;
                }
                return -1;
              };

              viewer.addEventListener('load', () => {
                viewer.cameraOrbit = '${planetList[0].cameraOrbit}';
                viewer.cameraTarget = '${planetList[0].cameraTarget}';
                viewer.interpolationDecay = 80;
                playSolarAnimation();
                updateTrackedCamera();
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
                let hitObject = null;
                const material = viewer.materialFromPoint?.(event.clientX, event.clientY);
                if (material && material.name) {
                  name = material.name;
                }
                const hit = viewer.queryHitTest?.(x, y);
                if (hit && hit.object) {
                  hitObject = hit.object;
                  if (!name) {
                    name = hit.object.name || hit.object.material?.name || '';
                  }
                }
                const index = planetIndexFromHit(hitObject, name);
                if (window.PlanetClickChannel && index !== -1) {
                  window.PlanetClickChannel.postMessage(String(index));
                }
              });
              })();
            ''',
            javascriptChannels: {
              JavascriptChannel(
                'PlanetClickChannel',
                onMessageReceived: (message) {
                  final name = message.message;
                  final parsedIndex = int.tryParse(name);
                  int index = parsedIndex ?? _getPlanetIndexFromName(name);
                  if (index != -1) {
                    _focusPlanet(index);
                  }
                },
              ),
            },
          ),

          // LAYER 2: Info atas
          if (!isOverview)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 74, 12, 0),
                  child: PlanetInfoCard(
                    key: ValueKey(selectedPlanet.name),
                    planet: selectedPlanet,
                    onClose: () {
                      _focusPlanet(0);
                    },
                  ),
                ),
              ),
            ),

          // LAYER 3: Navigasi bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: _buildPlanetList(),
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
      (() => {
        const viewer = document.querySelector('model-viewer');
        if (!viewer) return;
        viewer.animationName = 'Rotasi dan orbit tata surya';
        viewer.timeScale = 0.65;
        viewer.interpolationDecay = 80;
        viewer.cameraOrbit = '${planet.cameraOrbit}';
        if (window.setTrackedPlanet) {
          window.setTrackedPlanet($index);
        } else {
          viewer.cameraTarget = '${planet.cameraTarget}';
        }
        const playResult = viewer.play({ repetitions: Infinity });
        if (playResult && typeof playResult.catch === 'function') {
          playResult.catch(() => {});
        }
      })();
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
          final bool isSelected = index == selectedIndex;

          return Padding(
            padding: EdgeInsets.only(
              left: index == 1 ? 16.0 : 0.0,
              right: 12.0,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? Colors.cyanAccent.withValues(alpha: 0.24)
                    : Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(
                  color: isSelected
                      ? Colors.cyanAccent.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.4),
                  width: 1.2,
                ),
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
    if (name.contains('bumi') || name.contains('erath')) return 4;
    if (name.contains('bulan')) return 5;
    if (name.contains('mars')) return 6;
    if (name.contains('jupiter')) return 7;
    if (name.contains('saturnus')) return 8;
    if (name.contains('uranus')) return 9;
    if (name.contains('neptunus') ||
        name.contains('neptune') ||
        name.contains('neptune_25')) {
      return 10;
    }
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
