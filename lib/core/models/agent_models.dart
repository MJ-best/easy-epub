enum AgentStage {
  orchestration,
  planning,
  architecture,
  implementation,
  validation,
}

class AgentNode {
  const AgentNode({
    required this.id,
    required this.name,
    required this.stage,
    required this.responsibility,
    required this.outputType,
  });

  final String id;
  final String name;
  final AgentStage stage;
  final String responsibility;
  final String outputType;
}
