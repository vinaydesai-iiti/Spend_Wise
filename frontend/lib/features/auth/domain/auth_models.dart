/// The signed-in user, as returned inside every auth response.
class AppUser {
  final String id;
  final String name;
  final String email;

  const AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

/// What the backend returns on a successful `POST /auth/login`.
///
/// [accessToken] is the JWT the server issues on login. Every other API
/// call attaches it as `Authorization: Bearer <accessToken>` — see the
/// auth interceptor in `core/network/api_client.dart`.
class AuthResult {
  final String accessToken;
  final String? refreshToken;
  final AppUser user;

  const AuthResult({required this.accessToken, this.refreshToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
