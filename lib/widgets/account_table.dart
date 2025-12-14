import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../data/account_model.dart';

class AccountTable extends StatelessWidget {
  const AccountTable({
    super.key,
    required this.accounts,
    required this.rowsPerPage,
    required this.onRowsPerPageChanged,
    required this.selectedIds,
    required this.onSelectChange,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  final List<AccountRecord> accounts;
  final int rowsPerPage;
  final ValueChanged<int?> onRowsPerPageChanged;
  final Set<int> selectedIds;
  final void Function(int id, bool selected) onSelectChange;
  final void Function(AccountRecord record) onEdit;
  final void Function(AccountRecord record) onDelete;
  final void Function(AccountRecord record, bool active) onStatusChange;

  @override
  Widget build(BuildContext context) {
    final source = _AccountTableSource(
      accounts: accounts,
      selectedIds: selectedIds,
      onEdit: onEdit,
      onDelete: onDelete,
      onSelectChanged: onSelectChange,
      onStatusChange: onStatusChange,
    );

    return PaginatedDataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      headingRowHeight: 44,
      dataRowHeight: 56,
      minWidth: 900,
      showCheckboxColumn: true,
      rowsPerPage: rowsPerPage,
      availableRowsPerPage: const [10, 20, 30],
      onRowsPerPageChanged: onRowsPerPageChanged,
      columns: const [
        DataColumn2(label: Text('头像'), fixedWidth: 72),
        DataColumn2(label: Text('账号'), size: ColumnSize.L),
        DataColumn2(label: Text('角色')),
        DataColumn2(label: Text('角色列表'), size: ColumnSize.L),
        DataColumn2(label: Text('状态')),
        DataColumn2(label: Text('创建时间'), size: ColumnSize.M),
        DataColumn2(label: Text('操作'), fixedWidth: 120),
      ],
      source: source,
    );
  }
}

class _AccountTableSource extends DataTableSource {
  _AccountTableSource({
    required this.accounts,
    required this.selectedIds,
    required this.onEdit,
    required this.onDelete,
    required this.onSelectChanged,
    required this.onStatusChange,
  });

  final List<AccountRecord> accounts;
  final Set<int> selectedIds;
  final void Function(AccountRecord record) onEdit;
  final void Function(AccountRecord record) onDelete;
  final void Function(int id, bool selected) onSelectChanged;
  final void Function(AccountRecord record, bool active) onStatusChange;

  @override
  DataRow? getRow(int index) {
    if (index >= accounts.length) return null;
    final record = accounts[index];
    final selected = record.id != null && selectedIds.contains(record.id);
    final isSuper = record.username == 'superchenergou';

    return DataRow2(
      selected: selected,
      onSelectChanged: (value) {
        if (record.id != null && value != null && !isSuper) {
          onSelectChanged(record.id!, value);
          notifyListeners();
        }
      },
      cells: [
        DataCell(
          Container(
            width: 40,
            height: 40,
            color: Colors.grey.shade200,
            child: record.avatarPath != null && record.avatarPath!.isNotEmpty && File(record.avatarPath!).existsSync()
                ? Image.file(File(record.avatarPath!), fit: BoxFit.cover)
                : const Icon(Icons.person, size: 20, color: Colors.grey),
          ),
        ),
        DataCell(Text(record.username)),
        DataCell(Text(record.role)),
        DataCell(Text(record.roles.map((e) => e.name).join(', '))),
        DataCell(
          Switch.adaptive(
            value: record.status == 'active',
            onChanged: isSuper
                ? null
                : (value) {
                    onStatusChange(record, value);
                  },
          ),
        ),
        DataCell(Text(record.createdAt.split('T').first)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: '编辑',
                onPressed: isSuper ? null : () => onEdit(record),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: '删除',
                onPressed: isSuper ? null : () => onDelete(record),
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
  int get rowCount => accounts.length;

  @override
  int get selectedRowCount => selectedIds.length;
}
