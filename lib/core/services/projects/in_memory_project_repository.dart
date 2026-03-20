import '../../config/app_constants.dart';
import '../../models/agent_models.dart';
import '../../models/project_models.dart';
import 'project_repository.dart';

class InMemoryProjectRepository implements ProjectRepository {
  InMemoryProjectRepository()
      : _workspaces = const [
          WorkspaceSummary(
            id: AppConstants.defaultWorkspaceId,
            name: 'Core Product Studio',
            roleLabel: 'Owner',
            projectCount: 2,
          ),
        ],
        _projects = [
          _seedSummary,
          _qaSummary,
        ] {
    _details = {
      _seedDetail.summary.id: _seedDetail,
      _qaDetail.summary.id: _qaDetail,
    };
  }

  static final ProjectSummary _seedSummary = ProjectSummary(
    id: 'project-multi-agent-mvp',
    workspaceId: AppConstants.defaultWorkspaceId,
    name: 'Multi-Agent Vibe Coding MVP',
    goal: 'Build a Flutter web-first platform where multiple agents produce PRD, schema, UI, code, and QA artifacts from a single goal.',
    status: ProjectStatus.running,
    updatedAt: DateTime(2026, 3, 20, 17, 40),
    totalArtifacts: 5,
    completedTasks: 4,
    totalTasks: 5,
  );

  static final ProjectSummary _qaSummary = ProjectSummary(
    id: 'project-analytics-extension',
    workspaceId: AppConstants.defaultWorkspaceId,
    name: 'Analytics Visibility Upgrade',
    goal: 'Add run analytics and task throughput metrics to the project workflow view.',
    status: ProjectStatus.planning,
    updatedAt: DateTime(2026, 3, 19, 10, 10),
    totalArtifacts: 2,
    completedTasks: 1,
    totalTasks: 4,
  );

  static const List<AgentNode> catalog = [
    AgentNode(
      id: 'orchestrator',
      name: 'Orchestrator',
      stage: AgentStage.orchestration,
      responsibility: 'Plans workflow, assigns tasks, prevents duplicate execution.',
      outputType: 'execution_plan',
    ),
    AgentNode(
      id: 'pm',
      name: 'PM Agent',
      stage: AgentStage.planning,
      responsibility: 'Produces PRD, feature set, user flow.',
      outputType: 'prd',
    ),
    AgentNode(
      id: 'system_designer',
      name: 'System Designer',
      stage: AgentStage.architecture,
      responsibility: 'Designs schema, RLS, and backend model.',
      outputType: 'schema',
    ),
    AgentNode(
      id: 'flutter',
      name: 'Flutter Agent',
      stage: AgentStage.implementation,
      responsibility: 'Creates UI structure, routes, and client code.',
      outputType: 'ui_code',
    ),
    AgentNode(
      id: 'qa',
      name: 'QA Agent',
      stage: AgentStage.validation,
      responsibility: 'Checks coverage, edge cases, and release risk.',
      outputType: 'qa_report',
    ),
  ];

  final List<WorkspaceSummary> _workspaces;
  final List<ProjectSummary> _projects;
  late final Map<String, ProjectDetail> _details;

  static final ProjectDetail _seedDetail = ProjectDetail(
    summary: _seedSummary,
    executionPlan: [
      ExecutionPlanStep(
        id: 'plan-1',
        title: 'Frame execution plan',
        agentId: 'orchestrator',
        description: 'Validate goal, create workflow stages, and sequence agent handoffs.',
        status: TaskStatus.completed,
      ),
      ExecutionPlanStep(
        id: 'plan-2',
        title: 'Draft PRD and user flow',
        agentId: 'pm',
        description: 'Produce product framing, user journeys, and release scope.',
        status: TaskStatus.completed,
      ),
      ExecutionPlanStep(
        id: 'plan-3',
        title: 'Design Supabase model',
        agentId: 'system_designer',
        description: 'Author tables, RLS, constraints, and ownership rules.',
        status: TaskStatus.completed,
      ),
      ExecutionPlanStep(
        id: 'plan-4',
        title: 'Build Flutter web shell',
        agentId: 'flutter',
        description: 'Generate routing, workflow UI, and artifact viewers.',
        status: TaskStatus.inProgress,
      ),
      ExecutionPlanStep(
        id: 'plan-5',
        title: 'Run QA validation',
        agentId: 'qa',
        description: 'Check edge cases, partial generation, and permission failures.',
        status: TaskStatus.queued,
      ),
    ],
    tasks: [
      WorkflowTask(
        id: 'task-1',
        agentId: 'orchestrator',
        title: 'Plan execution graph',
        description: 'Create step graph and ownership map.',
        status: TaskStatus.completed,
        outputArtifactIds: ['artifact-plan'],
      ),
      WorkflowTask(
        id: 'task-2',
        agentId: 'pm',
        title: 'Generate PRD',
        description: 'Build user flow, feature list, and release scope.',
        status: TaskStatus.completed,
        outputArtifactIds: ['artifact-prd'],
      ),
      WorkflowTask(
        id: 'task-3',
        agentId: 'system_designer',
        title: 'Design data model',
        description: 'Create schema and RLS package for Supabase.',
        status: TaskStatus.completed,
        outputArtifactIds: ['artifact-schema'],
      ),
      WorkflowTask(
        id: 'task-4',
        agentId: 'flutter',
        title: 'Ship workflow UI',
        description: 'Implement responsive workflow-first shell.',
        status: TaskStatus.inProgress,
        outputArtifactIds: ['artifact-ui', 'artifact-code'],
      ),
      WorkflowTask(
        id: 'task-5',
        agentId: 'qa',
        title: 'Validate release',
        description: 'Review missing cases and fallback flows.',
        status: TaskStatus.queued,
        outputArtifactIds: ['artifact-qa'],
      ),
    ],
    artifacts: [
      ArtifactSummary(
        id: 'artifact-plan',
        type: ArtifactType.executionPlan,
        title: 'Execution Plan',
        format: 'json',
        status: ArtifactStatus.ready,
        preview: 'Stage graph with dedupe and retry rules.',
        updatedAt: DateTime(2026, 3, 20, 17, 11),
      ),
      ArtifactSummary(
        id: 'artifact-prd',
        type: ArtifactType.prd,
        title: 'PRD',
        format: 'md',
        status: ArtifactStatus.ready,
        preview: 'User roles, workspace flow, project lifecycle.',
        updatedAt: DateTime(2026, 3, 20, 17, 16),
      ),
      ArtifactSummary(
        id: 'artifact-schema',
        type: ArtifactType.schema,
        title: 'Supabase Schema',
        format: 'sql',
        status: ArtifactStatus.ready,
        preview: 'RLS-first schema with workspace scoped ownership.',
        updatedAt: DateTime(2026, 3, 20, 17, 21),
      ),
      ArtifactSummary(
        id: 'artifact-ui',
        type: ArtifactType.ui,
        title: 'UI Spec',
        format: 'dart',
        status: ArtifactStatus.generating,
        preview: 'Responsive workflow view and artifact timeline.',
        updatedAt: DateTime(2026, 3, 20, 17, 26),
      ),
      ArtifactSummary(
        id: 'artifact-code',
        type: ArtifactType.code,
        title: 'Flutter Skeleton',
        format: 'dart',
        status: ArtifactStatus.partial,
        preview: 'Routing and providers shipped, settings flow pending.',
        updatedAt: DateTime(2026, 3, 20, 17, 34),
      ),
      ArtifactSummary(
        id: 'artifact-qa',
        type: ArtifactType.qa,
        title: 'QA Review',
        format: 'md',
        status: ArtifactStatus.pending,
        preview: 'Waiting for Flutter output to finish.',
        updatedAt: DateTime(2026, 3, 20, 17, 34),
      ),
    ],
    logs: [
      ConversationLogEntry(
        id: 'log-1',
        speaker: 'system',
        message: 'Goal accepted. Duplicate task check passed.',
        createdAt: DateTime(2026, 3, 20, 17, 8),
      ),
      ConversationLogEntry(
        id: 'log-2',
        speaker: 'orchestrator',
        message: 'Split run into planning, backend, client, and QA stages.',
        createdAt: DateTime(2026, 3, 20, 17, 10),
      ),
      ConversationLogEntry(
        id: 'log-3',
        speaker: 'flutter',
        message: 'Workflow shell is rendering. Artifact viewer fallback added for partial output.',
        createdAt: DateTime(2026, 3, 20, 17, 33),
      ),
    ],
    toolRuns: [
      ToolRunSummary(
        id: 'tool-1',
        toolName: 'schema_compiler',
        status: TaskStatus.completed,
        summary: 'Validated foreign keys and RLS coverage.',
        createdAt: DateTime(2026, 3, 20, 17, 22),
      ),
      ToolRunSummary(
        id: 'tool-2',
        toolName: 'flutter_builder',
        status: TaskStatus.inProgress,
        summary: 'Building workflow shell and artifact cards.',
        createdAt: DateTime(2026, 3, 20, 17, 30),
      ),
    ],
  );

  static final ProjectDetail _qaDetail = ProjectDetail(
    summary: _qaSummary,
    executionPlan: [
      ExecutionPlanStep(
        id: 'analytics-plan-1',
        title: 'Review current telemetry',
        agentId: 'orchestrator',
        description: 'Check current visibility for project and task metrics.',
        status: TaskStatus.completed,
      ),
      ExecutionPlanStep(
        id: 'analytics-plan-2',
        title: 'Define metrics',
        agentId: 'pm',
        description: 'Choose throughput, failure rate, and retry count KPIs.',
        status: TaskStatus.inProgress,
      ),
      ExecutionPlanStep(
        id: 'analytics-plan-3',
        title: 'QA coverage mapping',
        agentId: 'qa',
        description: 'Find permission and partial generation cases.',
        status: TaskStatus.queued,
      ),
    ],
    tasks: [
      WorkflowTask(
        id: 'analytics-task-1',
        agentId: 'orchestrator',
        title: 'Map telemetry gaps',
        description: 'Inspect missing artifact and tool_run metrics.',
        status: TaskStatus.completed,
        outputArtifactIds: ['analytics-artifact-plan'],
      ),
      WorkflowTask(
        id: 'analytics-task-2',
        agentId: 'pm',
        title: 'Define dashboards',
        description: 'Specify operator and project owner views.',
        status: TaskStatus.inProgress,
        outputArtifactIds: ['analytics-artifact-prd'],
      ),
    ],
    artifacts: [
      ArtifactSummary(
        id: 'analytics-artifact-plan',
        type: ArtifactType.executionPlan,
        title: 'Metrics Plan',
        format: 'json',
        status: ArtifactStatus.ready,
        preview: 'Telemetry dimensions and aggregation plan.',
        updatedAt: DateTime(2026, 3, 19, 9, 50),
      ),
      ArtifactSummary(
        id: 'analytics-artifact-prd',
        type: ArtifactType.prd,
        title: 'Analytics Spec',
        format: 'md',
        status: ArtifactStatus.generating,
        preview: 'Dashboard requirements with project throughput views.',
        updatedAt: DateTime(2026, 3, 19, 10, 4),
      ),
    ],
    logs: [
      ConversationLogEntry(
        id: 'analytics-log-1',
        speaker: 'pm',
        message: 'Need a compact dashboard for workspace leads.',
        createdAt: DateTime(2026, 3, 19, 10, 0),
      ),
    ],
    toolRuns: [
      ToolRunSummary(
        id: 'analytics-tool-1',
        toolName: 'metrics_snapshot',
        status: TaskStatus.completed,
        summary: 'Collected baseline throughput from last 30 runs.',
        createdAt: DateTime(2026, 3, 19, 9, 46),
      ),
    ],
  );

  @override
  Future<List<WorkspaceSummary>> getWorkspaces() async {
    return _workspaces;
  }

  @override
  Future<List<ProjectSummary>> getProjects(String workspaceId) async {
    return _projects.where((project) => project.workspaceId == workspaceId).toList();
  }

  @override
  Future<ProjectDetail?> getProjectDetail(String projectId) async {
    return _details[projectId];
  }

  @override
  Future<ProjectDetail> createProject({
    required String workspaceId,
    required String goal,
  }) async {
    final trimmedGoal = goal.trim();
    final timestamp = DateTime.now();
    final id = 'project-${timestamp.microsecondsSinceEpoch}';
    final title = _deriveTitle(trimmedGoal);

    final detail = ProjectDetail(
      summary: ProjectSummary(
        id: id,
        workspaceId: workspaceId,
        name: title,
        goal: trimmedGoal,
        status: ProjectStatus.planning,
        updatedAt: timestamp,
        totalArtifacts: 5,
        completedTasks: 0,
        totalTasks: 5,
      ),
      executionPlan: [
        ExecutionPlanStep(
          id: '$id-plan-1',
          title: 'Validate goal and form plan',
          agentId: 'orchestrator',
          description: 'Create workflow graph, dedupe rules, and stage dependencies.',
          status: TaskStatus.inProgress,
        ),
        ExecutionPlanStep(
          id: '$id-plan-2',
          title: 'Write PRD',
          agentId: 'pm',
          description: 'Generate product framing, features, and user flow.',
          status: TaskStatus.queued,
        ),
        ExecutionPlanStep(
          id: '$id-plan-3',
          title: 'Design Supabase backend',
          agentId: 'system_designer',
          description: 'Author schema, foreign keys, and RLS.',
          status: TaskStatus.queued,
        ),
        ExecutionPlanStep(
          id: '$id-plan-4',
          title: 'Assemble Flutter shell',
          agentId: 'flutter',
          description: 'Build responsive workflow UI and artifact viewer.',
          status: TaskStatus.queued,
        ),
        ExecutionPlanStep(
          id: '$id-plan-5',
          title: 'Run QA checks',
          agentId: 'qa',
          description: 'Validate edge cases, retries, and permission violations.',
          status: TaskStatus.queued,
        ),
      ],
      tasks: [
        WorkflowTask(
          id: '$id-task-1',
          agentId: 'orchestrator',
          title: 'Seed execution plan',
          description: 'Turn project goal into stage-based tasks.',
          status: TaskStatus.inProgress,
          outputArtifactIds: ['$id-artifact-plan'],
        ),
      ],
      artifacts: [
        ArtifactSummary(
          id: '$id-artifact-plan',
          type: ArtifactType.executionPlan,
          title: 'Execution Plan',
          format: 'json',
          status: ArtifactStatus.generating,
          preview: 'Orchestrator is generating an execution plan.',
          updatedAt: timestamp,
        ),
        ArtifactSummary(
          id: '$id-artifact-prd',
          type: ArtifactType.prd,
          title: 'PRD',
          format: 'md',
          status: ArtifactStatus.pending,
          preview: 'Waiting for PM agent.',
          updatedAt: timestamp,
        ),
        ArtifactSummary(
          id: '$id-artifact-schema',
          type: ArtifactType.schema,
          title: 'Schema',
          format: 'sql',
          status: ArtifactStatus.pending,
          preview: 'Waiting for System Designer.',
          updatedAt: timestamp,
        ),
        ArtifactSummary(
          id: '$id-artifact-ui',
          type: ArtifactType.ui,
          title: 'UI Blueprint',
          format: 'dart',
          status: ArtifactStatus.pending,
          preview: 'Waiting for Flutter agent.',
          updatedAt: timestamp,
        ),
        ArtifactSummary(
          id: '$id-artifact-qa',
          type: ArtifactType.qa,
          title: 'QA Review',
          format: 'md',
          status: ArtifactStatus.pending,
          preview: 'Waiting for QA agent.',
          updatedAt: timestamp,
        ),
      ],
      logs: [
        ConversationLogEntry(
          id: '$id-log-1',
          speaker: 'system',
          message: 'Project created. Goal queued for orchestrator review.',
          createdAt: timestamp,
        ),
      ],
      toolRuns: const [],
    );

    _details[id] = detail;
    _projects.insert(0, detail.summary);
    return detail;
  }

  String _deriveTitle(String goal) {
    final compact = goal.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 42) {
      return compact;
    }
    return '${compact.substring(0, 39)}...';
  }
}
