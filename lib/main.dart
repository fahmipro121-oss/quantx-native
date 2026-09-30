import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const QuantXApp());
}

class QuantXApp extends StatelessWidget {
  const QuantXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orion AI',
      debugShowCheckedModeBanner: false,
      theme: buildQuantXTheme(),
      // Halaman utama (tombol MASUK) SELALU muncul dulu tiap app dibuka —
      // nggak langsung nyelonong ke dashboard diam-diam biarpun sesinya
      // masih valid. Pengecekan sesi (skip form login atau enggak) baru
      // kejadian pas tombol MASUK ditekan, ditangani di LoginScreen.
      home: const LoginScreen(),
    );
  }
}
