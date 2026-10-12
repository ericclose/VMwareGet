class AuthSession {
  final String email;
  final String displayName;
  final String sessionToken;
  final String? cookieJar;
  final String? csrfToken;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isExportComplianceVerified;

  const AuthSession({
    required this.email,
    required this.displayName,
    required this.sessionToken,
    this.cookieJar,
    this.csrfToken,
    required this.createdAt,
    required this.expiresAt,
    this.isExportComplianceVerified = true,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'sessionToken': sessionToken,
        'cookieJar': cookieJar,
        'csrfToken': csrfToken,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isExportComplianceVerified': isExportComplianceVerified,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawToken = json['sessionToken'] as String? ?? '';
    final rawCookieJar = json['cookieJar'] as String?;
    final rawCsrf = json['csrfToken'] as String?;
    return AuthSession(
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? 'Broadcom User',
      sessionToken: rawToken.replaceAll('\u0000', ''),
      cookieJar: rawCookieJar?.replaceAll('\u0000', ''),
      csrfToken: rawCsrf?.replaceAll('\u0000', ''),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isExportComplianceVerified:
          json['isExportComplianceVerified'] as bool? ?? true,
    );
  }
}
