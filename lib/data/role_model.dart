class RoleRecord {
  RoleRecord({
    this.id,
    required this.name,
    this.description = '',
    this.permissions = const [],
  });

  final int? id;
  final String name;
  final String description;
  final List<String> permissions;

  RoleRecord copyWith({
    int? id,
    String? name,
    String? description,
    List<String>? permissions,
  }) {
    return RoleRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
    );
  }
}
