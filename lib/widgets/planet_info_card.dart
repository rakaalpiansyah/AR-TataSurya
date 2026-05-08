import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/planet.dart';

class PlanetInfoCard extends StatelessWidget {
  final Planet planet;
  final VoidCallback onClose;

  const PlanetInfoCard({super.key, required this.planet, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Margin dihindarkan dari pojok kiri dan kanan bawah agar tidak menabrak tombol AR
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        planet.name,
                        style: const TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.w800, 
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded, size: 26, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (planet.distance != "-")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Text(
                      planet.distance,
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600, 
                        color: Colors.lightBlueAccent
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  planet.description,
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.white.withValues(alpha: 0.9), 
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}