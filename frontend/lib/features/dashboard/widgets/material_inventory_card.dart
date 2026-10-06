import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class MaterialInventoryCard extends StatelessWidget {
  const MaterialInventoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Material Inventory',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CivilTheme.textPrimary)),
              ),
              Icon(Icons.more_horiz, color: CivilTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text('Item',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  child: Text('Status',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text('Quantity',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary),
                      textAlign: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: CivilTheme.border, height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildRow(
                    'Steel Beams', 'Green', CivilTheme.secondary, '145/200'),
                _buildRow(
                    'Concrete', 'Yellow', CivilTheme.warning, '800/1000m³'),
                _buildRow('Bridge', 'Green', CivilTheme.secondary, '145/200'),
                _buildRow(
                    'Parkside', 'Green', CivilTheme.secondary, '800/1000m³'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String item, String status, Color color, String qty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(item,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: CivilTheme.textPrimary))),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(status,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(qty,
                  style: const TextStyle(
                      fontSize: 13, color: CivilTheme.textPrimary),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
