class RoleRecord {
  RoleRecord({
    this.id,
    required this.name,
    this.description = '',
    this.permissions = const [],
    this.status = 'active',
  });

  final int? id;
  final String name;
  final String description;
  final List<String> permissions;
  final String status;

  RoleRecord copyWith({
    int? id,
    String? name,
    String? description,
    List<String>? permissions,
    String? status,
  }) {
    return RoleRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
    );
  }
}
