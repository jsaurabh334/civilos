import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AIInsightCard extends StatelessWidget {
  final String title;
  final String insight;
  final VoidCallback onAction;
  
  const AIInsightCard({
    super.key, 
    required this.title, 
    required this.insight,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B), // Deep purple for AI
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6D28D9)), // Violet border
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(FontAwesomeIcons.wandMagicSparkles, color: Color(0xFFC4B5FD)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFEEDDFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insight,
                  style: const TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const FaIcon(FontAwesomeIcons.bolt, size: 14),
                  label: const Text('Apply Suggestion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
