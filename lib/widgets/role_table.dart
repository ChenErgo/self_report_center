import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../data/role_model.dart';

class RoleTable extends StatefulWidget {
  const RoleTable({
    super.key,
    required this.roles,
    required this.rowsPerPage,
    required this.resetToken,
    required this.onRowsPerPageChanged,
    required this.selectedIds,
    required this.onSelectChange,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  final List<RoleRecord> roles;
  final int rowsPerPage;
  final int resetToken;
  final ValueChanged<int?> onRowsPerPageChanged;
  final Set<int> selectedIds;
  final void Function(int id, bool selected) onSelectChange;
  final void Function(RoleRecord record) onEdit;
  final void Function(RoleRecord record) onDelete;
  final void Function(RoleRecord record, bool active) onStatusChange;

  @override
  State<RoleTable> createState() => _RoleTableState();
}

class _RoleTableState extends State<RoleTable> {
  int _currentPage = 1;

  @override
  void didUpdateWidget(covariant RoleTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final totalPages = _totalPages;
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    if (oldWidget.resetToken != widget.resetToken) {
      _currentPage = 1;
    }
  }

  int get _totalPages {
    if (widget.roles.isEmpty) return 1;
    return ((widget.roles.length - 1) ~/ widget.rowsPerPage) + 1;
  }

  List<RoleRecord> get _pageRecords {
    final start = (_currentPage - 1) * widget.rowsPerPage;
    return widget.roles.skip(start).take(widget.rowsPerPage).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    final pageRecords = _pageRecords;
    final tableData = pageRecords
        .map(
          (role) => {
            'id': role.id,
            'name': role.name,
            'description': role.description,
            'permissions': role.permissions.join(', '),
            'statusText': role.status == 'active' ? '启用' : '禁用',
            'record': role,
          },
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const paginationHeight = 104.0;
        const spacerHeight = 8.0;
        final desiredTableHeight = (widget.rowsPerPage * 68).toDouble();
        var tableHeight = desiredTableHeight;
        if (constraints.hasBoundedHeight) {
          final available =
              constraints.maxHeight - paginationHeight - spacerHeight;
          if (available.isFinite) {
            final safeAvailable = available - 16;
            tableHeight =
                math.max(0, math.min(desiredTableHeight, safeAvailable));
          }
        }
        final tableWidth = constraints.maxWidth;
        return Column(
          children: [
            TDTable(
              bordered: true,
              stripe: true,
              rowHeight: 48,
              height: tableHeight,
              width: tableWidth,
              backgroundColor: TDTheme.of(context).bgColorContainer,
              columns: [
                TDTableCol(
                  selection: true,
                  width: 56,
                  align: TDTableColAlign.center,
                  selectable: (index, row) {
                    final record = _recordAt(tableData, index);
                    if (record == null) return false;
                    return record.id != null && record.name != 'super_admin';
                  },
                  checked: (index, row) {
                    final record = _recordAt(tableData, index);
                    if (record == null) return false;
                    final id = record.id;
                    if (id == null) return false;
                    return widget.selectedIds.contains(id);
                  },
                ),
                TDTableCol(
                  title: '名称',
                  colKey: 'name',
                  ellipsis: true,
                  width: 200,
                  align: TDTableColAlign.center,
                ),
                TDTableCol(
                  title: '描述',
                  colKey: 'description',
                  width: 260,
                  align: TDTableColAlign.center,
                  cellBuilder: (_, index) {
                    final record = _recordAt(tableData, index);
                    if (record == null) return const SizedBox.shrink();
                    final text = record.description;
                    return Tooltip(
                      message: text.isEmpty ? '无描述' : text,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
                TDTableCol(
                  title: '权限',
                  colKey: 'permissions',
                  ellipsis: true,
                  align: TDTableColAlign.center,
                ),
                TDTableCol(
                  title: '状态',
                  colKey: 'statusText',
                  width: 180,
                  align: TDTableColAlign.center,
                  cellBuilder: (_, index) {
                    final record = _recordAt(tableData, index);
                    if (record == null) return const SizedBox.shrink();
                    final disabled = record.name == 'super_admin';
                    final active = record.status == 'active';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TDSwitch(
                          isOn: active,
                          enable: !disabled,
                          size: TDSwitchSize.small,
                          onChanged: (value) {
                            widget.onStatusChange(record, value);
                            return false;
                          },
                        ),
                        const SizedBox(width: 8),
                        TDText(
                          active ? '启用' : '禁用',
                          textColor: disabled
                              ? theme.textDisabledColor
                              : theme.textColorPrimary,
                        ),
                      ],
                    );
                  },
                ),
                TDTableCol(
                  title: '操作',
                  colKey: 'actions',
                  width: 180,
                  align: TDTableColAlign.center,
                  cellBuilder: (_, index) {
                    final record = _recordAt(tableData, index);
                    if (record == null) return const SizedBox.shrink();
                    final disabled = record.name == 'super_admin';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: disabled ? null : () => widget.onEdit(record),
                          child: TDText(
                            '编辑',
                            style: TextStyle(
                              color: disabled
                                  ? theme.textDisabledColor
                                  : theme.brandNormalColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap:
                              disabled ? null : () => widget.onDelete(record),
                          child: TDText(
                            '删除',
                            style: TextStyle(
                              color: disabled
                                  ? theme.textDisabledColor
                                  : theme.errorColor6,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              data: tableData,
              onSelect: (rows) {
                final next = <int>{};
                for (final row in rows ?? <dynamic>[]) {
                  if (row is Map && row['id'] is int) {
                    next.add(row['id'] as int);
                  }
                }
                for (final id in widget.selectedIds.difference(next)) {
                  widget.onSelectChange(id, false);
                }
                for (final id in next.difference(widget.selectedIds)) {
                  widget.onSelectChange(id, true);
                }
              },
            ),
            const SizedBox(height: 8),
            _buildPagination(theme),
          ],
        );
      },
    );
  }

  Widget _buildPagination(TDThemeData theme) {
    final total = widget.roles.length;
    final start = total == 0
        ? 0
        : ((_currentPage - 1) * widget.rowsPerPage) + 1;
    final end = total == 0 ? 0 : (start + _pageRecords.length - 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('每页'),
            const SizedBox(width: 6),
            DropdownButton<int>(
              value: widget.rowsPerPage,
              underline: const SizedBox.shrink(),
              items: const [5, 10, 20, 30]
                  .map(
                    (e) => DropdownMenuItem<int>(value: e, child: Text('$e')),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _currentPage = 1;
                });
                widget.onRowsPerPageChanged(value);
              },
            ),
            const SizedBox(width: 12),
            Text('显示 $start-$end / $total'),
          ],
        ),
        Row(
          children: [
            IconButton(
              tooltip: '上一页',
              onPressed: _currentPage > 1
                  ? () => setState(() {
                        _currentPage -= 1;
                      })
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('$_currentPage / $_totalPages'),
            IconButton(
              tooltip: '下一页',
              onPressed: _currentPage < _totalPages
                  ? () => setState(() {
                        _currentPage += 1;
                      })
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  RoleRecord? _recordAt(List<Map<String, dynamic>> tableData, int index) {
    if (index < 0 || index >= tableData.length) return null;
    final row = tableData[index];
    final record = row['record'];
    if (record is RoleRecord) return record;
    return null;
  }
}
