import 'package:flutter/material.dart';

/// Reusable status badge widget for displaying invoice/payment status
/// 
/// Example:
/// ```dart
/// statusBadge('paid')      // Green badge: PAID
/// statusBadge('overdue')   // Red badge: OVERDUE
/// statusBadge('partial')   // Purple badge: PARTIAL
/// statusBadge('unpaid')    // Orange badge: UNPAID
/// ```
Widget statusBadge(String status, {double? fontSize, EdgeInsets? padding}) {
  Color color;
  String displayText = status.toUpperCase();
  
  switch (status.toLowerCase()) {
    case 'paid':
      color = Colors.green;
      break;
    case 'overdue':
      color = Colors.red;
      break;
    case 'partial':
      color = Colors.purple;
      break;
    case 'draft':
      color = Colors.grey;
      break;
    case 'sent':
      color = Colors.blue;
      break;
    case 'unpaid':
    default:
      color = Colors.orange;
  }

  return Container(
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Text(
      displayText,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: fontSize ?? 12,
      ),
    ),
  );
}

/// Extended status badge with icon
class StatusBadgeWithIcon extends StatelessWidget {
  final String status;
  final double? fontSize;
  final EdgeInsets? padding;
  final bool showIcon;

  const StatusBadgeWithIcon({
    Key? key,
    required this.status,
    this.fontSize,
    this.padding,
    this.showIcon = true,
  }) : super(key: key);

  IconData _getIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'overdue':
        return Icons.error;
      case 'partial':
        return Icons.pending_actions;
      case 'draft':
        return Icons.description;
      case 'sent':
        return Icons.send;
      case 'unpaid':
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'overdue':
        color = Colors.red;
        break;
      case 'partial':
        color = Colors.purple;
        break;
      case 'draft':
        color = Colors.grey;
        break;
      case 'sent':
        color = Colors.blue;
        break;
      case 'unpaid':
      default:
        color = Colors.orange;
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getIconForStatus(status),
              color: color,
              size: fontSize ?? 14,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: fontSize ?? 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact status chip for list items
class StatusChip extends StatelessWidget {
  final String status;
  final VoidCallback? onTap;
  final bool dense;

  const StatusChip({
    Key? key,
    required this.status,
    this.onTap,
    this.dense = false,
  }) : super(key: key);

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'partial':
        return Colors.purple;
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'unpaid':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(status);
    
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: dense ? 10 : 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(
        color: color.withOpacity(0.3),
        width: 1,
      ),
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onDeleted: onTap != null ? () => onTap!() : null,
    );
  }
}

/// Status badge with customizable colors
class CustomStatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final double? fontSize;
  final EdgeInsets? padding;
  final bool showBorder;

  const CustomStatusBadge({
    Key? key,
    required this.status,
    required this.color,
    this.fontSize,
    this.padding,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: showBorder
            ? Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: fontSize ?? 12,
        ),
      ),
    );
  }
}
