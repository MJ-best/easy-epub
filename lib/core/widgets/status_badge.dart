import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
