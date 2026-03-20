enum ProjectStatus { draft, planning, running, completed, failed }

enum TaskStatus { queued, inProgress, completed, failed, blocked }

enum ArtifactType { executionPlan, prd, schema, ui, code, qa }

enum ArtifactStatus { pending, generating, ready, partial, failed }

class WorkspaceSummary {
  const WorkspaceSummary({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.projectCount,
  });

  final String id;
  final String name;
  final String roleLabel;
  final int projectCount;
}

class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.goal,
    required this.status,
    required this.updatedAt,
    required this.totalArtifacts,
    required this.completedTasks,
    required this.totalTasks,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String goal;
  final ProjectStatus status;
  final DateTime updatedAt;
  final int totalArtifacts;
  final int completedTasks;
  final int totalTasks;
}

class ExecutionPlanStep {
  const ExecutionPlanStep({
    required this.id,
    required this.title,
    required this.agentId,
    required this.description,
    required this.status,
  });

  final String id;
  final String title;
  final String agentId;
  final String description;
  final TaskStatus status;
}

class WorkflowTask {
  const WorkflowTask({
    required this.id,
    required this.agentId,
    required this.title,
    required this.description,
    required this.status,
    required this.outputArtifactIds,
    this.errorMessage,
  });

  final String id;
  final String agentId;
  final String title;
  final String description;
  final TaskStatus status;
  final List<String> outputArtifactIds;
  final String? errorMessage;
}

class ArtifactSummary {
  const ArtifactSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.format,
    required this.status,
    required this.preview,
    required this.updatedAt,
  });

  final String id;
  final ArtifactType type;
  final String title;
  final String format;
  final ArtifactStatus status;
  final String preview;
  final DateTime updatedAt;
}

class ConversationLogEntry {
  const ConversationLogEntry({
    required this.id,
    required this.speaker,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String speaker;
  final String message;
  final DateTime createdAt;
}

class ToolRunSummary {
  const ToolRunSummary({
    required this.id,
    required this.toolName,
    required this.status,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String toolName;
  final TaskStatus status;
  final String summary;
  final DateTime createdAt;
}

class ProjectDetail {
  const ProjectDetail({
    required this.summary,
    required this.executionPlan,
    required this.tasks,
    required this.artifacts,
    required this.logs,
    required this.toolRuns,
  });

  final ProjectSummary summary;
  final List<ExecutionPlanStep> executionPlan;
  final List<WorkflowTask> tasks;
  final List<ArtifactSummary> artifacts;
  final List<ConversationLogEntry> logs;
  final List<ToolRunSummary> toolRuns;
}

extension ProjectStatusLabel on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.draft:
        return 'Draft';
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.running:
        return 'Running';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.failed:
        return 'Failed';
    }
  }
}

extension TaskStatusLabel on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.queued:
        return 'Queued';
      case TaskStatus.inProgress:
        return 'Running';
      case TaskStatus.completed:
        return 'Done';
      case TaskStatus.failed:
        return 'Failed';
      case TaskStatus.blocked:
        return 'Blocked';
    }
  }
}

extension ArtifactTypeLabel on ArtifactType {
  String get label {
    switch (this) {
      case ArtifactType.executionPlan:
        return 'Execution Plan';
      case ArtifactType.prd:
        return 'PRD';
      case ArtifactType.schema:
        return 'Schema';
      case ArtifactType.ui:
        return 'UI';
      case ArtifactType.code:
        return 'Code';
      case ArtifactType.qa:
        return 'QA';
    }
  }
}

extension ArtifactStatusLabel on ArtifactStatus {
  String get label {
    switch (this) {
      case ArtifactStatus.pending:
        return 'Pending';
      case ArtifactStatus.generating:
        return 'Generating';
      case ArtifactStatus.ready:
        return 'Ready';
      case ArtifactStatus.partial:
        return 'Partial';
      case ArtifactStatus.failed:
        return 'Failed';
    }
  }
}
