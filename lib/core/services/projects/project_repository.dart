import '../../models/project_models.dart';

abstract class ProjectRepository {
  Future<List<WorkspaceSummary>> getWorkspaces();
  Future<List<ProjectSummary>> getProjects(String workspaceId);
  Future<ProjectDetail?> getProjectDetail(String projectId);
  Future<ProjectDetail> createProject({
    required String workspaceId,
    required String goal,
  });
}
