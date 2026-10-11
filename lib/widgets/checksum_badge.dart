import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChecksumBadge extends StatelessWidget {
  final String label;
  final String checksum;
  final IconData? icon;

  const ChecksumBadge({
    super.key,
    required this.label,
    required this.checksum,
    this.icon,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: checksum));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.verified_user_outlined,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              checksum,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Copy $label',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copyToClipboard(context),
          ),
        ],
      ),
    );
  }
}
