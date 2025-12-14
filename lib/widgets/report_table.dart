import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../data/report_model.dart';

class ReportTable extends StatelessWidget {
  const ReportTable({
    super.key,
    required this.records,
    required this.rowsPerPage,
    required this.onRowsPerPageChanged,
    required this.selectedIds,
    required this.onSelectChange,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ReportRecord> records;
  final int rowsPerPage;
  final ValueChanged<int?> onRowsPerPageChanged;
  final Set<int> selectedIds;
  final void Function(int id, bool selected) onSelectChange;
  final void Function(ReportRecord record) onEdit;
  final void Function(ReportRecord record) onDelete;

  @override
  Widget build(BuildContext context) {
    final source = _ReportTableSource(
      records: records,
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
      minWidth: 1400,
      showCheckboxColumn: true,
      rowsPerPage: rowsPerPage,
      availableRowsPerPage: const [10, 20, 30],
      onRowsPerPageChanged: onRowsPerPageChanged,
      columns: const [
        DataColumn2(label: Text('标题'), size: ColumnSize.L),
        DataColumn2(label: Text('负责人')),
        DataColumn2(label: Text('部门')),
        DataColumn2(label: Text('状态')),
        DataColumn2(label: Text('优先级')),
        DataColumn2(label: Text('分类')),
        DataColumn2(label: Text('区域')),
        DataColumn2(label: Text('平台')),
        DataColumn2(label: Text('版本')),
        DataColumn2(label: Text('城市')),
        DataColumn2(label: Text('更新时间'), size: ColumnSize.M),
        DataColumn2(label: Text('操作'), fixedWidth: 120),
      ],
      source: source,
    );
  }
}

class _ReportTableSource extends DataTableSource {
  _ReportTableSource({
    required this.records,
    required this.selectedIds,
    required this.onEdit,
    required this.onDelete,
    required this.onSelectChanged,
  });

  final List<ReportRecord> records;
  final Set<int> selectedIds;
  final void Function(ReportRecord record) onEdit;
  final void Function(ReportRecord record) onDelete;
  final void Function(int id, bool selected) onSelectChanged;

  @override
  DataRow? getRow(int index) {
    if (index >= records.length) return null;
    final record = records[index];
    final selected = record.id != null && selectedIds.contains(record.id);

    return DataRow2(
      selected: selected,
      onSelectChanged: (value) {
        if (record.id != null && value != null) {
          onSelectChanged(record.id!, value);
          notifyListeners();
        }
      },
      cells: [
        DataCell(Text(record.title)),
        DataCell(Text(record.owner)),
        DataCell(Text(record.department)),
        DataCell(_StatusChip(text: record.status)),
        DataCell(Text(record.priority)),
        DataCell(Text(record.category)),
        DataCell(Text(record.region)),
        DataCell(Text(record.platform)),
        DataCell(Text(record.version)),
        DataCell(Text(record.city)),
        DataCell(Text(record.updatedAt.split('T').first)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: '编辑',
                onPressed: () => onEdit(record),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: '删除',
                onPressed: () => onDelete(record),
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
  int get rowCount => records.length;

  @override
  int get selectedRowCount => selectedIds.length;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

  final String text;

  Color _background() {
    switch (text) {
      case '待审核':
        return Colors.orange.shade50;
      case '已发布':
        return Colors.green.shade50;
      case '草稿':
        return Colors.grey.shade200;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _foreground() {
    switch (text) {
      case '待审核':
        return Colors.orange.shade900;
      case '已发布':
        return Colors.green.shade800;
      case '草稿':
        return Colors.grey.shade800;
      default:
        return Colors.blue.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _background(),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        text,
        style: TextStyle(color: _foreground(), fontSize: 12),
      ),
    );
  }
}
