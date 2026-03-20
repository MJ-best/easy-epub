import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/project_models.dart';
import 'project_repository.dart';

class SupabaseProjectRepository implements ProjectRepository {
  SupabaseProjectRepository(this._client);

  final SupabaseClient _client;

  static const List<_AgentSeed> _agentSeeds = [
    _AgentSeed(
      roleId: 'orchestrator',
      kind: 'orchestrator',
      name: 'Orchestrator Agent',
      description:
          'Plans workflow, assigns tasks, and prevents duplicate execution.',
      systemPrompt:
          'Plan the workflow, assign specialist agents, and keep execution state consistent.',
    ),
    _AgentSeed(
      roleId: 'pm',
      kind: 'pm',
      name: 'PM Agent',
      description: 'Generates PRD, feature list, and user flow.',
      systemPrompt:
          'Generate structured product requirements, user flow, and MVP scope.',
    ),
    _AgentSeed(
      roleId: 'system_designer',
      kind: 'system_designer',
      name: 'System Designer Agent',
      description: 'Designs Supabase schema, RLS, and data model.',
      systemPrompt:
          'Design a secure Supabase schema, RLS policies, and entity relationships.',
    ),
    _AgentSeed(
      roleId: 'flutter',
      kind: 'flutter',
      name: 'Flutter Agent',
      description:
          'Creates workflow-first UI structure and Flutter code skeleton.',
      systemPrompt:
          'Generate a Flutter web-first app structure, workflow UI, and implementation skeleton.',
    ),
    _AgentSeed(
      roleId: 'qa',
      kind: 'qa',
      name: 'QA Agent',
      description: 'Validates completeness, risks, and missing edge cases.',
      systemPrompt:
          'Review outputs for gaps, edge cases, and release readiness.',
    ),
  ];

  @override
  Future<List<WorkspaceSummary>> getWorkspaces() async {
    final user = _requireUser();
    await _ensureDefaultWorkspace(user);

    final workspaceRows = _asList(
      await _client
          .from('workspaces')
          .select('id,name,owner_user_id,workspace_members(user_id,role)')
          .order('created_at'),
    );

    if (workspaceRows.isEmpty) {
      return const [];
    }

    final workspaceIds = [
      for (final row in workspaceRows) _asString(_asMap(row)['id']),
    ];
    final projectRows = _asList(
      await _client
          .from('projects')
          .select('workspace_id')
          .inFilter('workspace_id', workspaceIds),
    );

    final projectCounts = <String, int>{};
    for (final row in projectRows) {
      final workspaceId = _asString(_asMap(row)['workspace_id']);
      projectCounts.update(workspaceId, (value) => value + 1,
          ifAbsent: () => 1);
    }

    return [
      for (final row in workspaceRows)
        _mapWorkspaceSummary(_asMap(row), user.id, projectCounts),
    ];
  }

  @override
  Future<List<ProjectSummary>> getProjects(String workspaceId) async {
    final resolvedWorkspaceId = await _resolveWorkspaceId(workspaceId);
    if (resolvedWorkspaceId == null) {
      return const [];
    }

    final projectRows = _asList(
      await _client
          .from('projects')
          .select(
              'id,workspace_id,name,project_goal,status,updated_at,created_at')
          .eq('workspace_id', resolvedWorkspaceId)
          .order('updated_at', ascending: false),
    );

    if (projectRows.isEmpty) {
      return const [];
    }

    final projectIds = [
      for (final row in projectRows) _asString(_asMap(row)['id']),
    ];
    final taskRows = _asList(
      await _client
          .from('tasks')
          .select('project_id,status')
          .inFilter('project_id', projectIds),
    );
    final artifactRows = _asList(
      await _client
          .from('artifacts')
          .select('project_id')
          .inFilter('project_id', projectIds),
    );

    final taskTotals = <String, int>{};
    final completedTasks = <String, int>{};
    for (final row in taskRows) {
      final data = _asMap(row);
      final projectId = _asString(data['project_id']);
      taskTotals.update(projectId, (value) => value + 1, ifAbsent: () => 1);
      if (_mapTaskStatusValue(data['status']) == TaskStatus.completed) {
        completedTasks.update(projectId, (value) => value + 1,
            ifAbsent: () => 1);
      }
    }

    final artifactTotals = <String, int>{};
    for (final row in artifactRows) {
      final projectId = _asString(_asMap(row)['project_id']);
      artifactTotals.update(projectId, (value) => value + 1, ifAbsent: () => 1);
    }

    return [
      for (final row in projectRows)
        _mapProjectSummary(
          _asMap(row),
          totalTasks: taskTotals[_asString(_asMap(row)['id'])] ?? 0,
          completedTasks: completedTasks[_asString(_asMap(row)['id'])] ?? 0,
          totalArtifacts: artifactTotals[_asString(_asMap(row)['id'])] ?? 0,
        ),
    ];
  }

  @override
  Future<ProjectDetail?> getProjectDetail(String projectId) async {
    final projectRow = await _client
        .from('projects')
        .select(
          'id,workspace_id,name,project_goal,status,updated_at,created_at,execution_plan',
        )
        .eq('id', projectId)
        .maybeSingle();

    if (projectRow == null) {
      return null;
    }

    final projectData = _asMap(projectRow);
    final workspaceId = _asString(projectData['workspace_id']);
    final agentRows = _asList(
      await _client
          .from('agents')
          .select('id,kind,name')
          .eq('workspace_id', workspaceId)
          .order('sort_order'),
    );
    final agentsById = {
      for (final row in agentRows)
        _asString(_asMap(row)['id']): _AgentSeed.fromAgentRow(_asMap(row)),
    };

    final taskRows = _asList(
      await _client
          .from('tasks')
          .select(
            'id,assigned_agent_id,kind,title,instruction,status,error_message,step_index',
          )
          .eq('project_id', projectId)
          .order('step_index'),
    );
    final artifactRows = _asList(
      await _client
          .from('artifacts')
          .select(
            'id,task_id,kind,title,mime_type,status,is_partial,partial_reason,content_text,content_json,updated_at,generated_at,created_at',
          )
          .eq('project_id', projectId)
          .order('created_at'),
    );
    final conversationRows = _asList(
      await _client
          .from('conversations')
          .select('id')
          .eq('project_id', projectId)
          .order('created_at'),
    );
    final conversationIds = [
      for (final row in conversationRows) _asString(_asMap(row)['id']),
    ];
    final messageRows = conversationIds.isEmpty
        ? const <Object?>[]
        : _asList(
            await _client
                .from('messages')
                .select(
                  'id,agent_id,sender_type,content,content_json,is_error,created_at',
                )
                .inFilter('conversation_id', conversationIds)
                .order('created_at'),
          );
    final toolRunRows = _asList(
      await _client
          .from('tool_runs')
          .select(
            'id,agent_id,tool_name,status,error_message,response_payload,created_at',
          )
          .eq('project_id', projectId)
          .order('created_at'),
    );

    final artifactsByTaskId = <String, List<String>>{};
    for (final row in artifactRows) {
      final data = _asMap(row);
      final taskId = _nullableString(data['task_id']);
      if (taskId == null) {
        continue;
      }
      artifactsByTaskId.putIfAbsent(taskId, () => <String>[]).add(
            _asString(data['id']),
          );
    }

    final summary = _mapProjectSummary(
      projectData,
      totalTasks: taskRows.length,
      completedTasks: taskRows.where((row) {
        return _mapTaskStatusValue(_asMap(row)['status']) ==
            TaskStatus.completed;
      }).length,
      totalArtifacts: artifactRows.length,
    );

    return ProjectDetail(
      summary: summary,
      executionPlan: _mapExecutionPlan(
        projectData['execution_plan'],
        taskRows,
        agentsById,
      ),
      tasks: [
        for (final row in taskRows)
          _mapWorkflowTask(
            _asMap(row),
            agentsById,
            artifactsByTaskId,
          ),
      ],
      artifacts: [
        for (final row in artifactRows) _mapArtifactSummary(_asMap(row)),
      ],
      logs: [
        for (final row in messageRows)
          _mapConversationLog(_asMap(row), agentsById),
      ],
      toolRuns: [
        for (final row in toolRunRows) _mapToolRunSummary(_asMap(row)),
      ],
    );
  }

  @override
  Future<ProjectDetail> createProject({
    required String workspaceId,
    required String goal,
  }) async {
    final normalizedGoal = goal.trim();
    if (normalizedGoal.isEmpty) {
      throw ArgumentError('Project goal is required.');
    }

    final user = _requireUser();
    final resolvedWorkspaceId = await _resolveWorkspaceId(workspaceId);
    if (resolvedWorkspaceId == null) {
      throw StateError('No workspace is available for project creation.');
    }

    final agentMap = await _ensureWorkspaceAgents(resolvedWorkspaceId, user.id);
    final projectName = _deriveProjectName(normalizedGoal);
    final projectSlug = _buildSlug(projectName);
    final executionPlan = _buildExecutionPlan(normalizedGoal);

    final projectRow = _asMap(
      await _client
          .from('projects')
          .insert({
            'workspace_id': resolvedWorkspaceId,
            'created_by_user_id': user.id,
            'name': projectName,
            'slug': '$projectSlug-${DateTime.now().millisecondsSinceEpoch}',
            'project_goal': normalizedGoal,
            'status': 'planning',
            'execution_plan': executionPlan,
            'execution_plan_generated_at':
                DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single(),
    );
    final projectId = _asString(projectRow['id']);

    final conversationRow = _asMap(
      await _client
          .from('conversations')
          .insert({
            'workspace_id': resolvedWorkspaceId,
            'created_by_user_id': user.id,
            'project_id': projectId,
            'kind': 'workflow',
            'title': '$projectName Workflow',
            'summary': 'Execution pipeline for $projectName',
          })
          .select('id')
          .single(),
    );
    final conversationId = _asString(conversationRow['id']);

    final now = DateTime.now().toUtc();
    final taskRows = [
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'conversation_id': conversationId,
        'assigned_agent_id': agentMap['orchestrator'],
        'kind': 'plan',
        'title': 'Create execution plan',
        'instruction':
            'Break the goal into ordered workflow stages and define handoff rules.',
        'step_index': 0,
        'status': 'completed',
        'started_at': now.toIso8601String(),
        'completed_at': now.toIso8601String(),
        'output_payload': {
          'artifacts': ['execution_plan'],
        },
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'conversation_id': conversationId,
        'assigned_agent_id': agentMap['pm'],
        'kind': 'prd',
        'title': 'Generate PRD',
        'instruction': 'Turn the goal into PRD, feature list, and user flow.',
        'step_index': 1,
        'status': 'queued',
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'conversation_id': conversationId,
        'assigned_agent_id': agentMap['system_designer'],
        'kind': 'schema',
        'title': 'Design Supabase schema',
        'instruction':
            'Define entities, foreign keys, indexes, and RLS policies.',
        'step_index': 2,
        'status': 'queued',
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'conversation_id': conversationId,
        'assigned_agent_id': agentMap['flutter'],
        'kind': 'ui',
        'title': 'Generate workflow UI and code skeleton',
        'instruction':
            'Produce workflow-first Flutter web structure, router, and UI artifacts.',
        'step_index': 3,
        'status': 'queued',
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'conversation_id': conversationId,
        'assigned_agent_id': agentMap['qa'],
        'kind': 'qa',
        'title': 'Run QA validation',
        'instruction':
            'Check missing cases, permission gaps, and partial artifact behavior.',
        'step_index': 4,
        'status': 'queued',
      },
    ];

    final insertedTaskRows = _asList(
      await _client.from('tasks').insert(taskRows).select('id,kind'),
    );
    final taskIdsByKind = {
      for (final row in insertedTaskRows)
        _asString(_asMap(row)['kind']): _asString(_asMap(row)['id']),
    };

    await _client.from('artifacts').insert([
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'task_id': taskIdsByKind['plan'],
        'conversation_id': conversationId,
        'agent_id': agentMap['orchestrator'],
        'kind': 'plan',
        'title': 'Execution Plan',
        'status': 'final',
        'mime_type': 'application/json',
        'content_json': {
          'project_goal': normalizedGoal,
          'stages': executionPlan,
        },
        'generated_at': now.toIso8601String(),
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'task_id': taskIdsByKind['prd'],
        'conversation_id': conversationId,
        'agent_id': agentMap['pm'],
        'kind': 'prd',
        'title': 'PRD',
        'status': 'draft',
        'content_text': 'Pending PM agent execution.',
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'task_id': taskIdsByKind['schema'],
        'conversation_id': conversationId,
        'agent_id': agentMap['system_designer'],
        'kind': 'schema',
        'title': 'Supabase Schema',
        'status': 'draft',
        'content_text': 'Pending System Designer execution.',
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'task_id': taskIdsByKind['ui'],
        'conversation_id': conversationId,
        'agent_id': agentMap['flutter'],
        'kind': 'ui',
        'title': 'UI Spec',
        'status': 'draft',
        'content_text': 'Pending Flutter Agent UI output.',
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'task_id': taskIdsByKind['ui'],
        'conversation_id': conversationId,
        'agent_id': agentMap['flutter'],
        'kind': 'code',
        'title': 'Flutter Skeleton',
        'status': 'draft',
        'content_text': 'Pending Flutter Agent code output.',
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'project_id': projectId,
        'task_id': taskIdsByKind['qa'],
        'conversation_id': conversationId,
        'agent_id': agentMap['qa'],
        'kind': 'qa',
        'title': 'QA Review',
        'status': 'draft',
        'content_text': 'Pending QA validation.',
      },
    ]);

    await _client.from('messages').insert([
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'conversation_id': conversationId,
        'task_id': taskIdsByKind['plan'],
        'agent_id': agentMap['orchestrator'],
        'sender_type': 'system',
        'content': 'Goal accepted. Building workflow plan.',
      },
      {
        'workspace_id': resolvedWorkspaceId,
        'created_by_user_id': user.id,
        'conversation_id': conversationId,
        'task_id': taskIdsByKind['plan'],
        'agent_id': agentMap['orchestrator'],
        'sender_type': 'agent',
        'content':
            'Execution plan created. Specialists are queued for artifact generation.',
      },
    ]);

    await _client.from('tool_runs').insert({
      'workspace_id': resolvedWorkspaceId,
      'created_by_user_id': user.id,
      'project_id': projectId,
      'task_id': taskIdsByKind['plan'],
      'conversation_id': conversationId,
      'agent_id': agentMap['orchestrator'],
      'tool_name': 'workflow_planner',
      'status': 'succeeded',
      'response_payload': {
        'stages': executionPlan.length,
        'project_goal': normalizedGoal,
      },
      'started_at': now.toIso8601String(),
      'finished_at': now.toIso8601String(),
      'duration_ms': 350,
    });

    return (await getProjectDetail(projectId))!;
  }

  WorkspaceSummary _mapWorkspaceSummary(
    Map<String, dynamic> row,
    String currentUserId,
    Map<String, int> projectCounts,
  ) {
    final workspaceId = _asString(row['id']);
    final roleLabel = row['owner_user_id'] == currentUserId
        ? 'Owner'
        : _roleLabelFromMembership(row['workspace_members'], currentUserId);
    return WorkspaceSummary(
      id: workspaceId,
      name: _asString(row['name']),
      roleLabel: roleLabel,
      projectCount: projectCounts[workspaceId] ?? 0,
    );
  }

  ProjectSummary _mapProjectSummary(
    Map<String, dynamic> row, {
    required int totalTasks,
    required int completedTasks,
    required int totalArtifacts,
  }) {
    return ProjectSummary(
      id: _asString(row['id']),
      workspaceId: _asString(row['workspace_id']),
      name: _asString(row['name']),
      goal: _asString(row['project_goal']),
      status: _mapProjectStatusValue(row['status']),
      updatedAt: _parseDateTime(row['updated_at'] ?? row['created_at']),
      totalArtifacts: totalArtifacts,
      completedTasks: completedTasks,
      totalTasks: totalTasks,
    );
  }

  List<ExecutionPlanStep> _mapExecutionPlan(
    Object? executionPlanValue,
    List<Object?> taskRows,
    Map<String, _AgentSeed> agentsById,
  ) {
    final executionPlanRows = _asList(executionPlanValue);
    if (executionPlanRows.isNotEmpty) {
      return [
        for (final row in executionPlanRows)
          ExecutionPlanStep(
            id: _asString(_asMap(row)['id']),
            title: _asString(_asMap(row)['title']),
            agentId: _normalizeRoleId(
                _nullableString(_asMap(row)['agent']) ?? 'orchestrator'),
            description: _asString(_asMap(row)['description']),
            status: _mapTaskStatusValue(_asMap(row)['status']),
          ),
      ];
    }

    return [
      for (final row in taskRows)
        ExecutionPlanStep(
          id: _asString(_asMap(row)['id']),
          title: _asString(_asMap(row)['title']),
          agentId: _agentRoleIdFromTask(_asMap(row), agentsById),
          description: _asString(_asMap(row)['instruction']),
          status: _mapTaskStatusValue(_asMap(row)['status']),
        ),
    ];
  }

  WorkflowTask _mapWorkflowTask(
    Map<String, dynamic> row,
    Map<String, _AgentSeed> agentsById,
    Map<String, List<String>> artifactsByTaskId,
  ) {
    final taskId = _asString(row['id']);
    return WorkflowTask(
      id: taskId,
      agentId: _agentRoleIdFromTask(row, agentsById),
      title: _asString(row['title']),
      description: _asString(row['instruction']),
      status: _mapTaskStatusValue(row['status']),
      outputArtifactIds: artifactsByTaskId[taskId] ?? const [],
      errorMessage: _nullableString(row['error_message']),
    );
  }

  ArtifactSummary _mapArtifactSummary(Map<String, dynamic> row) {
    final preview = _buildArtifactPreview(row);
    final format = _artifactFormat(row['mime_type'], row['kind']);
    final status = _mapArtifactStatusValue(
      row['status'],
      isPartial: row['is_partial'] == true,
    );
    return ArtifactSummary(
      id: _asString(row['id']),
      type: _mapArtifactTypeValue(row['kind']),
      title: _asString(row['title']),
      format: format,
      status: status,
      preview: preview,
      updatedAt: _parseDateTime(
        row['updated_at'] ?? row['generated_at'] ?? row['created_at'],
      ),
    );
  }

  ConversationLogEntry _mapConversationLog(
    Map<String, dynamic> row,
    Map<String, _AgentSeed> agentsById,
  ) {
    final agentId = _nullableString(row['agent_id']);
    final speaker = switch (_asString(row['sender_type'])) {
      'agent' =>
        agentId != null ? (agentsById[agentId]?.roleId ?? 'agent') : 'agent',
      'user' => 'user',
      _ => 'system',
    };
    return ConversationLogEntry(
      id: _asString(row['id']),
      speaker: speaker,
      message: _buildMessagePreview(row),
      createdAt: _parseDateTime(row['created_at']),
    );
  }

  ToolRunSummary _mapToolRunSummary(Map<String, dynamic> row) {
    final summary =
        _nullableString(row['error_message'])?.trim().isNotEmpty == true
            ? _asString(row['error_message'])
            : _summarizeJson(row['response_payload']);
    return ToolRunSummary(
      id: _asString(row['id']),
      toolName: _asString(row['tool_name']),
      status: _mapToolRunStatus(row['status']),
      summary: summary.isEmpty ? 'Tool run completed.' : summary,
      createdAt: _parseDateTime(row['created_at']),
    );
  }

  Future<String?> _resolveWorkspaceId(String workspaceId) async {
    final workspaces = await getWorkspaces();
    if (workspaces.isEmpty) {
      return null;
    }
    if (workspaceId.isNotEmpty) {
      for (final workspace in workspaces) {
        if (workspace.id == workspaceId) {
          return workspaceId;
        }
      }
    }
    return workspaces.first.id;
  }

  Future<String> _ensureDefaultWorkspace(User user) async {
    final existingRows = _asList(
      await _client.from('workspaces').select('id').limit(1),
    );
    if (existingRows.isNotEmpty) {
      return _asString(_asMap(existingRows.first)['id']);
    }

    final workspaceName = _workspaceName(user);
    final workspaceRow = _asMap(
      await _client
          .from('workspaces')
          .insert({
            'owner_user_id': user.id,
            'name': workspaceName,
            'slug': 'workspace-${user.id.substring(0, 8)}',
            'description': 'Personal workspace for $workspaceName',
          })
          .select('id')
          .single(),
    );
    final workspaceId = _asString(workspaceRow['id']);
    await _ensureWorkspaceAgents(workspaceId, user.id);
    return workspaceId;
  }

  Future<Map<String, String>> _ensureWorkspaceAgents(
    String workspaceId,
    String userId,
  ) async {
    final existingRows = _asList(
      await _client
          .from('agents')
          .select('id,kind,name')
          .eq('workspace_id', workspaceId),
    );

    final agentsByKind = <String, String>{
      for (final row in existingRows)
        _asString(_asMap(row)['kind']): _asString(_asMap(row)['id']),
    };

    final missingSeeds = [
      for (final seed in _agentSeeds)
        if (!agentsByKind.containsKey(seed.kind))
          {
            'workspace_id': workspaceId,
            'created_by_user_id': userId,
            'kind': seed.kind,
            'name': seed.name,
            'description': seed.description,
            'system_prompt': seed.systemPrompt,
            'model_hint': 'gpt-5.4-mini',
            'sort_order': _agentSeeds.indexOf(seed),
          },
    ];

    if (missingSeeds.isNotEmpty) {
      final insertedRows = _asList(
        await _client.from('agents').insert(missingSeeds).select('id,kind'),
      );
      for (final row in insertedRows) {
        agentsByKind[_asString(_asMap(row)['kind'])] =
            _asString(_asMap(row)['id']);
      }
    }

    return {
      for (final seed in _agentSeeds)
        seed.roleId: agentsByKind[seed.kind] ?? '',
    };
  }

  List<Map<String, dynamic>> _buildExecutionPlan(String goal) {
    return [
      {
        'id': 'stage-plan',
        'title': 'Plan execution',
        'agent': 'orchestrator',
        'description': 'Validate "$goal" and create the execution pipeline.',
        'status': 'completed',
      },
      {
        'id': 'stage-prd',
        'title': 'Generate PRD',
        'agent': 'pm',
        'description': 'Define product scope, features, and user flow.',
        'status': 'queued',
      },
      {
        'id': 'stage-schema',
        'title': 'Design schema',
        'agent': 'system_designer',
        'description': 'Design Supabase tables, relationships, and RLS rules.',
        'status': 'queued',
      },
      {
        'id': 'stage-ui',
        'title': 'Build workflow UI',
        'agent': 'flutter',
        'description': 'Create the Flutter web shell and artifact views.',
        'status': 'queued',
      },
      {
        'id': 'stage-qa',
        'title': 'Validate output',
        'agent': 'qa',
        'description': 'Check gaps, failures, and partial artifact behavior.',
        'status': 'queued',
      },
    ];
  }

  String _workspaceName(User user) {
    final metadata = user.userMetadata ?? const {};
    final displayName = (metadata['full_name'] ??
            metadata['name'] ??
            user.email?.split('@').first ??
            'Workspace')
        .toString()
        .trim();
    return displayName.isEmpty ? 'Workspace' : '$displayName Workspace';
  }

  String _deriveProjectName(String goal) {
    final compact = goal.trim().replaceAll(RegExp(r'\s+'), ' ');
    final words =
        compact.split(' ').where((word) => word.isNotEmpty).take(6).toList();
    if (words.isEmpty) {
      return 'New Workflow';
    }
    final candidate = words.join(' ');
    return candidate.length > 48
        ? '${candidate.substring(0, 45)}...'
        : candidate;
  }

  String _buildSlug(String input) {
    final value = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '')
        .replaceAll(RegExp(r'-{2,}'), '-');
    return value.isEmpty ? 'workflow' : value;
  }

  String _buildArtifactPreview(Map<String, dynamic> row) {
    final contentText = _nullableString(row['content_text']);
    if (contentText != null && contentText.trim().isNotEmpty) {
      return _trimPreview(contentText);
    }

    final contentJson = row['content_json'];
    if (contentJson is Map && contentJson.isNotEmpty) {
      return _trimPreview(_summarizeJson(contentJson));
    }

    final partialReason = _nullableString(row['partial_reason']);
    if (partialReason != null && partialReason.isNotEmpty) {
      return _trimPreview(partialReason);
    }

    return 'No preview available.';
  }

  String _buildMessagePreview(Map<String, dynamic> row) {
    final content = _nullableString(row['content']);
    if (content != null && content.trim().isNotEmpty) {
      return content;
    }
    return _summarizeJson(row['content_json']);
  }

  String _summarizeJson(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is Map && value.isEmpty) {
      return '';
    }
    if (value is List && value.isEmpty) {
      return '';
    }
    return _trimPreview(jsonEncode(value));
  }

  String _trimPreview(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 160) {
      return compact;
    }
    return '${compact.substring(0, 157)}...';
  }

  String _artifactFormat(Object? mimeType, Object? kind) {
    final value = _nullableString(mimeType);
    if (value == null || value.isEmpty) {
      return _asString(kind);
    }
    if (value.contains('json')) {
      return 'json';
    }
    if (value.contains('markdown')) {
      return 'md';
    }
    if (value.contains('sql')) {
      return 'sql';
    }
    if (value.contains('dart')) {
      return 'dart';
    }
    return value;
  }

  String _roleLabelFromMembership(Object? membershipValue, String userId) {
    final memberships = _asList(membershipValue);
    for (final membership in memberships) {
      final data = _asMap(membership);
      if (_nullableString(data['user_id']) == userId) {
        return _capitalize(_asString(data['role']));
      }
    }
    return 'Member';
  }

  String _agentRoleIdFromTask(
    Map<String, dynamic> taskRow,
    Map<String, _AgentSeed> agentsById,
  ) {
    final agentId = _nullableString(taskRow['assigned_agent_id']);
    if (agentId != null && agentsById.containsKey(agentId)) {
      return agentsById[agentId]!.roleId;
    }
    return switch (_asString(taskRow['kind'])) {
      'plan' => 'orchestrator',
      'prd' => 'pm',
      'schema' => 'system_designer',
      'ui' || 'code' => 'flutter',
      'qa' => 'qa',
      _ => 'orchestrator',
    };
  }

  ProjectStatus _mapProjectStatusValue(Object? status) {
    return switch (_asString(status)) {
      'draft' => ProjectStatus.draft,
      'planning' => ProjectStatus.planning,
      'active' => ProjectStatus.running,
      'completed' => ProjectStatus.completed,
      'archived' => ProjectStatus.completed,
      'blocked' => ProjectStatus.failed,
      _ => ProjectStatus.failed,
    };
  }

  TaskStatus _mapTaskStatusValue(Object? status) {
    return switch (_asString(status)) {
      'completed' || 'succeeded' => TaskStatus.completed,
      'running' => TaskStatus.inProgress,
      'blocked' || 'canceled' => TaskStatus.blocked,
      'failed' => TaskStatus.failed,
      'pending' || 'queued' => TaskStatus.queued,
      _ => TaskStatus.queued,
    };
  }

  ArtifactType _mapArtifactTypeValue(Object? kind) {
    return switch (_asString(kind)) {
      'plan' => ArtifactType.executionPlan,
      'prd' => ArtifactType.prd,
      'schema' => ArtifactType.schema,
      'ui' => ArtifactType.ui,
      'qa' => ArtifactType.qa,
      'code' => ArtifactType.code,
      _ => ArtifactType.code,
    };
  }

  ArtifactStatus _mapArtifactStatusValue(
    Object? status, {
    required bool isPartial,
  }) {
    if (isPartial) {
      return ArtifactStatus.partial;
    }
    return switch (_asString(status)) {
      'draft' => ArtifactStatus.pending,
      'partial' => ArtifactStatus.partial,
      'final' => ArtifactStatus.ready,
      'superseded' => ArtifactStatus.ready,
      'failed' => ArtifactStatus.failed,
      _ => ArtifactStatus.pending,
    };
  }

  TaskStatus _mapToolRunStatus(Object? status) {
    return switch (_asString(status)) {
      'running' => TaskStatus.inProgress,
      'failed' => TaskStatus.failed,
      'canceled' => TaskStatus.blocked,
      'queued' => TaskStatus.queued,
      'succeeded' => TaskStatus.completed,
      _ => TaskStatus.queued,
    };
  }

  String _normalizeRoleId(String roleId) {
    return switch (roleId) {
      'system-designer' => 'system_designer',
      _ => roleId,
    };
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User must be signed in before loading projects.');
    }
    return user;
  }

  List<Object?> _asList(Object? value) {
    if (value is List) {
      return value.cast<Object?>();
    }
    return const <Object?>[];
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value
          .map((key, dynamicValue) => MapEntry(key.toString(), dynamicValue));
    }
    return const <String, dynamic>{};
  }

  String _asString(Object? value) {
    return value?.toString() ?? '';
  }

  String? _nullableString(Object? value) {
    final result = value?.toString();
    if (result == null || result.isEmpty) {
      return null;
    }
    return result;
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  DateTime _parseDateTime(Object? value) {
    final parsed = DateTime.tryParse(_asString(value));
    return parsed ?? DateTime.now();
  }
}

class _AgentSeed {
  const _AgentSeed({
    required this.roleId,
    required this.kind,
    required this.name,
    required this.description,
    required this.systemPrompt,
  });

  factory _AgentSeed.fromAgentRow(Map<String, dynamic> row) {
    final kind = row['kind']?.toString() ?? 'custom';
    return _AgentSeed(
      roleId: switch (kind) {
        'system_designer' => 'system_designer',
        _ => kind,
      },
      kind: kind,
      name: row['name']?.toString() ?? kind,
      description: '',
      systemPrompt: '',
    );
  }

  final String roleId;
  final String kind;
  final String name;
  final String description;
  final String systemPrompt;
}
