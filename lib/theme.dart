import 'package:flutter/material.dart';

// Palet warna ini sengaja disamain persis sama css/styles.css versi web,
// biar brand-nya konsisten antara web dan app native.
class QuantXColors {
  static const bg = Color(0xFF05060D);
  static const panel = Color(0xFF0B0E1A);
  static const line = Color(0xFF1C2133);
  static const mute = Color(0xFF8B93A8);
  static const accent = Color(0xFF4DA8FF); // dipakai umum (tombol, dll)

  // Warna per role — VIP biru, Executive ungu, Elite/Owner merah.
  static const vip = Color(0xFF4DA8FF);
  static const executive = Color(0xFFC48BFF);
  static const elite = Color(0xFFFF5A5A);

  static Color forRole(String role) {
    switch (role) {
      case 'RESELLER':
        return executive;
      case 'PARTNER':
      case 'OWNER':
        return elite;
      case 'MEMBER':
      default:
        return vip;
    }
  }
}

ThemeData buildQuantXTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: QuantXColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: QuantXColors.accent,
      secondary: QuantXColors.accent,
      surface: QuantXColors.panel,
    ),
    useMaterial3: true,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: QuantXColors.panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: QuantXColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: QuantXColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: QuantXColors.accent),
      ),
      labelStyle: const TextStyle(color: QuantXColors.mute),
    ),
  );
}
