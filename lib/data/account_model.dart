import 'package:bcrypt/bcrypt.dart';
import 'role_model.dart';

class AccountRecord {
  AccountRecord({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.status,
    required this.avatarPath,
    this.roles = const [],
    required this.createdAt,
  });

  final int? id;
  final String username;
  final String passwordHash;
  final String role;
  final String status;
  final String? avatarPath;
  final List<RoleRecord> roles;
  final String createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'role': role,
      'status': status,
      'avatarPath': avatarPath,
      // roles stored via account_roles table
      'createdAt': createdAt,
    };
  }

  factory AccountRecord.fromMap(Map<String, Object?> map) {
    return AccountRecord(
      id: map['id'] as int?,
      username: (map['username'] ?? '') as String,
      passwordHash: (map['passwordHash'] ?? '') as String,
      role: (map['role'] ?? '') as String,
      status: (map['status'] ?? '') as String,
      avatarPath: map['avatarPath'] as String?,
      roles: const [],
      createdAt: (map['createdAt'] ?? '') as String,
    );
  }

  AccountRecord copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? role,
    String? status,
    String? avatarPath,
    List<RoleRecord>? roles,
    String? createdAt,
  }) {
    return AccountRecord(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarPath: avatarPath ?? this.avatarPath,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String hashPassword(String plain) {
    return BCrypt.hashpw(plain, BCrypt.gensalt());
  }

  bool verifyPassword(String plain) {
    return BCrypt.checkpw(plain, passwordHash);
  }
}
