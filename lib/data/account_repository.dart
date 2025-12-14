import 'account_model.dart';
import 'app_database.dart';

class AccountRepository {
  AccountRepository(this.db);

  final AppDatabase db;

  Future<List<AccountRecord>> fetchAll({String query = ''}) {
    return db.getAllAccounts(query: query);
  }

  Future<AccountRecord?> findByUsername(String username) {
    return db.getAccountByUsername(username);
  }

  Future<void> deleteMany(Set<int> ids) async {
    await db.deleteAccounts(ids.toList());
  }

  Future<void> deleteOne(int id) async {
    await db.deleteAccounts([id]);
  }

  Future<int> create(AccountRecord account) {
    return db.insertAccount(account);
  }

  Future<void> update(AccountRecord account) {
    return db.updateAccount(account);
  }
}
