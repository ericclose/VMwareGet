import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/diagnostic_service.dart';

class DiagnosticDialog extends StatefulWidget {
  const DiagnosticDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const DiagnosticDialog(),
    );
  }

  @override
  State<DiagnosticDialog> createState() => _DiagnosticDialogState();
}

class _DiagnosticDialogState extends State<DiagnosticDialog> {
  final _scrollController = ScrollController();
  DiagnosticLogLevel? _filterLevel;
  String _searchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copyAllLogs() async {
    final l10n = AppLocalizations.of(context);
    final text = DiagnosticService.instance.exportFormattedLogs();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(l10n.copiedLogLines(DiagnosticService.instance.entries.length)),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: DiagnosticService.instance,
      builder: (context, _) {
        final allEntries = DiagnosticService.instance.entries;
        final filtered = allEntries.where((e) {
          if (_filterLevel != null && e.level != _filterLevel) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return e.message.toLowerCase().contains(q) ||
                e.tag.toLowerCase().contains(q) ||
                (e.details?.toLowerCase().contains(q) ?? false);
          }
          return true;
        }).toList();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 820,
              maxHeight: 640,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title & Top Actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.bug_report_rounded,
                          size: 20,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.diagnosticLogsTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.diagnosticSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(l10n.copyAllLogs),
                        onPressed: allEntries.isEmpty ? null : _copyAllLogs,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: l10n.close,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search & Level Filter
                  Row(
                    children: [
                      Expanded(
                        child: SearchBar(
                          hintText: l10n.filterLogsHint,
                          leading: const Icon(Icons.search_rounded, size: 18),
                          elevation: const WidgetStatePropertyAll(0),
                          backgroundColor: WidgetStatePropertyAll(
                            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SegmentedButton<DiagnosticLogLevel?>(
                        segments: [
                          ButtonSegment(value: null, label: Text(l10n.filterAll)),
                          const ButtonSegment(value: DiagnosticLogLevel.http, label: Text('HTTP')),
                          ButtonSegment(value: DiagnosticLogLevel.error, label: Text(l10n.filterErrors)),
                        ],
                        selected: {_filterLevel},
                        onSelectionChanged: (set) {
                          setState(() => _filterLevel = set.first);
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: l10n.clearLogs,
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        onPressed: allEntries.isEmpty
                            ? null
                            : () => DiagnosticService.instance.clear(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Log Entries Viewer
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141619) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                          width: 0.8,
                        ),
                      ),
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                allEntries.isEmpty
                                    ? l10n.noLogsYet
                                    : l10n.noLogsMatching,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 10,
                                  thickness: 0.5,
                                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                ),
                                itemBuilder: (ctx, i) {
                                  final entry = filtered[i];
                                  return _buildLogItem(context, entry, isDark);
                                },
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Footer summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total records: ${allEntries.length} | Filtered: ${filtered.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.copy_all_rounded, size: 14),
                        label: const Text('Copy to Clipboard', style: TextStyle(fontSize: 12)),
                        onPressed: allEntries.isEmpty ? null : _copyAllLogs,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogItem(BuildContext context, DiagnosticLogEntry entry, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color badgeColor;
    Color badgeTextColor;
    switch (entry.level) {
      case DiagnosticLogLevel.info:
        badgeColor = Colors.blue.withValues(alpha: 0.15);
        badgeTextColor = isDark ? Colors.lightBlueAccent : Colors.blue.shade800;
        break;
      case DiagnosticLogLevel.http:
        badgeColor = Colors.purple.withValues(alpha: 0.15);
        badgeTextColor = isDark ? Colors.purpleAccent : Colors.purple.shade800;
        break;
      case DiagnosticLogLevel.warning:
        badgeColor = Colors.amber.withValues(alpha: 0.15);
        badgeTextColor = isDark ? Colors.amberAccent : Colors.amber.shade900;
        break;
      case DiagnosticLogLevel.error:
        badgeColor = Colors.red.withValues(alpha: 0.15);
        badgeTextColor = isDark ? Colors.redAccent : Colors.red.shade800;
        break;
    }

    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}.${entry.timestamp.millisecond.toString().padLeft(3, '0')}';

    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '[$timeStr] ',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.levelLabel,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.tag,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          TextSpan(
            text: entry.message,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          if (entry.details != null && entry.details!.isNotEmpty) ...[
            const TextSpan(text: '\n'),
            TextSpan(
              text: '   ↳ ${entry.details}',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
