import 'package:flutter/material.dart';

// Pastikan import ini mengarah ke folder screens tempat UI Anda berada
import 'screens/ar_viewer_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AR Tata Surya',
      theme: ThemeData(
        // Tema dasar aplikasi Anda
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // Layar pertama yang dibuka saat aplikasi dijalankan
      home: const ArViewerScreen(), 
    );
  }
}