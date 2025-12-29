class MenuPermission {
  const MenuPermission({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;
}

const List<MenuPermission> kMenuPermissions = [
  MenuPermission(
    key: 'data_overview',
    label: '数据概览',
    description: '查看关键指标和总体数据大盘。',
  ),
  MenuPermission(
    key: 'sales_report',
    label: '销售报表',
    description: '查看与导出销售相关的报表数据。',
  ),
  MenuPermission(
    key: 'ops_report',
    label: '运营报表',
    description: '查看运营表现、趋势及细分数据。',
  ),
  MenuPermission(
    key: 'finance_report',
    label: '财务报表',
    description: '查看财务相关的收入、支出与成本报表。',
  ),
  MenuPermission(
    key: 'settings_permission',
    label: '权限',
    description: '查看菜单权限配置与结构。',
  ),
  MenuPermission(
    key: 'settings_security',
    label: '安全策略',
    description: '查看安全策略及安全相关配置项。',
  ),
  MenuPermission(
    key: 'settings_backup',
    label: '备份恢复',
    description: '查看备份计划与恢复相关操作入口。',
  ),
  MenuPermission(
    key: 'account_manage',
    label: '账号管理',
    description: '查看账号列表、角色绑定和状态。',
  ),
  MenuPermission(
    key: 'role_manage',
    label: '角色管理',
    description: '查看角色列表以及角色对应的权限集合。',
  ),
  MenuPermission(
    key: 'dev_api',
    label: 'API 网关',
    description: '查看 API 网关配置与可用接口列表。',
  ),
  MenuPermission(
    key: 'dev_debug',
    label: '调试',
    description: '查看调试工具和相关配置页面。',
  ),
];
