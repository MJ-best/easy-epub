import 'package:flutter/material.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../projects/models/project_workflow_models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.projects,
    required this.metrics,
    required this.goalController,
    required this.onGoalChanged,
    required this.onStartWorkflow,
    required this.onOpenProject,
    required this.onDestinationSelected,
    this.statusMessage,
    this.submissionError,
    this.isSubmitting = false,
  });

  final List<ProjectWorkflowData> projects;
  final Map<String, int> metrics;
  final TextEditingController goalController;
  final ValueChanged<String> onGoalChanged;
  final VoidCallback onStartWorkflow;
  final ValueChanged<String> onOpenProject;
  final ValueChanged<int> onDestinationSelected;
  final String? statusMessage;
  final String? submissionError;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeProject = projects.isEmpty ? null : projects.first;

    return AppShell(
      title: 'Dashboard',
      selectedIndex: 0,
      onDestinationSelected: onDestinationSelected,
      actions: [
        IconButton(
            onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
      ],
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Welcome back', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Track goals, agent progress, and artifact readiness from a single workflow view.',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.secondary),
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              statusMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SectionCard(
            title: 'Start a new workflow',
            subtitle:
                'Enter a goal and let the orchestrator create the execution plan.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: goalController,
                  onChanged: onGoalChanged,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Build a Flutter web-first platform that generates PRD, schema, UI, code, and QA artifacts.',
                  ),
                ),
                if (submissionError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    submissionError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: isSubmitting ? null : onStartWorkflow,
                    icon: const Icon(Icons.auto_awesome_motion),
                    label: Text(
                      isSubmitting
                          ? 'Generating plan...'
                          : 'Generate execution plan',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 1100 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.55,
            children: [
              MetricCard(
                  label: 'Active projects',
                  value: '${metrics['activeProjects'] ?? 0}',
                  icon: Icons.folder_outlined),
              MetricCard(
                  label: 'Completed tasks',
                  value: '${metrics['completedTasks'] ?? 0}',
                  icon: Icons.play_circle_outline),
              MetricCard(
                  label: 'Artifacts ready',
                  value: '${metrics['artifacts'] ?? 0}',
                  icon: Icons.description_outlined),
              MetricCard(
                  label: 'Total tasks',
                  value: '${metrics['totalTasks'] ?? 0}',
                  icon: Icons.error_outline),
            ],
          ),
          const SizedBox(height: 24),
          if (activeProject != null)
            ResponsiveSplit(
              left: SectionCard(
                title: 'Current execution',
                subtitle: activeProject.name,
                trailing: StatusBadge(
                  label: activeProject.status.label,
                  backgroundColor:
                      statusColor(activeProject.status, theme.colorScheme)
                          .withValues(alpha: 0.12),
                  foregroundColor:
                      statusColor(activeProject.status, theme.colorScheme),
                ),
                child: _CurrentProjectSummary(project: activeProject),
              ),
              right: SectionCard(
                title: 'Agent activity',
                subtitle: 'Most recent execution signals',
                child: _AgentActivityList(project: activeProject),
              ),
            )
          else
            SectionCard(
              title: 'No workflows yet',
              subtitle:
                  'Start with a project goal to create the first pipeline.',
              child: Text(
                'The orchestrator will create the execution plan after you submit a goal.',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Recent projects',
            subtitle: 'Workspace-wide view of active workstreams',
            child: projects.isEmpty
                ? Text(
                    'No projects have been created in this workspace yet.',
                    style: theme.textTheme.bodyMedium,
                  )
                : Column(
                    children: projects
                        .map(
                          (project) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  statusColor(project.status, theme.colorScheme)
                                      .withValues(alpha: 0.12),
                              foregroundColor: statusColor(
                                  project.status, theme.colorScheme),
                              child: const Icon(Icons.work_outline),
                            ),
                            title: Text(project.name),
                            subtitle: Text(project.goal,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: TextButton(
                              onPressed: () => onOpenProject(project.id),
                              child: const Text('Open'),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class ResponsiveSplit extends StatelessWidget {
  const ResponsiveSplit({required this.left, required this.right, super.key});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              left,
              const SizedBox(height: 16),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _CurrentProjectSummary extends StatelessWidget {
  const _CurrentProjectSummary({required this.project});

  final ProjectWorkflowData project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(project.goal, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: project.progress),
        const SizedBox(height: 8),
        Text('${(project.progress * 100).round()}% complete',
            style: theme.textTheme.labelLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryChip(label: 'Plan steps ${project.totalSteps}'),
            _SummaryChip(label: 'Completed ${project.completedSteps}'),
            _SummaryChip(label: 'Workspace ${project.workspaceName}'),
          ],
        ),
      ],
    );
  }
}

class _AgentActivityList extends StatelessWidget {
  const _AgentActivityList({required this.project});

  final ProjectWorkflowData project;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: project.agents
          .map(
            (agent) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  CircleAvatar(child: Text(agent.role.label.substring(0, 1))),
              title: Text(agent.name),
              subtitle: Text(agent.capabilities.join(' - ')),
              trailing: Text(agent.status),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
