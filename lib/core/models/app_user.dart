class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isPreview,
  });

  final String id;
  final String email;
  final String displayName;
  final bool isPreview;
}
