import 'package:flutter/material.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/responsive_split_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../projects/models/project_workflow_models.dart';

class ArtifactViewerScreen extends StatelessWidget {
  const ArtifactViewerScreen({
    super.key,
    required this.artifacts,
    this.artifact,
    required this.onSelectArtifact,
    required this.onDestinationSelected,
  });

  final List<WorkflowArtifactSummary> artifacts;
  final WorkflowArtifactSummary? artifact;
  final ValueChanged<String> onSelectArtifact;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final selected = artifact;

    return AppShell(
      title: 'Artifact Viewer',
      selectedIndex: 2,
      onDestinationSelected: onDestinationSelected,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: selected?.title ?? 'Artifact pending',
            subtitle:
                selected?.description ?? 'No artifact has been selected yet.',
            child: Text(
              selected?.preview ??
                  'Choose an artifact from the list once the workflow generates it.',
            ),
          ),
          const SizedBox(height: 16),
          ResponsiveSplitView(
            primary: SectionCard(
              title: 'Artifact list',
              subtitle: 'Switch between generated outputs',
              child: artifacts.isEmpty
                  ? const Text(
                      'Artifacts will appear here after agent execution starts.')
                  : Column(
                      children: artifacts
                          .map(
                            (item) => ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: Text(item.title),
                              subtitle: Text(item.type.label),
                              selected: item.id == selected?.id,
                              onTap: () => onSelectArtifact(item.id),
                            ),
                          )
                          .toList(),
                    ),
            ),
            secondary: SectionCard(
              title: 'Viewer',
              subtitle: 'Markdown, code, and logs can be rendered here',
              child: Container(
                height: 360,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SelectableText(
                  selected?.preview ?? 'Artifact content is not available yet.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
