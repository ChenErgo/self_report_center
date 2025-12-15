import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

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
    final data = roles
        .map(
          (role) => {
            'id': role.id,
            'name': role.name,
            'description': role.description,
            'permissions': role.permissions.join(', '),
          },
        )
        .toList();
    final theme = TDTheme.of(context);
    final tableHeight = (rowsPerPage * 68).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth;
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
              align: TDTableColAlign.center,
              selectable: (index, row) {
                if (index < 0 || index >= roles.length) return false;
                final role = roles[index];
                return role.id != null && role.name != 'super_admin';
              },
              checked: (index, row) {
                if (index < 0 || index >= roles.length) return false;
                final id = roles[index].id;
                if (id == null) return false;
                return selectedIds.contains(id);
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
              ellipsis: true,
              width: 260,
              align: TDTableColAlign.center,
            ),
            TDTableCol(
              title: '权限',
              colKey: 'permissions',
              ellipsis: true,
              align: TDTableColAlign.center,
            ),
            TDTableCol(
              title: '操作',
              colKey: 'actions',
              width: 180,
              fixed: TDTableColFixed.right,
              align: TDTableColAlign.center,
              cellBuilder: (_, index) {
                if (index < 0 || index >= roles.length) {
                  return const SizedBox.shrink();
                }
                final role = roles[index];
                final disabled = role.name == 'super_admin';
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: disabled ? null : () => onEdit(role),
                      child: TDText(
                        '编辑',
                        style: TextStyle(
                          color: disabled ? theme.textDisabledColor : theme.brandNormalColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: disabled ? null : () => onDelete(role),
                      child: TDText(
                        '删除',
                        style: TextStyle(
                          color: disabled ? theme.textDisabledColor : theme.errorColor6,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          data: data,
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
      },
    );
  }
}
