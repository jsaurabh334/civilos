import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ScheduleVarianceCard extends StatelessWidget {
  const ScheduleVarianceCard({super.key});

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
                child: Text('Schedule Variance',
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
                  child: Text('3 Projects',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  child: Text('+3 days',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  child: Text('-2 days',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  child: Text('9 Days',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  child: Text('13 days',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
            ],
          ),
          const SizedBox(height: 16),
          _buildRow('Oakwood', 0.1, 0.6, CivilTheme.primary, '+3 days',
              CivilTheme.error),
          _buildRow('Bridge', 0.4, 0.2, CivilTheme.secondary, '-2 days',
              CivilTheme.secondary),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Parkside',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: CivilTheme.textPrimary))),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: CivilTheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('On Schedule',
                          style: TextStyle(
                              color: CivilTheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRow(String title, double offset, double width, Color color,
      String label, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: CivilTheme.textPrimary))),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (offset > 0) Spacer(flex: (offset * 10).toInt()),
                Expanded(
                  flex: (width * 10).toInt(),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
                if ((1 - offset - width) > 0)
                  Spacer(flex: ((1 - offset - width) * 10).toInt()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
