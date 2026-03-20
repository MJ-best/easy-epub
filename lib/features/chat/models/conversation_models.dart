class ExecutionConversationSummary {
  const ExecutionConversationSummary({
    required this.id,
    required this.title,
    required this.projectId,
    required this.latestMessageAt,
  });

  final String id;
  final String title;
  final String projectId;
  final DateTime latestMessageAt;
}

class ExecutionMessageViewData {
  const ExecutionMessageViewData({
    required this.id,
    required this.sender,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String sender;
  final String content;
  final DateTime createdAt;
}
