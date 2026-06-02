import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../data/pc_part_data.dart';
import '../models/pc_part.dart';
import '../widgets/pc_part_info_card.dart';

class PcViewerScreen extends StatefulWidget {
  const PcViewerScreen({super.key});

  @override
  State<PcViewerScreen> createState() => _PcViewerScreenState();
}

class _PcViewerScreenState extends State<PcViewerScreen> {
  int selectedIndex = 0;
  bool isExploded = false;
  dynamic _webViewController;

  @override
  Widget build(BuildContext context) {
    final selectedPart = pcPartList[selectedIndex];
    final isOverview = selectedIndex == 0;
    final pcModelSource = isExploded
        ? 'assets/models/computer_pc_futuristic_exploded.glb'
        : 'assets/models/computer_pc_futuristic_named.glb';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Edukasi Hardware PC AR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ModelViewer(
            key: ValueKey(pcModelSource),
            src: pcModelSource,
            ar: true,
            autoPlay: false,
            autoRotate: false,
            cameraControls: true,
            disableZoom: false,
            cameraOrbit: pcPartList[0].cameraOrbit,
            cameraTarget: pcPartList[0].cameraTarget,
            exposure: 1.15,
            shadowIntensity: 0.9,
            shadowSoftness: 0.55,
            interactionPrompt: InteractionPrompt.none,
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            relatedJs: '''
              (() => {
                const viewer = document.querySelector('model-viewer');
                if (!viewer) return;
                const scriptVersion = 'pc-futuristic-v1';
                if (
                  window._pcViewerVersion === scriptVersion &&
                  window._pcViewerElement === viewer
                ) {
                  return;
                }
                window._pcViewerVersion = scriptVersion;
                window._pcViewerElement = viewer;
                if (typeof window._pcExplodedState !== 'boolean') {
                  window._pcExplodedState = false;
                }

                const partIndexFromName = (rawName = '') => {
                  const name = rawName.toLowerCase();
                  if (name.includes('futuristic case')) return 1;
                  if (name.includes('side panel')) return 2;
                  if (name.includes('motherboard')) return 3;
                  if (name.includes('cooling system')) return 4;
                  if (name.includes('memory module')) return 5;
                  if (name.includes('graphics unit')) return 6;
                  if (name.includes('power bay')) return 7;
                  if (name.includes('rear i/o')) return 8;
                  return -1;
                };

                const indexFromHit = (hitObject, materialName) => {
                  const names = [];
                  if (materialName) names.push(materialName);
                  let object = hitObject;
                  while (object) {
                    if (object.name) names.push(object.name);
                    if (object.material?.name) names.push(object.material.name);
                    object = object.parent;
                  }
                  for (const item of names) {
                    const index = partIndexFromName(item);
                    if (index !== -1) return index;
                  }
                  return -1;
                };

                const partRules = {
                  1: {
                    keywords: ['futuristic case'],
                    offset: [-0.6, 0.0, 0.45],
                  },
                  2: {
                    keywords: ['side panel'],
                    offset: [-1.05, 0.0, 0.25],
                  },
                  3: {
                    keywords: ['motherboard'],
                    offset: [-0.25, 0.55, 0.55],
                  },
                  4: {
                    keywords: ['cooling system'],
                    offset: [0.0, 0.85, 0.7],
                  },
                  5: {
                    keywords: ['memory module'],
                    offset: [-0.65, 0.35, 0.85],
                  },
                  6: {
                    keywords: ['graphics unit'],
                    offset: [0.85, -0.25, 0.55],
                  },
                  7: {
                    keywords: ['power bay'],
                    offset: [0.55, -0.75, 0.35],
                  },
                  8: {
                    keywords: ['rear i/o'],
                    offset: [0.35, -0.35, 0.8],
                  },
                };

                const partRoots = (index = null) => {
                  const rules = index ? { [index]: partRules[index] } : partRules;
                  const roots = [];
                  const seen = new Set();
                  viewer.model?.scene?.traverse((object) => {
                    const name = [
                      object.name || '',
                      object.material?.name || '',
                    ].join(' ').toLowerCase();
                    for (const [partIndex, rule] of Object.entries(rules)) {
                      const matchedKeyword = rule?.keywords.find((keyword) => {
                        if (keyword.startsWith('object_')) {
                          return name === keyword || name.startsWith(`\${keyword}_`);
                        }
                        if (keyword.startsWith('cube.')) {
                          return name === keyword || name.startsWith(`\${keyword}_`);
                        }
                        return name.includes(keyword);
                      });
                      if (!matchedKeyword) continue;
                      const parentName = (object.parent?.name || '').toLowerCase();
                      if (parentName.includes(matchedKeyword)) continue;
                      if (!seen.has(object.uuid)) {
                        seen.add(object.uuid);
                        roots.push({ object, rule, partIndex: Number(partIndex) });
                      }
                    }
                  });
                  return roots;
                };

                const animatePosition = (object, target, duration = 420) => {
                  const start = {
                    x: object.position.x,
                    y: object.position.y,
                    z: object.position.z,
                  };
                  const startedAt = performance.now();
                  const easeOut = (t) => 1 - Math.pow(1 - t, 3);
                  const step = (now) => {
                    const t = Math.min(1, (now - startedAt) / duration);
                    const eased = easeOut(t);
                    object.position.set(
                      start.x + (target[0] - start.x) * eased,
                      start.y + (target[1] - start.y) * eased,
                      start.z + (target[2] - start.z) * eased,
                    );
                    if (t < 1) requestAnimationFrame(step);
                  };
                  requestAnimationFrame(step);
                };

                const animateScale = (object, target, duration = 420) => {
                  const start = {
                    x: object.scale.x,
                    y: object.scale.y,
                    z: object.scale.z,
                  };
                  const startedAt = performance.now();
                  const easeOut = (t) => 1 - Math.pow(1 - t, 3);
                  const step = (now) => {
                    const t = Math.min(1, (now - startedAt) / duration);
                    const eased = easeOut(t);
                    object.scale.set(
                      start.x + (target[0] - start.x) * eased,
                      start.y + (target[1] - start.y) * eased,
                      start.z + (target[2] - start.z) * eased,
                    );
                    if (t < 1) requestAnimationFrame(step);
                  };
                  requestAnimationFrame(step);
                };

                const syncBasePositions = () => {
                  viewer.interpolationDecay = 85;
                  partRoots().forEach(({ object }) => {
                    object.userData.basePosition = [
                      object.position.x,
                      object.position.y,
                      object.position.z,
                    ];
                    object.userData.baseScale = [
                      object.scale.x,
                      object.scale.y,
                      object.scale.z,
                    ];
                  });
                };

                viewer.addEventListener('load', () => {
                  syncBasePositions();
                  window.setPcExploded(window._pcExplodedState);
                });

                window.setPcExploded = (isExploded) => {
                  window._pcExplodedState = isExploded;
                  partRoots().forEach(({ object, rule }) => {
                    const base = object.userData.basePosition || [
                      object.position.x,
                      object.position.y,
                      object.position.z,
                    ];
                    const target = isExploded
                      ? [
                          base[0] + rule.offset[0],
                          base[1] + rule.offset[1],
                          base[2] + rule.offset[2],
                        ]
                      : base;
                    const baseScale = object.userData.baseScale || [
                      object.scale.x,
                      object.scale.y,
                      object.scale.z,
                    ];
                    const targetScale = isExploded
                      ? [
                          baseScale[0] * 1.03,
                          baseScale[1] * 1.03,
                          baseScale[2] * 1.03,
                        ]
                      : baseScale;
                    animatePosition(object, target);
                    animateScale(object, targetScale);
                  });
                };

                if (viewer.model?.scene) {
                  syncBasePositions();
                  window.setPcExploded(window._pcExplodedState);
                }

                window.focusPcPart = (index) => {
                  if (index === 0) return false;
                  const object = partRoots(index)[0]?.object;
                  if (!object) return false;
                  object.updateWorldMatrix(true, false);
                  const matrix = object.matrixWorld?.elements;
                  if (!matrix) return false;
                  viewer.cameraTarget = `\${matrix[12].toFixed(2)}m \${matrix[13].toFixed(2)}m \${matrix[14].toFixed(2)}m`;
                  viewer.fieldOfView = '18deg';
                  return true;
                };

                viewer.addEventListener('click', (event) => {
                  const rect = viewer.getBoundingClientRect();
                  const x = event.clientX - rect.left;
                  const y = event.clientY - rect.top;
                  let name = '';
                  let hitObject = null;
                  const material = viewer.materialFromPoint?.(event.clientX, event.clientY);
                  if (material?.name) name = material.name;
                  const hit = viewer.queryHitTest?.(x, y);
                  if (hit?.object) {
                    hitObject = hit.object;
                    if (!name) name = hit.object.name || hit.object.material?.name || '';
                  }
                  const index = indexFromHit(hitObject, name);
                  if (window.PcPartClickChannel && index !== -1) {
                    window.PcPartClickChannel.postMessage(String(index));
                  }
                });
              })();
            ''',
            javascriptChannels: {
              JavascriptChannel(
                'PcPartClickChannel',
                onMessageReceived: (message) {
                  final index = int.tryParse(message.message) ?? -1;
                  if (index != -1) _focusPart(index);
                },
              ),
            },
          ),
          if (!isOverview)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: PcPartInfoCard(
                    key: ValueKey(selectedPart.name),
                    part: selectedPart,
                    onClose: () => _focusPart(0),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeControls(),
                  const SizedBox(height: 12),
                  _buildPartList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeControls() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: 'Rakit',
            icon: Icons.inventory_2_outlined,
            active: !isExploded,
            onPressed: () => _setExploded(false),
          ),
          _ModeButton(
            label: 'Bongkar',
            icon: Icons.open_in_full_rounded,
            active: isExploded,
            onPressed: () => _setExploded(true),
          ),
        ],
      ),
    );
  }

  Widget _buildPartList() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pcPartList.length,
        itemBuilder: (context, index) {
          if (index == 0) return const SizedBox.shrink();
          final isSelected = selectedIndex == index;
          return Padding(
            padding: EdgeInsets.only(left: index == 1 ? 16 : 0, right: 12),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: () => _focusPart(index),
              child: Text(
                pcPartList[index].name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          );
        },
      ),
    );
  }

  void _setExploded(bool value) {
    setState(() => isExploded = value);
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _focusPart(selectedIndex);
    });
  }

  void _focusPart(int index) {
    final PcPart part = pcPartList[index];
    setState(() => selectedIndex = index);
    _webViewController?.runJavaScript("""
      (() => {
        const viewer = document.querySelector('model-viewer');
        if (!viewer) return;
        viewer.cameraOrbit = '${part.cameraOrbit}';
        viewer.fieldOfView = $index === 0 ? '26deg' : '18deg';
        if (!window.focusPcPart || !window.focusPcPart($index)) {
          viewer.cameraTarget = '${part.cameraTarget}';
        }
        viewer.interpolationDecay = 85;
      })();
    """);
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: active ? Colors.black : Colors.white,
        backgroundColor: active ? Colors.cyanAccent : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
