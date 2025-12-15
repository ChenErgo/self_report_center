import 'dart:io';

import 'package:faker/faker.dart' as fk;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/menu_keys.dart';
import '../data/account_model.dart';
import '../data/account_repository.dart';
import '../data/report_model.dart';
import '../data/report_repository.dart';
import '../data/role_model.dart';
import '../data/role_repository.dart';
import '../widgets/account_table.dart';
import '../widgets/report_table.dart';
import '../widgets/role_table.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.reportRepository,
    required this.accountRepository,
    required this.roleRepository,
    required this.currentUsername,
    required this.onLogout,
  });

  final ReportRepository reportRepository;
  final AccountRepository accountRepository;
  final RoleRepository roleRepository;
  final String currentUsername;
  final VoidCallback onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _accountSearchController = TextEditingController();
  final Set<int> _selectedIds = {};
  final Set<int> _selectedAccountIds = {};
  final Set<int> _selectedRoleIds = {};
  final fk.Faker _faker = fk.Faker();

  bool _loading = true;
  int _rowsPerPage = 10;
  String _searchTerm = '';
  String _accountSearchTerm = '';
  String? _selectedCategory;
  String _selectedMenuLabel = '数据概览';
  bool _accountView = false;
  bool _roleView = false;
  bool _isSuperAdmin = false;
  Set<String> _currentPermissions = {};
  List<ReportRecord> _records = [];
  List<AccountRecord> _accounts = [];
  List<RoleRecord> _roles = [];
  List<RoleRecord> _roleRecords = [];

  final List<MenuEntry> _menuEntries = [
    MenuEntry(
      label: '报表中心',
      icon: Icons.analytics,
      permissionKey: 'data_overview',
      children: [
        MenuEntry(label: '数据概览', icon: Icons.folder, category: null, permissionKey: 'data_overview'),
        MenuEntry(label: '销售报表', icon: Icons.table_view, category: '销售', permissionKey: 'sales_report'),
        MenuEntry(label: '运营报表', icon: Icons.stacked_bar_chart, category: '运营', permissionKey: 'ops_report'),
        MenuEntry(label: '财务报表', icon: Icons.receipt_long, category: '财务', permissionKey: 'finance_report'),
      ],
    ),
    MenuEntry(
      label: '系统设置',
      icon: Icons.settings,
      children: [
        MenuEntry(label: '权限', icon: Icons.person, permissionKey: 'settings_permission'),
        MenuEntry(label: '安全策略', icon: Icons.security, permissionKey: 'settings_security'),
        MenuEntry(label: '备份恢复', icon: Icons.backup, permissionKey: 'settings_backup'),
        MenuEntry(label: '账号管理', icon: Icons.admin_panel_settings, isAccount: true, permissionKey: 'account_manage'),
        MenuEntry(label: '角色管理', icon: Icons.supervisor_account, isRole: true, permissionKey: 'role_manage'),
      ],
    ),
    MenuEntry(
      label: '开发工具',
      icon: Icons.developer_board,
      children: [
        MenuEntry(label: 'API 网关', icon: Icons.web, permissionKey: 'dev_api'),
        MenuEntry(label: '调试', icon: Icons.bug_report, permissionKey: 'dev_debug'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadRolesAndPermissions();
    await _refreshData();
  }

  Future<void> _loadRolesAndPermissions() async {
    final roles = await widget.roleRepository.fetchAll();
    final acct = await widget.accountRepository.findDetailByUsername(widget.currentUsername);
    final perms = <String>{};
    bool superAdmin = false;
    if (acct != null && acct.roles.isNotEmpty) {
      for (final r in acct.roles) {
        perms.addAll(r.permissions);
        if (r.name == 'super_admin') superAdmin = true;
      }
    } else {
      perms.addAll(kMenuPermissions.map((e) => e.key));
    }
    setState(() {
      _roles = roles;
      _isSuperAdmin = superAdmin;
      _currentPermissions = perms;
    });
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    if (_roleView) {
      await _refreshRoles();
      setState(() => _loading = false);
      return;
    }
    if (_accountView) {
      final accounts = await widget.accountRepository.fetchAll(query: _accountSearchTerm);
      setState(() {
        _accounts = accounts;
        _selectedAccountIds.clear();
        _loading = false;
      });
    } else {
      final data = await widget.reportRepository.fetch(query: _searchTerm, category: _selectedCategory);
      setState(() {
        _records = data;
        _selectedIds.clear();
        _loading = false;
      });
    }
  }

  Future<void> _refreshRoles() async {
    final roles = await widget.roleRepository.fetchAll();
    setState(() {
      _roleRecords = roles;
      _roles = roles;
      _selectedRoleIds.clear();
    });
  }

  // Menu and permissions
  bool _canAccess(MenuEntry entry) {
    if (_isSuperAdmin) return true;
    if (entry.permissionKey == null) return true;
    return _currentPermissions.contains(entry.permissionKey);
  }

  // Report handlers
  Future<void> _handleEdit(ReportRecord record) async {
    final updated = await _openEditDialog(record);
    if (updated != null) {
      await widget.reportRepository.update(updated);
      await _refreshData();
    }
  }

  Future<void> _handleAdd() async {
    final base = ReportRecord.fake(_faker);
    final created = await _openEditDialog(base, isNew: true);
    if (created != null) {
      await widget.reportRepository.create(created);
      await _refreshData();
    }
  }

  Future<void> _handleDeleteSingle(ReportRecord record) async {
    if (record.id == null) return;
    await widget.reportRepository.deleteOne(record.id!);
    await _refreshData();
  }

  Future<void> _handleBulkDelete() async {
    if (_selectedIds.isEmpty) return;
    await widget.reportRepository.deleteMany(_selectedIds);
    await _refreshData();
  }

  // Account handlers
  Future<void> _handleAccountAdd() async {
    final record = await _openAccountDialog(isNew: true);
    if (record != null) {
      final exists = await widget.accountRepository.findByUsername(record.username);
      if (exists != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('账号已存在，请更换账号名')));
        return;
      }
      final roleIds = record.roles.where((r) => r.id != null).map((r) => r.id!).toList();
      await widget.accountRepository.create(record, roleIds: roleIds);
      await _refreshData();
    }
  }

  Future<void> _handleAccountEdit(AccountRecord record) async {
    if (record.username == 'superchenergou') return;
    final updated = await _openAccountDialog(existing: record);
    if (updated != null) {
      final roleIds = updated.roles.where((r) => r.id != null).map((r) => r.id!).toList();
      await widget.accountRepository.update(updated.copyWith(id: record.id), roleIds: roleIds);
      await _refreshData();
    }
  }

  Future<void> _handleAccountDelete(AccountRecord record) async {
    if (record.username == 'superchenergou') return;
    if (record.id == null) return;
    await widget.accountRepository.deleteOne(record.id!);
    await _refreshData();
  }

  Future<void> _handleAccountBulkDelete() async {
    if (_selectedAccountIds.isEmpty) return;
    final filtered = _accounts.where((e) => e.username != 'superchenergou' && e.id != null && _selectedAccountIds.contains(e.id)).map((e) => e.id!).toSet();
    if (filtered.isEmpty) return;
    await widget.accountRepository.deleteMany(filtered);
    await _refreshData();
  }

  Future<void> _handleAccountStatusChange(AccountRecord record, bool active) async {
    if (record.username == 'superchenergou') return;
    final updated = record.copyWith(status: active ? 'active' : 'disabled');
    await widget.accountRepository.update(updated);
    await _refreshData();
  }

  // Role handlers
  Future<void> _handleRoleAdd() async {
    final role = await _openRoleDialog();
    if (role != null) {
      await widget.roleRepository.create(role);
      await _loadRolesAndPermissions();
      await _refreshData();
    }
  }

  Future<void> _handleRoleEdit(RoleRecord role) async {
    if (role.name == 'super_admin') return;
    final updated = await _openRoleDialog(existing: role);
    if (updated != null) {
      await widget.roleRepository.update(updated.copyWith(id: role.id));
      await _loadRolesAndPermissions();
      await _refreshData();
    }
  }

  Future<void> _handleRoleDelete(RoleRecord role) async {
    if (role.name == 'super_admin' || role.id == null) return;
    await widget.roleRepository.delete(role.id!);
    await _loadRolesAndPermissions();
    await _refreshData();
  }

  Future<void> _handleRoleDeleteSelected() async {
    if (_selectedRoleIds.isEmpty) return;
    final toDelete = _roleRecords.where((r) => r.id != null && _selectedRoleIds.contains(r.id) && r.name != 'super_admin').toList();
    for (final r in toDelete) {
      await widget.roleRepository.delete(r.id!);
    }
    await _loadRolesAndPermissions();
    await _refreshData();
  }

  // Dialogs
  Future<ReportRecord?> _openEditDialog(ReportRecord record, {bool isNew = false}) {
    final titleController = TextEditingController(text: record.title);
    final ownerController = TextEditingController(text: record.owner);
    final statusController = TextEditingController(text: record.status);
    final priorityController = TextEditingController(text: record.priority);
    final categoryController = TextEditingController(text: record.category);
    final departmentController = TextEditingController(text: record.department);
    final cityController = TextEditingController(text: record.city);

    return showDialog<ReportRecord>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(isNew ? '新增记录' : '编辑记录'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LabeledField(label: '标题', controller: titleController),
                  _LabeledField(label: '负责人', controller: ownerController),
                  _LabeledField(label: '状态', controller: statusController),
                  _LabeledField(label: '优先级', controller: priorityController),
                  _LabeledField(label: '分类', controller: categoryController),
                  _LabeledField(label: '部门', controller: departmentController),
                  _LabeledField(label: '城市', controller: cityController),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final updated = record.copyWith(
                  title: titleController.text.trim(),
                  owner: ownerController.text.trim(),
                  status: statusController.text.trim(),
                  priority: priorityController.text.trim(),
                  category: categoryController.text.trim(),
                  department: departmentController.text.trim(),
                  city: cityController.text.trim(),
                  updatedAt: DateTime.now().toIso8601String(),
                );
                Navigator.of(context).pop(updated);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<AccountRecord?> _openAccountDialog({AccountRecord? existing, bool isNew = false}) {
    final usernameController = TextEditingController(text: existing?.username ?? '');
    final passwordController = TextEditingController();
    final roleController = TextEditingController(text: existing?.role ?? 'user');
    bool statusActive = (existing?.status ?? 'active') == 'active';
    final isSuper = existing?.username == 'superchenergou';
    final createdAt = existing?.createdAt ?? DateTime.now().toIso8601String();
    String? avatarPath = existing?.avatarPath;
    final selectedRoleIds = <int>{...existing?.roles.where((r) => r.id != null).map((r) => r.id!) ?? {}};

    return showDialog<AccountRecord>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateDialog) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Text(isNew ? '新增账号' : '编辑账号'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: usernameController,
                        readOnly: isSuper || !isNew,
                        decoration: InputDecoration(
                          labelText: '账号',
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                          isDense: true,
                        ),
                      ),
                      _LabeledField(label: isNew ? '密码' : '新密码（留空则不变）', controller: passwordController),
                      _LabeledField(label: '角色', controller: roleController),
                      const SizedBox(height: 8),
                      _AvatarPicker(
                        initialPath: avatarPath,
                        onPicked: (path) {
                          setStateDialog(() {
                            avatarPath = path;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const Align(alignment: Alignment.centerLeft, child: Text('选择角色（可多选）')),
                      Column(
                        children: _roles.map((r) {
                          final checked = selectedRoleIds.contains(r.id);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: checked,
                            title: Text(r.name),
                            onChanged: (val) {
                              if (r.id == null || val == null) return;
                              setStateDialog(() {
                                if (val) {
                                  selectedRoleIds.add(r.id!);
                                } else {
                                  selectedRoleIds.remove(r.id!);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SwitchListTile(
                        title: const Text('状态（启用/禁用）'),
                        value: statusActive,
                        onChanged: isSuper
                            ? null
                            : (value) {
                                setStateDialog(() {
                                  statusActive = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('取消')),
                FilledButton(
                  onPressed: () {
                    final username = usernameController.text.trim();
                    if (username.isEmpty) return;
                    final newPassword = passwordController.text;
                    String passwordHash = existing?.passwordHash ?? '';
                    if (isNew && newPassword.isEmpty) {
                      Navigator.of(dialogCtx).pop();
                      return;
                    }
                    if (newPassword.isNotEmpty) {
                      passwordHash = AccountRecord.hashPassword(newPassword);
                    }
                    final record = AccountRecord(
                      id: existing?.id,
                      username: username,
                      passwordHash: passwordHash,
                      role: roleController.text.trim().isEmpty ? 'user' : roleController.text.trim(),
                      status: statusActive ? 'active' : 'disabled',
                      avatarPath: avatarPath,
                      createdAt: createdAt,
                      roles: _roles.where((r) => selectedRoleIds.contains(r.id)).toList(),
                    );
                    Navigator.of(dialogCtx).pop(record);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<RoleRecord?> _openRoleDialog({RoleRecord? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final selectedPerms = <String>{...?(existing?.permissions)};

    return showDialog<RoleRecord>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (innerCtx, setStateDialog) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Text(existing == null ? '新增角色' : '编辑角色'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        readOnly: existing?.name == 'super_admin',
                        decoration: InputDecoration(
                          labelText: '角色名称',
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: '描述',
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('菜单权限'),
                      Column(
                        children: kMenuPermissions.map((perm) {
                          final checked = selectedPerms.contains(perm.key);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: checked,
                            title: Text(perm.label),
                            onChanged: existing?.name == 'super_admin'
                                ? null
                                : (val) {
                                    if (val == null) return;
                                    setStateDialog(() {
                                      if (val) {
                                        selectedPerms.add(perm.key);
                                      } else {
                                        selectedPerms.remove(perm.key);
                                      }
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('取消')),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.of(dialogCtx).pop(
                      RoleRecord(
                        id: existing?.id,
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        permissions: selectedPerms.toList(),
                      ),
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // UI builders
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                _buildSideMenu(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildToolbar(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: _loading
                                ? const Center(child: CircularProgressIndicator())
                                : Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '当前模块：$_selectedMenuLabel（${_roleView ? _roleRecords.length : _accountView ? _accounts.length : _records.length} 条记录）',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: _roleView
                                              ? RoleTable(
                                                  roles: _roleRecords,
                                                  rowsPerPage: _rowsPerPage,
                                                  onRowsPerPageChanged: (value) {
                                                    if (value != null) setState(() => _rowsPerPage = value);
                                                  },
                                                  selectedIds: _selectedRoleIds,
                                                  onSelectChange: (id, sel) {
                                                    setState(() {
                                                      if (sel) {
                                                        _selectedRoleIds.add(id);
                                                      } else {
                                                        _selectedRoleIds.remove(id);
                                                      }
                                                    });
                                                  },
                                                  onEdit: _handleRoleEdit,
                                                  onDelete: _handleRoleDelete,
                                                )
                                              : _accountView
                                                  ? AccountTable(
                                                      accounts: _accounts,
                                                      rowsPerPage: _rowsPerPage,
                                                      onRowsPerPageChanged: (value) {
                                                        if (value != null) setState(() => _rowsPerPage = value);
                                                      },
                                                      selectedIds: _selectedAccountIds,
                                                      onSelectChange: (id, sel) {
                                                        setState(() {
                                                          if (sel) {
                                                            _selectedAccountIds.add(id);
                                                          } else {
                                                            _selectedAccountIds.remove(id);
                                                          }
                                                        });
                                                      },
                                                      onEdit: _handleAccountEdit,
                                                      onDelete: _handleAccountDelete,
                                                      onStatusChange: _handleAccountStatusChange,
                                                    )
                                                  : ReportTable(
                                                      records: _records,
                                                      rowsPerPage: _rowsPerPage,
                                                      onRowsPerPageChanged: (value) {
                                                        if (value != null) setState(() => _rowsPerPage = value);
                                                      },
                                                      selectedIds: _selectedIds,
                                                      onSelectChange: (id, sel) {
                                                        setState(() {
                                                          if (sel) {
                                                            _selectedIds.add(id);
                                                          } else {
                                                            _selectedIds.remove(id);
                                                          }
                                                        });
                                                      },
                                                      onEdit: _handleEdit,
                                                      onDelete: _handleDeleteSingle,
                                                    ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                color: Colors.teal.shade100,
                child: const Icon(Icons.dashboard_customize, color: Colors.teal),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('桌面管理系统', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Self Report Center', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Wrap(
            spacing: 16,
            children: [
              Text('当前用户：${widget.currentUsername}'),
              const Text('控制台'),
              const Text('通知中心'),
              const Text('帮助文档'),
              TextButton.icon(onPressed: widget.onLogout, icon: const Icon(Icons.logout), label: const Text('退出登录')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    return Container(
      width: 260,
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('导航', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._menuEntries.map((entry) {
            final visibleChildren = entry.children.where(_canAccess).toList();
            if (!_canAccess(entry) && visibleChildren.isEmpty) {
              return const SizedBox.shrink();
            }
            return ExpansionTile(
              leading: Icon(entry.icon),
              title: Text(entry.label),
              children: visibleChildren
                  .map(
                    (child) => ListTile(
                      leading: Icon(child.icon, size: 20),
                      title: Text(child.label),
                      selected: _selectedMenuLabel == child.label,
                      onTap: () => _handleMenuTap(child),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    if (_roleView) return _buildRoleToolbar();
    if (_accountView) return _buildAccountToolbar();
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: '搜索标题、负责人或分类',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: _handleSearch, icon: const Icon(Icons.filter_alt), label: const Text('筛选')),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _selectedIds.isEmpty ? null : _handleBulkDelete,
          icon: const Icon(Icons.delete_outline),
          label: Text('批量删除 (${_selectedIds.length})'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: _handleAdd, icon: const Icon(Icons.add), label: const Text('新增')),
        const Spacer(),
        Text('分页：每页 $_rowsPerPage 条 | 共 ${_records.length} 条', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _buildAccountToolbar() {
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: TextField(
            controller: _accountSearchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: '搜索账号、角色、状态',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            onSubmitted: (_) => _handleAccountSearch(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: _handleAccountSearch, icon: const Icon(Icons.filter_alt), label: const Text('筛选')),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _selectedAccountIds.isEmpty ? null : _handleAccountBulkDelete,
          icon: const Icon(Icons.delete_outline),
          label: Text('批量删除 (${_selectedAccountIds.length})'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: _handleAccountAdd, icon: const Icon(Icons.add), label: const Text('新增账号')),
        const Spacer(),
        Text('分页：每页 $_rowsPerPage 条 | 共 ${_accounts.length} 条', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _buildRoleToolbar() {
    return Row(
      children: [
        FilledButton.icon(onPressed: _handleRoleAdd, icon: const Icon(Icons.add), label: const Text('新增角色')),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _selectedRoleIds.isEmpty ? null : _handleRoleDeleteSelected,
          icon: const Icon(Icons.delete_outline),
          label: Text('删除选中 (${_selectedRoleIds.length})'),
        ),
        const Spacer(),
        Text('分页：每页 $_rowsPerPage 条 | 共 ${_roleRecords.length} 条', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('© 2024 Self Report Center'),
          SizedBox(width: 16),
          Text('开发厂商：SRC Tech'),
          SizedBox(width: 16),
          Text('备案：京ICP备000000号'),
          SizedBox(width: 16),
          Text('使用方：内部管理系统'),
        ],
      ),
    );
  }

  void _handleMenuTap(MenuEntry entry) {
    setState(() {
      _selectedCategory = entry.category;
      _selectedMenuLabel = entry.label;
      _accountView = entry.isAccount;
      _roleView = entry.isRole;
    });
    _refreshData();
  }

  Future<void> _handleSearch() async {
    _searchTerm = _searchController.text.trim();
    await _refreshData();
  }

  Future<void> _handleAccountSearch() async {
    _accountSearchTerm = _accountSearchController.text.trim();
    await _refreshData();
  }
}

class MenuEntry {
  MenuEntry({
    required this.label,
    required this.icon,
    this.category,
    this.isAccount = false,
    this.isRole = false,
    this.permissionKey,
    this.children = const [],
  });

  final String label;
  final IconData icon;
  final String? category;
  final bool isAccount;
  final bool isRole;
  final String? permissionKey;
  final List<MenuEntry> children;
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
          isDense: true,
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatefulWidget {
  const _AvatarPicker({
    required this.initialPath,
    required this.onPicked,
  });

  final String? initialPath;
  final void Function(String?) onPicked;

  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  String? _path;
  final TextEditingController _manualPathController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
    _manualPathController.text = widget.initialPath ?? '';
  }

  @override
  void dispose() {
    _manualPathController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked != null && picked.path.isNotEmpty) {
        await _copyAndSetPath(picked.path, await picked.readAsBytes());
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未选择文件')));
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('头像选择失败: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          color: Colors.grey.shade200,
          child: _path != null && File(_path!).existsSync()
              ? Image.file(File(_path!), fit: BoxFit.cover)
              : const Icon(Icons.person, size: 32, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: _manualPathController,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: '本地路径',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                ),
                onSubmitted: (value) => _setPath(value),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.upload), label: const Text('选择图片')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => _setPath(_manualPathController.text.trim()), child: const Text('使用路径')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _setPath(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final bytes = await File(path).readAsBytes();
      await _copyAndSetPath(path, bytes);
    } catch (e, st) {
      // ignore: avoid_print
      print('头像路径复制失败: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法读取/保存头像，请选择可访问的图片文件：$e')),
        );
      }
    }
  }

  Future<void> _copyAndSetPath(String sourcePath, List<int> bytes) async {
    final supportDir = await getApplicationSupportDirectory();
    final avatarDir = Directory(p.join(supportDir.path, 'avatars'));
    if (!avatarDir.existsSync()) {
      avatarDir.createSync(recursive: true);
    }
    final targetPath = p.join(avatarDir.path, p.basename(sourcePath));
    await File(targetPath).writeAsBytes(bytes, flush: true);
    if (mounted) {
      setState(() {
        _path = targetPath;
        _manualPathController.text = targetPath;
      });
    }
    widget.onPicked(targetPath);
  }
}
