import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SafetyAlertsCard extends StatelessWidget {
  const SafetyAlertsCard({super.key});

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
                child: Text('Safety Alerts',
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
                  child: Text('Site',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text('Alert Type',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text('Date',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  child: Text('Action',
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
                _buildRow('Oakwood', 'PPE Check', 'Oct 26'),
                _buildRow('Oakwood', 'PPE Check', 'Oct 26'),
                _buildRow('Oakwood', 'PPE Check', 'Oct 26'),
                _buildRow('Parkside', 'PPE Check', 'Oct 28'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String site, String alert, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(site,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: CivilTheme.textPrimary))),
          Expanded(
              flex: 2,
              child: Text(alert,
                  style: const TextStyle(
                      color: CivilTheme.textPrimary, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(date,
                  style: const TextStyle(
                      color: CivilTheme.textPrimary, fontSize: 13))),
          Expanded(
              child: const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.more_horiz,
                      color: CivilTheme.textSecondary, size: 20))),
        ],
      ),
    );
  }
}
