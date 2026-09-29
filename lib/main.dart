import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const QuantXApp());
}

class QuantXApp extends StatelessWidget {
  const QuantXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuantX',
      debugShowCheckedModeBanner: false,
      theme: buildQuantXTheme(),
      home: const _Boot(),
    );
  }
}

// Landing selalu muncul (LoginScreen dengan tombol MASUK), TAPI kalau pas
// app pertama dibuka ternyata ada sesi valid tersimpen, langsung
// dilewatin ke Dashboard tanpa perlu mencet apa-apa — sisanya (skip form
// kalau tekan MASUK dan sesi valid) sudah ditangani di LoginScreen sendiri.
class _Boot extends StatefulWidget {
  const _Boot();
  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  final _api = ApiService();
  bool _checked = false;
  Widget? _target;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final result = await _api.fetchMe();
    if (!mounted) return;
    setState(() {
      _checked = true;
      _target = result.ok
          ? DashboardScreen(account: result.account!, api: _api)
          : const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _target!;
  }
}
