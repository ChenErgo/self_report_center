import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../data/role_model.dart';

class RoleTable extends StatelessWidget {
  const RoleTable({
    super.key,
    required this.roles,
    required this.rowsPerPage,
    required this.onRowsPerPageChanged,
    required this.selectedIds,
    required this.onSelectChange,
    required this.onEdit,
    required this.onDelete,
  });

  final List<RoleRecord> roles;
  final int rowsPerPage;
  final ValueChanged<int?> onRowsPerPageChanged;
  final Set<int> selectedIds;
  final void Function(int id, bool selected) onSelectChange;
  final void Function(RoleRecord record) onEdit;
  final void Function(RoleRecord record) onDelete;

  @override
  Widget build(BuildContext context) {
    final source = _RoleTableSource(
      roles: roles,
      selectedIds: selectedIds,
      onEdit: onEdit,
      onDelete: onDelete,
      onSelectChanged: onSelectChange,
    );
    return PaginatedDataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      headingRowHeight: 44,
      dataRowHeight: 56,
      minWidth: 800,
      showCheckboxColumn: true,
      rowsPerPage: rowsPerPage,
      availableRowsPerPage: const [10, 20, 30],
      onRowsPerPageChanged: onRowsPerPageChanged,
      columns: const [
        DataColumn2(label: Text('名称'), size: ColumnSize.L),
        DataColumn2(label: Text('描述')),
        DataColumn2(label: Text('权限')),
        DataColumn2(label: Text('操作'), fixedWidth: 120),
      ],
      source: source,
    );
  }
}

class _RoleTableSource extends DataTableSource {
  _RoleTableSource({
    required this.roles,
    required this.selectedIds,
    required this.onEdit,
    required this.onDelete,
    required this.onSelectChanged,
  });

  final List<RoleRecord> roles;
  final Set<int> selectedIds;
  final void Function(RoleRecord record) onEdit;
  final void Function(RoleRecord record) onDelete;
  final void Function(int id, bool selected) onSelectChanged;

  @override
  DataRow? getRow(int index) {
    if (index >= roles.length) return null;
    final role = roles[index];
    final selected = role.id != null && selectedIds.contains(role.id);
    final isSuper = role.name == 'super_admin';

    return DataRow2(
      selected: selected,
      onSelectChanged: (value) {
        if (role.id != null && value != null && !isSuper) {
          onSelectChanged(role.id!, value);
          notifyListeners();
        }
      },
      cells: [
        DataCell(Text(role.name)),
        DataCell(Text(role.description)),
        DataCell(Text(role.permissions.join(', '))),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: '编辑',
                onPressed: isSuper ? null : () => onEdit(role),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: '删除',
                onPressed: isSuper ? null : () => onDelete(role),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => roles.length;

  @override
  int get selectedRowCount => selectedIds.length;
}
