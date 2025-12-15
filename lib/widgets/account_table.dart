import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../data/account_model.dart';

class AccountTable extends StatefulWidget {
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
  State<AccountTable> createState() => _AccountTableState();
}

class _AccountTableState extends State<AccountTable> {
  int _currentPage = 1;

  @override
  void didUpdateWidget(covariant AccountTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final totalPages = _totalPages;
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
  }

  int get _totalPages {
    if (widget.accounts.isEmpty) return 1;
    return ((widget.accounts.length - 1) ~/ widget.rowsPerPage) + 1;
  }

  List<AccountRecord> get _pageRecords {
    final start = (_currentPage - 1) * widget.rowsPerPage;
    return widget.accounts.skip(start).take(widget.rowsPerPage).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    final pageRecords = _pageRecords;
    final tableData = pageRecords
        .map(
          (record) => {
            'id': record.id,
            'username': record.username,
            'nickname': record.nickname,
            'roles': record.roles.map((e) => e.name).join(', '),
            'statusText': record.status == 'active' ? '启用' : '禁用',
            'createdAt': record.createdAt.split('T').first,
            'record': record,
          },
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep table height within available space to avoid Column overflow.
        const paginationHeight = 104.0; // allow headroom for controls
        const spacerHeight = 8.0;
        final desiredTableHeight = (widget.rowsPerPage * 68).toDouble();
        var tableHeight = desiredTableHeight;
        if (constraints.hasBoundedHeight) {
          final available =
              constraints.maxHeight - paginationHeight - spacerHeight;
          if (available.isFinite) {
            // Leave a small cushion to avoid minor overflows from padding/margins.
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
                    return record.id != null &&
                        record.username != 'superchenergou';
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
                  title: '头像',
                  colKey: 'avatar',
                  width: 96,
                  align: TDTableColAlign.center,
                  cellBuilder: (_, index) {
                    final record = _recordAt(tableData, index);
                    if (record == null) return const SizedBox.shrink();
                    return Align(
                      alignment: Alignment.center,
                      child: _buildAvatar(record),
                    );
                  },
                ),
                TDTableCol(
                  title: '账号',
                  colKey: 'username',
                  ellipsis: true,
                  width: 180,
                  align: TDTableColAlign.center,
                ),
                TDTableCol(
                  title: '昵称',
                  colKey: 'nickname',
                  ellipsis: true,
                  width: 180,
                  align: TDTableColAlign.center,
                ),
                TDTableCol(
                  title: '角色',
                  colKey: 'roles',
                  ellipsis: false,
                  width: 280,
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
                    final disabled = record.username == 'superchenergou';
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
                  title: '创建时间',
                  colKey: 'createdAt',
                  width: 160,
                  align: TDTableColAlign.center,
                ),
                TDTableCol(
                  title: '操作',
                  colKey: 'actions',
                  width: 180,
                  // fixed: TDTableColFixed.right,
                  align: TDTableColAlign.center,
                  cellBuilder: (_, index) {
                    final record = _recordAt(tableData, index);
                    if (record == null) return const SizedBox.shrink();
                    final isSuper = record.username == 'superchenergou';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: isSuper ? null : () => widget.onEdit(record),
                          child: TDText(
                            '编辑',
                            style: TextStyle(
                              color: isSuper
                                  ? theme.textDisabledColor
                                  : theme.brandNormalColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: isSuper ? null : () => widget.onDelete(record),
                          child: TDText(
                            '删除',
                            style: TextStyle(
                              color: isSuper
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

  Widget _buildAvatar(AccountRecord record) {
    final hasAvatar =
        record.avatarPath != null &&
        record.avatarPath!.isNotEmpty &&
        File(record.avatarPath!).existsSync();
    if (hasAvatar) {
      return Container(
        width: 48,
        height: 48,
        color: Colors.grey.shade200,
        child: Image.file(File(record.avatarPath!), fit: BoxFit.cover),
      );
    }
    final bgColor = _colorFromUsername(record.username);
    final initial = record.username.isNotEmpty
        ? record.username[0].toUpperCase()
        : '?';
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      color: bgColor,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _colorFromUsername(String username) {
    final hash = username.codeUnits.fold<int>(0, (prev, e) => prev + e);
    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.deepPurple,
      Colors.green,
      Colors.orange,
      Colors.brown,
    ];
    return colors[hash % colors.length].withOpacity(0.85);
  }

  Widget _buildPagination(TDThemeData theme) {
    final total = widget.accounts.length;
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

  AccountRecord? _recordAt(List<Map<String, dynamic>> tableData, int index) {
    if (index < 0 || index >= tableData.length) return null;
    final row = tableData[index];
    final record = row['record'];
    if (record is AccountRecord) return record;
    return null;
  }
}
