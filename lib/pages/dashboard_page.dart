import 'dart:io';

import 'package:faker/faker.dart' as fk;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/account_model.dart';
import '../data/account_repository.dart';
import '../data/report_model.dart';
import '../data/report_repository.dart';
import '../widgets/account_table.dart';
import '../widgets/report_table.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.reportRepository,
    required this.accountRepository,
    required this.currentUsername,
    required this.onLogout,
  });

  final ReportRepository reportRepository;
  final AccountRepository accountRepository;
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
  final fk.Faker _faker = fk.Faker();

  bool _loading = true;
  int _rowsPerPage = 10;
  String _searchTerm = '';
  String _accountSearchTerm = '';
  String? _selectedCategory;
  String _selectedMenuLabel = '数据概览';
  bool _accountView = false;
  List<ReportRecord> _records = [];
  List<AccountRecord> _accounts = [];

  final List<MenuEntry> _menuEntries = [
    MenuEntry(
      label: '报表中心',
      icon: Icons.analytics,
      children: [
        MenuEntry(label: '数据概览', icon: Icons.folder, category: null),
        MenuEntry(label: '销售报表', icon: Icons.table_view, category: '销售'),
        MenuEntry(label: '运营报表', icon: Icons.stacked_bar_chart, category: '运营'),
        MenuEntry(label: '财务报表', icon: Icons.receipt_long, category: '财务'),
      ],
    ),
    MenuEntry(
      label: '系统设置',
      icon: Icons.settings,
      children: [
        MenuEntry(label: '权限', icon: Icons.person),
        MenuEntry(label: '安全策略', icon: Icons.security),
        MenuEntry(label: '备份恢复', icon: Icons.backup),
        MenuEntry(label: '账号管理', icon: Icons.admin_panel_settings, isAccount: true),
      ],
    ),
    MenuEntry(
      label: '开发工具',
      icon: Icons.developer_board,
      children: [
        MenuEntry(label: 'API 网关', icon: Icons.web),
        MenuEntry(label: '调试', icon: Icons.bug_report),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    if (_accountView) {
      final accounts = await widget.accountRepository.fetchAll(query: _accountSearchTerm);
      setState(() {
        _accounts = accounts;
        _selectedAccountIds.clear();
        _loading = false;
      });
    } else {
      final data = await widget.reportRepository.fetch(
        query: _searchTerm,
        category: _selectedCategory,
      );
      setState(() {
        _records = data;
        _selectedIds.clear();
        _loading = false;
      });
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

  void _handleSelectChange(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _handleAccountSelectChange(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedAccountIds.add(id);
      } else {
        _selectedAccountIds.remove(id);
      }
    });
  }

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

  Future<void> _handleAccountDelete(AccountRecord record) async {
    if (record.username == 'superchenergou') return;
    if (record.id == null) return;
    await widget.accountRepository.deleteOne(record.id!);
    await _refreshData();
  }

  Future<void> _handleAccountBulkDelete() async {
    if (_selectedAccountIds.isEmpty) return;
    final filtered = _accounts
        .where((e) => e.username != 'superchenergou' && e.id != null && _selectedAccountIds.contains(e.id))
        .map((e) => e.id!)
        .toSet();
    if (filtered.isEmpty) return;
    await widget.accountRepository.deleteMany(filtered);
    await _refreshData();
  }

  Future<void> _handleAccountAdd() async {
    final record = await _openAccountDialog(isNew: true);
    if (record != null) {
      final exists = await widget.accountRepository.findByUsername(record.username);
      if (exists != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('账号已存在，请更换账号名')),
        );
        return;
      }
      await widget.accountRepository.create(record);
      await _refreshData();
    }
  }

  Future<void> _handleAccountEdit(AccountRecord record) async {
    if (record.username == 'superchenergou') return;
    final updated = await _openAccountDialog(existing: record);
    if (updated != null) {
      await widget.accountRepository.update(updated);
      await _refreshData();
    }
  }

  Future<void> _handleAccountStatusChange(AccountRecord record, bool active) async {
    if (record.username == 'superchenergou') return;
    final updated = record.copyWith(status: active ? 'active' : 'disabled');
    await widget.accountRepository.update(updated);
    await _refreshData();
  }

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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
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

  Future<void> _handleSearch() async {
    _searchTerm = _searchController.text.trim();
    await _refreshData();
  }

  Future<void> _handleAccountSearch() async {
    _accountSearchTerm = _accountSearchController.text.trim();
    await _refreshData();
  }

  void _handleMenuTap(MenuEntry entry) {
    setState(() {
      _selectedCategory = entry.category;
      _selectedMenuLabel = entry.label;
      _accountView = entry.isAccount;
    });
    _refreshData();
  }

  Future<AccountRecord?> _openAccountDialog({AccountRecord? existing, bool isNew = false}) {
    final usernameController = TextEditingController(text: existing?.username ?? '');
    final passwordController = TextEditingController();
    final roleController = TextEditingController(text: existing?.role ?? 'user');
    bool statusActive = (existing?.status ?? 'active') == 'active';
    final isSuper = existing?.username == 'superchenergou';
    final createdAt = existing?.createdAt ?? DateTime.now().toIso8601String();
    String? avatarPath = existing?.avatarPath;

    return showDialog<AccountRecord>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                        decoration: const InputDecoration(
                          labelText: '账号',
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                          isDense: true,
                        ),
                      ),
                      _LabeledField(
                        label: isNew ? '密码' : '新密码（留空则不变）',
                        controller: passwordController,
                      ),
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
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final username = usernameController.text.trim();
                    if (username.isEmpty) return;
                    final newPassword = passwordController.text;
                    String passwordHash = existing?.passwordHash ?? '';
                    if (isNew && newPassword.isEmpty) {
                      Navigator.of(context).pop();
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
                    );
                    Navigator.of(context).pop(record);
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

  @override
  void dispose() {
    _searchController.dispose();
    _accountSearchController.dispose();
    super.dispose();
  }

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
                                          '当前模块：$_selectedMenuLabel（${_accountView ? _accounts.length : _records.length} 条记录）',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: _accountView
                                              ? AccountTable(
                                                  accounts: _accounts,
                                                  rowsPerPage: _rowsPerPage,
                                                  onRowsPerPageChanged: (value) {
                                                    if (value != null) {
                                                      setState(() => _rowsPerPage = value);
                                                    }
                                                  },
                                                  selectedIds: _selectedAccountIds,
                                                  onSelectChange: _handleAccountSelectChange,
                                                  onEdit: _handleAccountEdit,
                                                  onDelete: _handleAccountDelete,
                                                  onStatusChange: _handleAccountStatusChange,
                                                )
                                              : ReportTable(
                                                  records: _records,
                                                  rowsPerPage: _rowsPerPage,
                                                  onRowsPerPageChanged: (value) {
                                                    if (value != null) {
                                                      setState(() => _rowsPerPage = value);
                                                    }
                                                  },
                                                  selectedIds: _selectedIds,
                                                  onSelectChange: _handleSelectChange,
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
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                ),
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
              TextButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('退出登录'),
              ),
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
          ..._menuEntries.map(
            (entry) => ExpansionTile(
              leading: Icon(entry.icon),
              title: Text(entry.label),
              children: entry.children
                  .map(
                    (child) => ListTile(
                      leading: Icon(child.icon, size: 20),
                      title: Text(child.label),
                      selected: _selectedMenuLabel == child.label,
                      onTap: () => _handleMenuTap(child),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    if (_accountView) {
      return _buildAccountToolbar();
    }
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: '搜索标题、负责人或分类',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _handleSearch,
          icon: const Icon(Icons.filter_alt),
          label: const Text('筛选'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _selectedIds.isEmpty ? null : _handleBulkDelete,
          icon: const Icon(Icons.delete_outline),
          label: Text('批量删除 (${_selectedIds.length})'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _handleAdd,
          icon: const Icon(Icons.add),
          label: const Text('新增'),
        ),
        const Spacer(),
        Text(
          '分页：每页 $_rowsPerPage 条 | 共 ${_records.length} 条',
          style: const TextStyle(color: Colors.black54),
        ),
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
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            onSubmitted: (_) => _handleAccountSearch(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _handleAccountSearch,
          icon: const Icon(Icons.filter_alt),
          label: const Text('筛选'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _selectedAccountIds.isEmpty ? null : _handleAccountBulkDelete,
          icon: const Icon(Icons.delete_outline),
          label: Text('批量删除 (${_selectedAccountIds.length})'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _handleAccountAdd,
          icon: const Icon(Icons.add),
          label: const Text('新增账号'),
        ),
        const Spacer(),
        Text(
          '分页：每页 $_rowsPerPage 条 | 共 ${_accounts.length} 条',
          style: const TextStyle(color: Colors.black54),
        ),
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
}

class MenuEntry {
  MenuEntry({
    required this.label,
    required this.icon,
    this.category,
    this.isAccount = false,
    this.children = const [],
  });

  final String label;
  final IconData icon;
  final String? category;
  final bool isAccount;
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
          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
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
      // Debug log start
      // ignore: avoid_print
      print('尝试打开图库选择头像...');
      final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked != null && picked.path.isNotEmpty) {
        final bytes = await picked.readAsBytes();
        final supportDir = await getApplicationSupportDirectory();
        final avatarDir = Directory(p.join(supportDir.path, 'avatars'));
        if (!avatarDir.existsSync()) {
          avatarDir.createSync(recursive: true);
        }
        final targetPath = p.join(avatarDir.path, p.basename(picked.path));
        await File(targetPath).writeAsBytes(bytes, flush: true);
        if (mounted) {
          setState(() {
            _path = targetPath;
            _manualPathController.text = targetPath;
          });
        }
        widget.onPicked(targetPath);
        return;
      }
      // ignore: avoid_print
      print('未选择文件（可能用户取消）');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未选择文件')),
        );
      }
    } catch (e, st) {
      // Debug print to console when picker fails.
      // ignore: avoid_print
      print('头像选择失败: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
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
                decoration: const InputDecoration(
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
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.upload),
                  label: const Text('选择图片'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _setPath(_manualPathController.text.trim()),
                  child: const Text('使用路径'),
                ),
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
      final supportDir = await getApplicationSupportDirectory();
      final avatarDir = Directory(p.join(supportDir.path, 'avatars'));
      if (!avatarDir.existsSync()) {
        avatarDir.createSync(recursive: true);
      }
      final targetPath = p.join(avatarDir.path, p.basename(path));
      await File(targetPath).writeAsBytes(bytes, flush: true);
      if (mounted) {
        setState(() {
          _path = targetPath;
          _manualPathController.text = targetPath;
        });
      }
      widget.onPicked(targetPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法读取/保存头像，请使用“选择图片”按钮并允许访问照片或选择其他目录：$e'),
          ),
        );
      }
    }
  }
}
