import 'package:flutter/material.dart';
import '../theme.dart';

class CivilDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;

  const CivilDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CivilTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CivilTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(CivilTheme.surface),
          dataRowColor: WidgetStateProperty.all(CivilTheme.card),
          dividerThickness: 1,
          horizontalMargin: 24,
          columnSpacing: 32,
          headingTextStyle: const TextStyle(
            color: CivilTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          dataTextStyle: const TextStyle(
            color: CivilTheme.textPrimary,
            fontSize: 14,
          ),
          columns: columns.map((col) => DataColumn(label: Text(col))).toList(),
          rows: rows.map((rowCells) {
            return DataRow(
              cells: rowCells.map((cell) => DataCell(cell)).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
