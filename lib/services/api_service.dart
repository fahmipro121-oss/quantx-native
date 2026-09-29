import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';

// GANTI baris ini kalau link Cloudflare Tunnel-nya berubah (misal abis
// Termux di-restart). Endpoint-endpointnya sama persis kayak yang dipake
// versi web (lihat server/auth-server.js) — server SAMA SEKALI nggak
// diubah buat app native ini.
const String kBaseUrl = "https://moscow-karl-wednesday-saying.trycloudflare.com";

class LoginResult {
  final bool ok;
  final String? error; // INVALID_CREDENTIALS | EXPIRED | PENDING | DISABLED | NETWORK_ERROR
  final Account? account;
  LoginResult({required this.ok, this.error, this.account});
}

class ApiService {
  static const _tokenKey = 'quantx_token';
  String? _token;

  // Token disimpen di SharedPreferences (persisten antar buka-tutup app,
  // sepadan sama localStorage di versi web) supaya user yang udah pernah
  // login nggak perlu isi password lagi tiap buka app.
  Future<void> _loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<LoginResult> login(String username, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['ok'] == true) {
        await _saveToken(body['token'] as String);
        return LoginResult(ok: true, account: Account.fromJson(body['account']));
      }
      return LoginResult(ok: false, error: body['error'] as String? ?? 'UNKNOWN');
    } catch (_) {
      return LoginResult(ok: false, error: 'NETWORK_ERROR');
    }
  }

  // Dipanggil pas landing screen mau nentuin: skip form login (kalau sesi
  // masih valid) atau tampilin form (kalau enggak) — persis logika yang
  // sama kayak goToLogin()/startApp() di js/app.js versi web.
  Future<LoginResult> fetchMe() async {
    await _loadToken();
    if (_token == null) return LoginResult(ok: false, error: 'NO_TOKEN');
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/api/auth/me'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['ok'] == true) {
        return LoginResult(ok: true, account: Account.fromJson(body['account']));
      }
      return LoginResult(ok: false, error: body['error'] as String? ?? 'INVALID_TOKEN');
    } catch (_) {
      return LoginResult(ok: false, error: 'NETWORK_ERROR');
    }
  }

  Future<void> logout() async {
    await _loadToken();
    try {
      await http.post(
        Uri.parse('$kBaseUrl/api/auth/logout'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Nggak masalah kalau gagal — token tetap dihapus lokal di bawah.
    }
    await clearToken();
  }
}
