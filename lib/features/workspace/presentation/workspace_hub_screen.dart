import 'package:flutter/material.dart';

import '../../../core/widgets/section_card.dart';
import '../../workspaces/models/workspace_models.dart';

class WorkspaceHubScreen extends StatelessWidget {
  const WorkspaceHubScreen({
    super.key,
    required this.workspaces,
    required this.onSelectWorkspace,
  });

  final List<WorkspaceSummary> workspaces;
  final ValueChanged<String> onSelectWorkspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Workspace Hub',
          subtitle: 'Select the workspace that owns the workflow artifacts.',
          child: workspaces.isEmpty
              ? Text(
                  'No workspace is available yet.',
                  style: theme.textTheme.bodyLarge,
                )
              : Column(
                  children: [
                    for (final workspace in workspaces)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(workspace.name),
                        subtitle: Text(
                          '${workspace.role.name} · ${workspace.projectCount} projects',
                        ),
                        trailing: TextButton(
                          onPressed: () => onSelectWorkspace(workspace.id),
                          child: const Text('Open'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
