import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

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
    final tableData = accounts
        .map(
          (record) => {
            'id': record.id,
            'username': record.username,
            'role': record.role,
            'roleNames': record.roles.map((e) => e.name).join(', '),
            'statusText': record.status == 'active' ? '启用' : '禁用',
            'createdAt': record.createdAt.split('T').first,
          },
        )
        .toList();
    final theme = TDTheme.of(context);
    final tableHeight = (rowsPerPage * 68).toDouble();
    final tableWidth = MediaQuery.of(context).size.width;

    return TDTable(
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
          selectable: (index, row) {
            if (index < 0 || index >= accounts.length) return false;
            final record = accounts[index];
            return record.id != null && record.username != 'superchenergou';
          },
          checked: (index, row) {
            if (index < 0 || index >= accounts.length) return false;
            final id = accounts[index].id;
            if (id == null) return false;
            return selectedIds.contains(id);
          },
        ),
        TDTableCol(
          title: '头像',
          colKey: 'avatar',
          width: 88,
          cellBuilder: (_, index) {
            if (index < 0 || index >= accounts.length) {
              return const SizedBox.shrink();
            }
            final record = accounts[index];
            final hasAvatar = record.avatarPath != null &&
                record.avatarPath!.isNotEmpty &&
                File(record.avatarPath!).existsSync();
            return Container(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 44,
                height: 44,
                color: Colors.grey.shade200,
                child: hasAvatar
                    ? Image.file(File(record.avatarPath!), fit: BoxFit.cover)
                    : const Icon(Icons.person, size: 22, color: Colors.grey),
              ),
            );
          },
        ),
        TDTableCol(title: '账号', colKey: 'username', ellipsis: true, width: 160),
        TDTableCol(title: '角色', colKey: 'role', ellipsis: true, width: 120),
        TDTableCol(
          title: '角色列表',
          colKey: 'roleNames',
          ellipsis: true,
          width: 260,
        ),
        TDTableCol(
          title: '状态',
          colKey: 'statusText',
          width: 160,
          cellBuilder: (_, index) {
            if (index < 0 || index >= accounts.length) {
              return const SizedBox.shrink();
            }
            final record = accounts[index];
            final disabled = record.username == 'superchenergou';
            final active = record.status == 'active';
            return Row(
              children: [
                TDSwitch(
                  isOn: active,
                  enable: !disabled,
                  size: TDSwitchSize.small,
                  onChanged: (value) {
                    onStatusChange(record, value);
                    return false;
                  },
                ),
                const SizedBox(width: 8),
                TDText(
                  active ? '启用' : '禁用',
                  textColor: disabled ? theme.textDisabledColor : theme.textColorPrimary,
                ),
              ],
            );
          },
        ),
        TDTableCol(title: '创建时间', colKey: 'createdAt', width: 140),
        TDTableCol(
          title: '操作',
          colKey: 'actions',
          width: 180,
          fixed: TDTableColFixed.right,
          cellBuilder: (_, index) {
            if (index < 0 || index >= accounts.length) {
              return const SizedBox.shrink();
            }
            final record = accounts[index];
            final isSuper = record.username == 'superchenergou';
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: isSuper ? null : () => onEdit(record),
                  child: TDText(
                    '编辑',
                    style: TextStyle(
                      color: isSuper ? theme.textDisabledColor : theme.brandNormalColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: isSuper ? null : () => onDelete(record),
                  child: TDText(
                    '删除',
                    style: TextStyle(
                      color: isSuper ? theme.textDisabledColor : theme.errorColor6,
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
        for (final id in selectedIds.difference(next)) {
          onSelectChange(id, false);
        }
        for (final id in next.difference(selectedIds)) {
          onSelectChange(id, true);
        }
      },
    );
  }
}
