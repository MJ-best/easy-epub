import 'package:flutter/material.dart';

import '../../../core/widgets/section_card.dart';
import '../models/conversation_models.dart';

class ExecutionLogScreen extends StatelessWidget {
  const ExecutionLogScreen({
    super.key,
    required this.messages,
  });

  final List<ExecutionMessageViewData> messages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Execution Log',
          subtitle: 'Conversation and system log feed for workflow steps.',
          child: messages.isEmpty
              ? Text(
                  'No execution messages yet.',
                  style: theme.textTheme.bodyLarge,
                )
              : Column(
                  children: [
                    for (final message in messages)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(message.sender),
                        subtitle: Text(message.content),
                        trailing: Text(
                          TimeOfDay.fromDateTime(message.createdAt)
                              .format(context),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
