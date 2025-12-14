import 'app_database.dart';
import 'role_model.dart';

class RoleRepository {
  RoleRepository(this.db);

  final AppDatabase db;

  Future<List<RoleRecord>> fetchAll() {
    return db.fetchRolesWithPermissions();
  }

  Future<int> create(RoleRecord role) {
    return db.insertRole(role);
  }

  Future<void> update(RoleRecord role) {
    return db.updateRole(role);
  }

  Future<void> delete(int roleId) {
    return db.deleteRole(roleId);
  }
}
