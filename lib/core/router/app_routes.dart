class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String projects = '/projects';
  static const String settings = '/settings';

  static String projectDetail(String id) => '/projects/$id';
  static String artifactViewer(String projectId, String artifactId) =>
      '/projects/$projectId/artifacts/$artifactId';
}
