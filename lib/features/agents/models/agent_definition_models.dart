class AgentDefinitionViewData {
  const AgentDefinitionViewData({
    required this.id,
    required this.name,
    required this.role,
    required this.boundaries,
    required this.outputTypes,
  });

  final String id;
  final String name;
  final String role;
  final List<String> boundaries;
  final List<String> outputTypes;
}
