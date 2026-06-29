import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final int total;
  final int newCount;
  final int flagged;
  final int resolved;

  const StatsRow({
    super.key,
    required this.total,
    required this.newCount,
    required this.flagged,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we should use a row layout (wide screens) or grid (smaller screens)
        final isWide = constraints.maxWidth > 600;
        final cards = [
          _StatCard(label: 'Total Reports',  value: total,    color: Colors.blue,   icon: Icons.article_outlined),
          _StatCard(label: 'New',            value: newCount, color: Colors.orange,  icon: Icons.mark_email_unread_outlined),
          _StatCard(label: 'Flagged',        value: flagged,  color: Colors.red,     icon: Icons.flag_outlined),
          _StatCard(label: 'Resolved',       value: resolved, color: Colors.green,   icon: Icons.check_circle_outline),
        ];

        if (isWide) {
          // Use horizontal row layout on wide screens
          return Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: c,
                      ),
                    ))
                .toList(),
          );
        }
        // Use grid layout on smaller screens
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: cards,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}