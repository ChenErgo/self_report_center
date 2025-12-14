class MenuPermission {
  const MenuPermission({required this.key, required this.label});

  final String key;
  final String label;
}

const List<MenuPermission> kMenuPermissions = [
  MenuPermission(key: 'data_overview', label: '数据概览'),
  MenuPermission(key: 'sales_report', label: '销售报表'),
  MenuPermission(key: 'ops_report', label: '运营报表'),
  MenuPermission(key: 'finance_report', label: '财务报表'),
  MenuPermission(key: 'settings_permission', label: '权限'),
  MenuPermission(key: 'settings_security', label: '安全策略'),
  MenuPermission(key: 'settings_backup', label: '备份恢复'),
  MenuPermission(key: 'account_manage', label: '账号管理'),
  MenuPermission(key: 'role_manage', label: '角色管理'),
  MenuPermission(key: 'dev_api', label: 'API 网关'),
  MenuPermission(key: 'dev_debug', label: '调试'),
];
