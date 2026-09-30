import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/chat_message.dart';

// GANTI baris ini kalau link Cloudflare Tunnel-nya berubah (misal abis
// Termux di-restart). Endpoint-endpointnya sama persis kayak yang dipake
// versi web (lihat server/auth-server.js) — server SAMA SEKALI nggak
// diubah buat app native ini.
const String kBaseUrl = "https://regulations-direction-memphis-sometimes.trycloudflare.com";

class OrionResult {
  final bool ok;
  final String? reply;
  final String? error; // RATE_LIMITED | NOT_CONFIGURED | UPSTREAM_ERROR | NETWORK_ERROR
  final int? unlockAt; // epoch ms, cuma keisi kalau error == RATE_LIMITED
  OrionResult({required this.ok, this.reply, this.error, this.unlockAt});
}

class LoginResult {
  final bool ok;
  final String? error; // INVALID_CREDENTIALS | EXPIRED | PENDING | DISABLED | NETWORK_ERROR
  final Account? account;
  LoginResult({required this.ok, this.error, this.account});
}

class ApiService {
  static const _tokenKey = 'quantx_token';
  static const _baseUrlKey = 'quantx_base_url';
  String? _token;
  String? _baseUrl;

  // URL server dipisah dari kode: defaultnya kBaseUrl di atas, tapi bisa
  // ditimpa/diganti langsung dari dalam app (layar Setting Server) dan
  // kesimpen persisten. Ini biar tiap kali link Cloudflare Tunnel berubah
  // (misal abis Termux di-restart), nggak perlu build ulang + install
  // ulang APK — tinggal buka app, ganti link-nya, langsung kepake.
  Future<String> get baseUrl async {
    if (_baseUrl != null) return _baseUrl!;
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? kBaseUrl;
    return _baseUrl!;
  }

  Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), ''); // buang trailing slash
    _baseUrl = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, trimmed);
  }

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
      final base = await baseUrl;
      final res = await http
          .post(
            Uri.parse('$base/api/auth/login'),
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
      final base = await baseUrl;
      final res = await http.get(
        Uri.parse('$base/api/auth/me'),
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

  // Endpoint & bentuk request ini sama persis kayak yang dipake versi web
  // (lihat POST /api/orion/chat di server/auth-server.js dan pemanggilnya
  // di js/app.js) — server nggak tau/nggak peduli yang manggil native
  // atau web, cukup Authorization: Bearer token yang sama.
  Future<OrionResult> sendOrionChat({
    required String message,
    String? symbol,
    List<ChatMessage> history = const [],
  }) async {
    await _loadToken();
    try {
      final base = await baseUrl;
      final res = await http
          .post(
            Uri.parse('$base/api/orion/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({
              'message': message,
              'symbol': symbol,
              'history': history.map((m) => m.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 90)); // mode /dalam & /panel bisa lama, lihat brain.py
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 429) {
        return OrionResult(ok: false, error: 'RATE_LIMITED', unlockAt: body['unlockAt'] as int?);
      }
      if (body['ok'] == true) {
        return OrionResult(ok: true, reply: body['reply'] as String?);
      }
      return OrionResult(ok: false, error: body['error'] as String? ?? 'UPSTREAM_ERROR');
    } catch (_) {
      return OrionResult(ok: false, error: 'NETWORK_ERROR');
    }
  }

  Future<void> logout() async {
    await _loadToken();
    try {
      final base = await baseUrl;
      await http.post(
        Uri.parse('$base/api/auth/logout'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Nggak masalah kalau gagal — token tetap dihapus lokal di bawah.
    }
    await clearToken();
  }
}
