import 'account_model.dart';
import 'app_database.dart';

class AccountRepository {
  AccountRepository(this.db);

  final AppDatabase db;

  Future<List<AccountRecord>> fetchAll({String query = ''}) {
    return db.getAllAccountsDetailed(query: query);
  }

  Future<AccountRecord?> findByUsername(String username) {
    return db.getAccountByUsername(username);
  }

  Future<AccountRecord?> findDetailByUsername(String username) {
    return db.getAccountDetail(username);
  }

  Future<void> deleteMany(Set<int> ids) async {
    await db.deleteAccounts(ids.toList());
  }

  Future<void> deleteOne(int id) async {
    await db.deleteAccounts([id]);
  }

  Future<int> create(AccountRecord account, {List<int> roleIds = const []}) async {
    final id = await db.insertAccount(account);
    await db.replaceAccountRoles(id, roleIds);
    return id;
  }

  Future<void> update(AccountRecord account, {List<int> roleIds = const []}) async {
    await db.updateAccount(account);
    if (account.id != null) {
      await db.replaceAccountRoles(account.id!, roleIds);
    }
  }
}
