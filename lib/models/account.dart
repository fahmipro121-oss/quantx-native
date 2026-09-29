// Bentuk data ini mengikuti persis apa yang dibalikin server
// (server/lib/accounts.js -> publicView), supaya kalau field baru
// ditambah di backend suatu saat, app ini nggak crash — field yang nggak
// dikenal cukup diabaikan, bukan bikin error parse.
class Account {
  final String username;
  final String role; // MEMBER | RESELLER | PARTNER | OWNER
  final String liveStatus; // ACTIVE | EXPIRED | PENDING | DISABLED
  final String? package;
  final String? expiresAt;

  Account({
    required this.username,
    required this.role,
    required this.liveStatus,
    this.package,
    this.expiresAt,
  });

  factory Account.fromJson(Map<String, dynamic> j) {
    return Account(
      username: j['username'] as String? ?? '-',
      role: j['role'] as String? ?? 'MEMBER',
      liveStatus: j['liveStatus'] as String? ?? 'ACTIVE',
      package: j['package'] as String?,
      expiresAt: j['expiresAt'] as String?,
    );
  }

  // Label yang ditampilin di UI, sama persis kayak versi web
  // (ORION_ROLE_LABEL di js/orionUi.js).
  String get roleLabel {
    switch (role) {
      case 'OWNER':
        return 'OWNER';
      case 'MEMBER':
        return 'VIP';
      case 'RESELLER':
        return 'EXECUTIVE';
      case 'PARTNER':
        return 'EXECUTIVE ELITE';
      default:
        return role;
    }
  }
}
