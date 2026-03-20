import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const Spacer(),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: theme.textTheme.headlineMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
