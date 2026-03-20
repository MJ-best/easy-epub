import 'package:flutter/material.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/project_workflow_models.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({
    super.key,
    required this.projects,
    required this.onNewProject,
    required this.onOpenProject,
    required this.onDestinationSelected,
  });

  final List<ProjectWorkflowData> projects;
  final VoidCallback onNewProject;
  final ValueChanged<String> onOpenProject;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'Projects',
      selectedIndex: 1,
      onDestinationSelected: onDestinationSelected,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search projects by goal, workspace, or status',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onNewProject,
                icon: const Icon(Icons.add),
                label: const Text('New project'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilterChip(
                  label: const Text('All'), selected: true, onSelected: (_) {}),
              FilterChip(
                  label: const Text('Active'),
                  selected: false,
                  onSelected: (_) {}),
              FilterChip(
                  label: const Text('Review'),
                  selected: false,
                  onSelected: (_) {}),
              FilterChip(
                  label: const Text('Done'),
                  selected: false,
                  onSelected: (_) {}),
            ],
          ),
          const SizedBox(height: 24),
          if (projects.isEmpty)
            SectionCard(
              title: 'No projects yet',
              subtitle: 'Create the first workflow from the dashboard.',
              child: Text(
                'Projects will appear here after the orchestrator creates an execution plan.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ...projects.map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onOpenProject(project.id),
                  child: SectionCard(
                    title: project.name,
                    subtitle: project.workspaceName,
                    trailing: StatusBadge(
                      label: project.status.label,
                      backgroundColor:
                          statusColor(project.status, theme.colorScheme)
                              .withValues(alpha: 0.12),
                      foregroundColor:
                          statusColor(project.status, theme.colorScheme),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.goal, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: project.progress),
                        const SizedBox(height: 8),
                        Text('${(project.progress * 100).round()}% complete'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
