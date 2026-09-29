import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = ApiService();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showForm = false;
  bool _checking = false;
  bool _loading = false;
  String? _error;

  // Dipanggil pas tombol MASUK ditekan — cek dulu ke server apa sesi lama
  // masih valid (sama kayak goToLogin() di versi web). Kalau valid, skip
  // form sama sekali dan langsung ke dashboard.
  Future<void> _onMasukPressed() async {
    setState(() => _checking = true);
    final result = await _api.fetchMe();
    if (!mounted) return;
    setState(() => _checking = false);
    if (result.ok) {
      _goToDashboard(result.account!);
    } else {
      setState(() => _showForm = true);
    }
  }

  Future<void> _onLoginSubmit() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Username dan password wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.login(username, password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      _goToDashboard(result.account!);
    } else {
      setState(() => _error = _errorMessage(result.error));
    }
  }

  String _errorMessage(String? code) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return 'Username atau password salah.';
      case 'EXPIRED':
        return 'Akun kamu udah expired. Hubungi admin buat perpanjang.';
      case 'PENDING':
        return 'Akun kamu masih menunggu aktivasi.';
      case 'DISABLED':
        return 'Akun kamu dinonaktifkan. Hubungi admin.';
      case 'NETWORK_ERROR':
        return 'Nggak bisa nyambung ke server. Cek koneksi internet kamu.';
      default:
        return 'Login gagal. Coba lagi.';
    }
  }

  void _goToDashboard(dynamic account) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DashboardScreen(account: account, api: _api)),
    );
  }

  // Ganti link server tanpa perlu build ulang + install ulang APK — tiap
  // kali link Cloudflare Tunnel di Termux berubah (misal abis restart),
  // tinggal buka ini, tempel link barunya.
  Future<void> _openServerSettings() async {
    final current = await _api.baseUrl;
    if (!mounted) return;
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantXColors.panel,
        title: const Text('Alamat Server', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(hintText: 'https://xxxx.trycloudflare.com'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await _api.setBaseUrl(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat server disimpan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white38),
            tooltip: 'Alamat Server',
            onPressed: _openServerSettings,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                  children: [
                    TextSpan(text: 'QUANT', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'X', style: TextStyle(color: QuantXColors.accent)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text('AI ANALISA MARKET',
                  style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 3)),
              const SizedBox(height: 48),
              if (!_showForm) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checking ? null : _onMasukPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuantXColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_checking ? 'MEMERIKSA...' : 'MASUK'),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _userCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSubmitted: (_) => _onLoginSubmit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFFF5A5A), fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _onLoginSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuantXColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_loading ? 'MASUK...' : 'LOGIN'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
