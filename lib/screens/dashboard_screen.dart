import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'orion_chat_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Account account;
  final ApiService api;
  const DashboardScreen({super.key, required this.account, required this.api});

  Future<void> _logout(BuildContext context) async {
    await api.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = QuantXColors.forRole(account.role);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: QuantXColors.bg,
        title: const Text('ORION AI', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: roleColor,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text('Chat Orion', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrionChatScreen(account: account, api: api)),
        ),
      ),
      body: QuantXBackground(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuantXColors.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: roleColor.withOpacity(0.15), blurRadius: 20, spreadRadius: -6),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    account.username,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: roleColor,
                      shadows: [Shadow(color: roleColor.withOpacity(0.7), blurRadius: 12)],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: roleColor),
                    boxShadow: [
                      BoxShadow(color: roleColor.withOpacity(0.5), blurRadius: 10),
                    ],
                  ),
                  child: Text(account.roleLabel,
                      style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Role & Benefit Chat Orion AI',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          _benefitCard('VIP', QuantXColors.vip, [
            'Chat Orion AI 20x/hari',
            'Akses dashboard live semua pair',
            'Analisa teknikal lengkap (SNR, Order Block, Fibonacci) + cek harga real-time tiap chat',
          ]),
          const SizedBox(height: 12),
          _benefitCard('EXECUTIVE', QuantXColors.executive, [
            'Semua benefit VIP',
            'Chat Orion AI 35x/hari',
            'Naik ke model AI yang lebih kuat',
            'Mode analisa DALAM — tiap jawaban dicek & direvisi ulang otomatis',
          ]),
          const SizedBox(height: 12),
          _benefitCard('EXECUTIVE ELITE', QuantXColors.elite, [
            'Semua benefit Executive',
            'Chat Orion AI 50x/hari — kuota terbesar',
            'Model AI paling kuat yang tersedia',
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text(
              // Placeholder milestone pertama — chat Orion AI, chart, dan
              // scanner nyusul di tahap berikutnya.
              'Dashboard versi native — tahap 1/beberapa.\nOrion AI, chart & scanner nyusul.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _benefitCard(String title, Color color, List<String> points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 18, spreadRadius: -4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: color, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
