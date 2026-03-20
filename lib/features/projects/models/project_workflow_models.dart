import 'package:flutter/material.dart';

import '../../../core/models/agent_models.dart' as core_agent;
import '../../../core/models/project_models.dart' as core;

enum ProjectStatus { draft, planning, active, review, done, failed }

enum WorkflowStepStatus { queued, running, blocked, complete }

enum AgentRole { orchestrator, pm, systemDesigner, flutter, qa }

enum ArtifactType { executionPlan, prd, schema, ui, code, qa }

enum LogSeverity { info, warning, error }

extension ProjectStatusLabel on ProjectStatus {
  String get label => switch (this) {
        ProjectStatus.draft => 'Draft',
        ProjectStatus.planning => 'Planning',
        ProjectStatus.active => 'Active',
        ProjectStatus.review => 'Review',
        ProjectStatus.done => 'Done',
        ProjectStatus.failed => 'Failed',
      };
}

extension WorkflowStepStatusLabel on WorkflowStepStatus {
  String get label => switch (this) {
        WorkflowStepStatus.queued => 'Queued',
        WorkflowStepStatus.running => 'Running',
        WorkflowStepStatus.blocked => 'Blocked',
        WorkflowStepStatus.complete => 'Complete',
      };
}

extension AgentRoleLabel on AgentRole {
  String get label => switch (this) {
        AgentRole.orchestrator => 'Orchestrator',
        AgentRole.pm => 'PM Agent',
        AgentRole.systemDesigner => 'System Designer',
        AgentRole.flutter => 'Flutter Agent',
        AgentRole.qa => 'QA Agent',
      };
}

extension ArtifactTypeLabel on ArtifactType {
  String get label => switch (this) {
        ArtifactType.executionPlan => 'Execution Plan',
        ArtifactType.prd => 'PRD',
        ArtifactType.schema => 'Schema',
        ArtifactType.ui => 'UI',
        ArtifactType.code => 'Code',
        ArtifactType.qa => 'QA',
      };
}

class WorkflowAgentSummary {
  const WorkflowAgentSummary({
    required this.id,
    required this.role,
    required this.name,
    required this.status,
    required this.capabilities,
  });

  final String id;
  final AgentRole role;
  final String name;
  final String status;
  final List<String> capabilities;
}

class WorkflowStepSummary {
  const WorkflowStepSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.owner,
    required this.status,
    required this.order,
    required this.dependencies,
  });

  final String id;
  final String title;
  final String description;
  final AgentRole owner;
  final WorkflowStepStatus status;
  final int order;
  final List<String> dependencies;
}

class WorkflowArtifactSummary {
  const WorkflowArtifactSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.updatedAt,
    required this.preview,
  });

  final String id;
  final ArtifactType type;
  final String title;
  final String description;
  final DateTime updatedAt;
  final String preview;
}

class WorkflowLogEntry {
  const WorkflowLogEntry({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.severity,
    required this.source,
  });

  final String id;
  final String message;
  final DateTime timestamp;
  final LogSeverity severity;
  final String source;
}

class ProjectWorkflowData {
  const ProjectWorkflowData({
    required this.id,
    required this.name,
    required this.goal,
    required this.workspaceName,
    required this.status,
    required this.progress,
    required this.updatedAt,
    required this.executionPlan,
    required this.agents,
    required this.artifacts,
    required this.logs,
  });

  final String id;
  final String name;
  final String goal;
  final String workspaceName;
  final ProjectStatus status;
  final double progress;
  final DateTime updatedAt;
  final List<WorkflowStepSummary> executionPlan;
  final List<WorkflowAgentSummary> agents;
  final List<WorkflowArtifactSummary> artifacts;
  final List<WorkflowLogEntry> logs;

  int get completedSteps => executionPlan
      .where((step) => step.status == WorkflowStepStatus.complete)
      .length;

  int get totalSteps => executionPlan.length;

  factory ProjectWorkflowData.fromProjectDetail(
    core.ProjectDetail detail, {
    required String workspaceName,
    required List<core_agent.AgentNode> catalog,
  }) {
    return ProjectWorkflowData(
      id: detail.summary.id,
      name: detail.summary.name,
      goal: detail.summary.goal,
      workspaceName: workspaceName,
      status: mapProjectStatus(detail.summary.status),
      progress: detail.summary.totalTasks == 0
          ? 0
          : detail.summary.completedTasks / detail.summary.totalTasks,
      updatedAt: detail.summary.updatedAt,
      executionPlan: [
        for (var i = 0; i < detail.executionPlan.length; i++)
          WorkflowStepSummary(
            id: detail.executionPlan[i].id,
            title: detail.executionPlan[i].title,
            description: detail.executionPlan[i].description,
            owner: mapAgentRole(detail.executionPlan[i].agentId),
            status: mapTaskStatus(detail.executionPlan[i].status),
            order: i + 1,
            dependencies: const [],
          ),
      ],
      agents: [
        for (final agent in catalog)
          WorkflowAgentSummary(
            id: agent.id,
            role: mapAgentRole(agent.id),
            name: agent.name,
            status: _deriveAgentStatus(agent.id, detail.executionPlan),
            capabilities: [agent.responsibility, agent.outputType],
          ),
      ],
      artifacts: [
        for (final artifact in detail.artifacts)
          WorkflowArtifactSummary(
            id: artifact.id,
            type: mapArtifactType(artifact.type),
            title: artifact.title,
            description:
                '${artifact.type.label} · ${artifact.status.label} · ${artifact.format}',
            updatedAt: artifact.updatedAt,
            preview: artifact.preview,
          ),
      ],
      logs: [
        for (final log in detail.logs)
          WorkflowLogEntry(
            id: log.id,
            message: log.message,
            timestamp: log.createdAt,
            severity: LogSeverity.info,
            source: log.speaker,
          ),
        for (final toolRun in detail.toolRuns)
          WorkflowLogEntry(
            id: toolRun.id,
            message: toolRun.summary,
            timestamp: toolRun.createdAt,
            severity: toolRun.status == core.TaskStatus.failed
                ? LogSeverity.error
                : toolRun.status == core.TaskStatus.blocked
                    ? LogSeverity.warning
                    : LogSeverity.info,
            source: toolRun.toolName,
          ),
      ],
    );
  }

  factory ProjectWorkflowData.fromProjectSummary(
    core.ProjectSummary summary, {
    required String workspaceName,
  }) {
    final progress = summary.totalTasks == 0
        ? 0.0
        : summary.completedTasks / summary.totalTasks;
    return ProjectWorkflowData(
      id: summary.id,
      name: summary.name,
      goal: summary.goal,
      workspaceName: workspaceName,
      status: mapProjectStatus(summary.status),
      progress: progress,
      updatedAt: summary.updatedAt,
      executionPlan: const [],
      agents: const [],
      artifacts: const [],
      logs: const [],
    );
  }

  static ProjectWorkflowData demo({
    String id = 'project-001',
    String name = 'Multi-agent MVP',
  }) {
    return ProjectWorkflowData(
      id: id,
      name: name,
      goal:
          'Build a production-ready Flutter + Supabase multi-agent vibe coding MVP',
      workspaceName: 'Core Platform',
      status: ProjectStatus.active,
      progress: 0.64,
      updatedAt: DateTime(2026, 3, 20, 10, 45),
      executionPlan: const [
        WorkflowStepSummary(
          id: 'step-orchestrate',
          title: 'Plan the workflow',
          description:
              'Break the goal into structured tasks and assign ownership.',
          owner: AgentRole.orchestrator,
          status: WorkflowStepStatus.complete,
          order: 1,
          dependencies: [],
        ),
        WorkflowStepSummary(
          id: 'step-prd',
          title: 'Generate PRD',
          description: 'PM agent defines scope, flows, and delivery gates.',
          owner: AgentRole.pm,
          status: WorkflowStepStatus.complete,
          order: 2,
          dependencies: ['step-orchestrate'],
        ),
        WorkflowStepSummary(
          id: 'step-schema',
          title: 'Design backend schema',
          description:
              'System designer prepares Supabase tables and RLS policies.',
          owner: AgentRole.systemDesigner,
          status: WorkflowStepStatus.running,
          order: 3,
          dependencies: ['step-prd'],
        ),
        WorkflowStepSummary(
          id: 'step-ui',
          title: 'Generate UI skeleton',
          description:
              'Flutter agent produces responsive screens and components.',
          owner: AgentRole.flutter,
          status: WorkflowStepStatus.queued,
          order: 4,
          dependencies: ['step-schema'],
        ),
        WorkflowStepSummary(
          id: 'step-qa',
          title: 'Run QA validation',
          description:
              'QA checks missing cases, conflicts, and incomplete artifacts.',
          owner: AgentRole.qa,
          status: WorkflowStepStatus.queued,
          order: 5,
          dependencies: ['step-ui'],
        ),
      ],
      agents: const [
        WorkflowAgentSummary(
          id: 'agent-orchestrator',
          role: AgentRole.orchestrator,
          name: 'Orchestrator',
          status: 'Active',
          capabilities: ['Task routing', 'Plan synthesis', 'Execution control'],
        ),
        WorkflowAgentSummary(
          id: 'agent-pm',
          role: AgentRole.pm,
          name: 'PM Agent',
          status: 'Ready',
          capabilities: ['PRD', 'User flows', 'Scope control'],
        ),
        WorkflowAgentSummary(
          id: 'agent-schema',
          role: AgentRole.systemDesigner,
          name: 'System Designer',
          status: 'Running',
          capabilities: ['Schema design', 'RLS', 'Data modeling'],
        ),
        WorkflowAgentSummary(
          id: 'agent-flutter',
          role: AgentRole.flutter,
          name: 'Flutter Agent',
          status: 'Queued',
          capabilities: [
            'Responsive UI',
            'Feature modules',
            'Reusable widgets'
          ],
        ),
        WorkflowAgentSummary(
          id: 'agent-qa',
          role: AgentRole.qa,
          name: 'QA Agent',
          status: 'Queued',
          capabilities: ['Coverage review', 'Failure cases', 'Artifact checks'],
        ),
      ],
      artifacts: [
        WorkflowArtifactSummary(
          id: 'artifact-prd',
          type: ArtifactType.prd,
          title: 'Product Requirements Document',
          description: 'Workflow-first product scope and user goals.',
          updatedAt: DateTime(2026, 3, 20, 10, 10),
          preview:
              'Multi-agent workflow, not a chat app. Structured artifact generation only.',
        ),
        WorkflowArtifactSummary(
          id: 'artifact-schema',
          type: ArtifactType.schema,
          title: 'Supabase Schema',
          description: 'Tables, relationships, and RLS policies.',
          updatedAt: DateTime(2026, 3, 20, 10, 24),
          preview:
              'profiles, workspaces, projects, tasks, artifacts, tool_runs',
        ),
        WorkflowArtifactSummary(
          id: 'artifact-ui',
          type: ArtifactType.ui,
          title: 'Flutter UI Skeleton',
          description: 'Web-first shell and responsive workflow screens.',
          updatedAt: DateTime(2026, 3, 20, 10, 39),
          preview: 'Dashboard, project detail, artifact viewer, settings',
        ),
      ],
      logs: [
        WorkflowLogEntry(
          id: 'log-1',
          message: 'Goal accepted and execution plan generated.',
          timestamp: DateTime(2026, 3, 20, 10, 05),
          severity: LogSeverity.info,
          source: 'Orchestrator',
        ),
        WorkflowLogEntry(
          id: 'log-2',
          message: 'Schema draft includes default-deny RLS policies.',
          timestamp: DateTime(2026, 3, 20, 10, 22),
          severity: LogSeverity.info,
          source: 'System Designer',
        ),
        WorkflowLogEntry(
          id: 'log-3',
          message: 'UI step is waiting for schema lock to clear.',
          timestamp: DateTime(2026, 3, 20, 10, 41),
          severity: LogSeverity.warning,
          source: 'Flutter Agent',
        ),
      ],
    );
  }

  static List<ProjectWorkflowData> demoProjects() => [
        demo(id: 'project-001', name: 'Multi-agent MVP'),
        ProjectWorkflowData(
          id: 'project-002',
          name: 'Client onboarding flow',
          goal:
              'Convert onboarding requirements into a delivery-ready artifact bundle',
          workspaceName: 'Design Lab',
          status: ProjectStatus.review,
          progress: 0.82,
          updatedAt: DateTime(2026, 3, 19, 18, 20),
          executionPlan: const [],
          agents: const [],
          artifacts: const [],
          logs: const [],
        ),
      ];
}

ProjectStatus mapProjectStatus(core.ProjectStatus status) {
  return switch (status) {
    core.ProjectStatus.draft => ProjectStatus.draft,
    core.ProjectStatus.planning => ProjectStatus.planning,
    core.ProjectStatus.running => ProjectStatus.active,
    core.ProjectStatus.completed => ProjectStatus.done,
    core.ProjectStatus.failed => ProjectStatus.failed,
  };
}

WorkflowStepStatus mapTaskStatus(core.TaskStatus status) {
  return switch (status) {
    core.TaskStatus.queued => WorkflowStepStatus.queued,
    core.TaskStatus.inProgress => WorkflowStepStatus.running,
    core.TaskStatus.completed => WorkflowStepStatus.complete,
    core.TaskStatus.failed => WorkflowStepStatus.blocked,
    core.TaskStatus.blocked => WorkflowStepStatus.blocked,
  };
}

ArtifactType mapArtifactType(core.ArtifactType type) {
  return switch (type) {
    core.ArtifactType.executionPlan => ArtifactType.executionPlan,
    core.ArtifactType.prd => ArtifactType.prd,
    core.ArtifactType.schema => ArtifactType.schema,
    core.ArtifactType.ui => ArtifactType.ui,
    core.ArtifactType.code => ArtifactType.code,
    core.ArtifactType.qa => ArtifactType.qa,
  };
}

AgentRole mapAgentRole(String agentId) {
  switch (agentId) {
    case 'orchestrator':
      return AgentRole.orchestrator;
    case 'pm':
      return AgentRole.pm;
    case 'system_designer':
      return AgentRole.systemDesigner;
    case 'flutter':
      return AgentRole.flutter;
    case 'qa':
      return AgentRole.qa;
    default:
      return AgentRole.orchestrator;
  }
}

String _deriveAgentStatus(
  String agentId,
  List<core.ExecutionPlanStep> steps,
) {
  final matching = steps.where((step) => step.agentId == agentId);
  if (matching.isEmpty) {
    return 'Idle';
  }
  if (matching.any((step) => step.status == core.TaskStatus.inProgress)) {
    return 'Running';
  }
  if (matching.every((step) => step.status == core.TaskStatus.completed)) {
    return 'Done';
  }
  if (matching.any((step) => step.status == core.TaskStatus.failed)) {
    return 'Failed';
  }
  return 'Queued';
}

Color statusColor(ProjectStatus status, ColorScheme scheme) {
  return switch (status) {
    ProjectStatus.draft => scheme.secondary,
    ProjectStatus.planning => scheme.tertiary,
    ProjectStatus.active => scheme.primary,
    ProjectStatus.review => const Color(0xFFB26A00),
    ProjectStatus.done => const Color(0xFF1F7A1F),
    ProjectStatus.failed => scheme.error,
  };
}

Color stepColor(WorkflowStepStatus status, ColorScheme scheme) {
  return switch (status) {
    WorkflowStepStatus.queued => scheme.outline,
    WorkflowStepStatus.running => scheme.primary,
    WorkflowStepStatus.blocked => scheme.error,
    WorkflowStepStatus.complete => const Color(0xFF1F7A1F),
  };
}
