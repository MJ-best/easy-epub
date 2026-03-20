enum WorkspaceRole { owner, admin, editor, viewer }

class WorkspaceSummary {
  const WorkspaceSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.role,
    required this.projectCount,
    required this.memberCount,
    required this.updatedAt,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String description;
  final WorkspaceRole role;
  final int projectCount;
  final int memberCount;
  final DateTime updatedAt;
  final bool isDefault;
}
