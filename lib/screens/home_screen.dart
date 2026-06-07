import 'package:flutter/material.dart';

import 'ar_viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF42D7FF).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF42D7FF).withValues(alpha: 0.26),
                            ),
                          ),
                          child: const Icon(
                            Icons.public_rounded,
                            color: Color(0xFF42D7FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AR Tata Surya',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Media pembelajaran astronomi interaktif',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Eksplorasi orbit, rotasi, dan karakter planet langsung di ruang nyata.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pilih planet, sentuh objek 3D, lalu baca fakta ringkasnya. Dirancang untuk presentasi UAS Augmented Reality dengan tema edukasi tata surya.',
                      style: TextStyle(
                        color: Color(0xFFB6C3D6),
                        fontSize: 15,
                        height: 1.48,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _StartButton(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ArViewerScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(
                          child: _StatTile(value: '10', label: 'Objek langit'),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(value: '3D', label: 'Model GLB'),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(value: 'AR', label: 'Mode ruang nyata'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _FeatureItem(
                      icon: Icons.touch_app_rounded,
                      title: 'Interaksi langsung',
                      description:
                          'Sentuh objek 3D untuk membuka informasi edukatif tanpa alur yang rumit.',
                    ),
                    SizedBox(height: 10),
                    _FeatureItem(
                      icon: Icons.auto_awesome_motion_rounded,
                      title: 'Visual orbit dinamis',
                      description:
                          'Model bergerak menampilkan rotasi dan orbit agar materi lebih mudah dipahami.',
                    ),
                    SizedBox(height: 10),
                    _FeatureItem(
                      icon: Icons.school_rounded,
                      title: 'Siap presentasi UAS',
                      description:
                          'Tampilan dibuat ringkas, modern, dan fokus pada demonstrasi pembelajaran AR.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.view_in_ar_rounded),
        label: const Text('Mulai Eksplorasi AR'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF42D7FF),
          foregroundColor: const Color(0xFF04111A),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9AA9BD),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF42D7FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF42D7FF), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFA9B6C8),
                    fontSize: 12,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
