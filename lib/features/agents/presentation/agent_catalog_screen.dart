import 'package:flutter/material.dart';

import '../../../core/widgets/section_card.dart';
import '../models/agent_definition_models.dart';

class AgentCatalogScreen extends StatelessWidget {
  const AgentCatalogScreen({
    super.key,
    required this.agents,
  });

  final List<AgentDefinitionViewData> agents;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Agent Catalog',
          subtitle: 'Clear role boundaries for the multi-agent workflow.',
          child: Column(
            children: [
              for (final agent in agents)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(agent.name),
                  subtitle: Text(agent.role),
                  trailing: Text(agent.outputTypes.join(', ')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
