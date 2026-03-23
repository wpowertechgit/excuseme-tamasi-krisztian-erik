class AuthSession {
  const AuthSession({
    required this.token,
    required this.username,
    required this.isAdmin,
  });

  final String token;
  final String username;
  final bool isAdmin;
}
