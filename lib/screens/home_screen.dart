import 'package:flutter/material.dart';

import '../features/chess/screens/chess_learning_ar_screen.dart';
import '../features/chess/screens/chess_viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070706),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          children: [
            const _HeroHeader(),
            const SizedBox(height: 22),
            _ModeCard(
              badge: 'MODE GAME',
              title: 'Main Catur 3D',
              subtitle: 'Papan 3D interaktif untuk bermain dengan teman, melawan bot, atau multiplayer Wi-Fi satu jaringan.',
              primaryAction: 'Mulai Bermain',
              icon: Icons.sports_esports_rounded,
              color: const Color(0xFFFFD54F),
              highlights: const ['3D Interactive', 'Bot Chess', 'Wi-Fi LAN'],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChessViewerScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            _ModeCard(
              badge: 'MODE BELAJAR',
              title: 'Belajar Catur AR',
              subtitle: 'Letakkan papan di kamera AR untuk melihat susunan bidak dan contoh animasi skakmat putih.',
              primaryAction: 'Buka AR',
              icon: Icons.view_in_ar_rounded,
              color: const Color(0xFF40E0D0),
              highlights: const ['Kamera AR', 'Materi Catur', 'Animasi Skakmat'],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChessLearningArScreen()),
                );
              },
            ),
            const SizedBox(height: 18),
            const _ProjectNote(),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171711), Color(0xFF0A0A08)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.amberAccent.withValues(alpha: .08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: .24)),
            ),
            child: const Text(
              'AUGMENTED REALITY CHESS',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AR Chess Arena',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Aplikasi catur 3D dengan dua pengalaman utama: bermain catur interaktif dan belajar catur lewat kamera AR.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 14,
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final String primaryAction;
  final IconData icon;
  final Color color;
  final List<String> highlights;
  final VoidCallback onTap;

  const _ModeCard({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.primaryAction,
    required this.icon,
    required this.color,
    required this.highlights,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF11110F),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 29),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: color),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .68),
                fontSize: 13,
                height: 1.36,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final highlight in highlights)
                  _FeaturePill(label: highlight, color: color),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                primaryAction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  final Color color;

  const _FeaturePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .76),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectNote extends StatelessWidget {
  const _ProjectNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode bermain digunakan untuk gameplay catur 3D. Mode belajar AR digunakan untuk demonstrasi edukasi lewat kamera.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .58),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
