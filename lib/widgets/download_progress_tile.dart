import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/download_item.dart';
import '../providers/auth_provider.dart';
import '../providers/download_provider.dart';
import '../services/download_service.dart';
import '../utils/formatters.dart';
import '../views/login_dialog.dart';

class DownloadProgressTile extends StatelessWidget {
  final DownloadItem item;

  const DownloadProgressTile({
    super.key,
    required this.item,
  });

  Widget _buildStatusChip(BuildContext context, bool fileExists) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    if (item.status == DownloadStatus.verifying ||
        item.verificationStatus == VerificationStatus.verifying) {
      final bg = Colors.amber.withValues(alpha: 0.2);
      final fg = Colors.amber.shade900;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.statusVerifying,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (item.status) {
      case DownloadStatus.downloading:
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        label = l10n.statusDownloading;
        icon = Icons.downloading_rounded;
        break;
      case DownloadStatus.paused:
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
        label = l10n.statusPaused;
        icon = Icons.pause_circle_outline_rounded;
        break;
      case DownloadStatus.verifying:
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amber.shade900;
        label = l10n.statusVerifying;
        icon = Icons.security_rounded;
        break;
      case DownloadStatus.completed:
        if (!fileExists) {
          bg = colorScheme.errorContainer;
          fg = colorScheme.onErrorContainer;
          label = l10n.statusFileNotFound;
          icon = Icons.file_copy_outlined;
        } else if (item.verificationStatus == VerificationStatus.passed) {
          bg = Colors.green.withValues(alpha: 0.2);
          fg = Colors.green.shade800;
          label = l10n.statusPassed;
          icon = Icons.verified_rounded;
        } else if (item.verificationStatus ==
            VerificationStatus.failedMismatch) {
          bg = colorScheme.errorContainer;
          fg = colorScheme.onErrorContainer;
          label = l10n.statusMismatch;
          icon = Icons.gpp_bad_rounded;
        } else {
          bg = Colors.green.withValues(alpha: 0.2);
          fg = Colors.green.shade800;
          label = l10n.statusCompleted;
          icon = Icons.check_circle_rounded;
        }
        break;
      case DownloadStatus.failed:
        bg = colorScheme.errorContainer;
        fg = colorScheme.onErrorContainer;
        label = l10n.statusFailed;
        icon = Icons.error_outline_rounded;
        break;
      case DownloadStatus.queued:
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
        label = l10n.statusQueued;
        icon = Icons.hourglass_top_rounded;
        break;
      case DownloadStatus.cancelled:
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
        label = l10n.statusCancelled;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final authSession = Provider.of<AuthProvider>(context, listen: false).currentSession;

    final percent = (item.progress * 100).toStringAsFixed(1);
    final fileExists = File(item.destinationPath).existsSync();
    final isVerifying = item.status == DownloadStatus.verifying ||
        item.verificationStatus == VerificationStatus.verifying;
    final isCompleted = item.status == DownloadStatus.completed && !isVerifying;
    final isFileMissing = isCompleted && !fileExists;
    final isMismatch = isCompleted && fileExists && item.verificationStatus == VerificationStatus.failedMismatch;
    final isPassed = isCompleted && fileExists && item.verificationStatus == VerificationStatus.passed;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isVerifying
              ? Colors.amber.withValues(alpha: 0.7)
              : ((isFileMissing || isMismatch)
                  ? colorScheme.error
                  : (isPassed
                      ? Colors.green.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant.withValues(alpha: 0.4))),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: File name & Status Chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.release.fileName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${item.destinationPath}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(context, fileExists),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: isVerifying ? null : item.progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isVerifying
                      ? Colors.amber.shade700
                      : ((isFileMissing || isMismatch)
                          ? colorScheme.error
                          : (isPassed
                              ? Colors.green
                              : colorScheme.primary)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Metrics row: Downloaded / Total, Speed, ETA
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '${Formatters.formatBytes(item.downloadedBytes)} / ${Formatters.formatBytes(item.totalBytes)} ($percent%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.status == DownloadStatus.downloading)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${l10n.speedLabel}: ${item.formattedSpeed}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${l10n.etaLabel}: ${item.estimatedRemainingTime}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (isFileMissing) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.localFileNotFoundTip,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (item.errorMessage != null) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final isAuthError = item.errorMessage!.toLowerCase().contains('expired') ||
                      item.errorMessage!.toLowerCase().contains('re-login') ||
                      item.errorMessage!.toLowerCase().contains('session') ||
                      item.errorMessage!.toLowerCase().contains('unauthor');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAuthError ? Icons.lock_clock_outlined : Icons.warning_amber_rounded,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAuthError ? l10n.broadcomSessionExpiredTip : item.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (isAuthError) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const LoginDialog(),
                              );
                            },
                            child: Text(
                              l10n.reloginAction,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action buttons
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 460;

                final copyLinkButton = IconButton(
                  tooltip: l10n.copyDirectDownloadLink,
                  icon: const Icon(Icons.link_rounded, size: 20),
                  onPressed: () async {
                    final scaffold = ScaffoldMessenger.of(context);
                    scaffold.hideCurrentSnackBar();
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.generatingDownloadLink),
                          ],
                        ),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    try {
                      final url = await downloadProvider.resolveDownloadUrl(
                        release: item.release,
                        session: authSession,
                      );

                      await Clipboard.setData(ClipboardData(text: url));

                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text(l10n.copyDirectDownloadLinkSuccess),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } on BroadcomAuthExpiredException catch (_) {
                      scaffold.hideCurrentSnackBar();
                      if (context.mounted) {
                        scaffold.showSnackBar(
                          SnackBar(
                            backgroundColor: colorScheme.error,
                            content: Text(l10n.broadcomSessionExpiredTip),
                            action: SnackBarAction(
                              label: l10n.reloginAction,
                              textColor: Colors.amberAccent,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const LoginDialog(),
                                );
                              },
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 6),
                          ),
                        );
                      }
                    } catch (e) {
                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );

                final deleteButton = IconButton(
                  tooltip: l10n.deleteRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: () {
                    downloadProvider.deleteDownload(
                      id: item.id,
                      deleteLocalFile: false,
                    );
                  },
                );

                final showInFolderButton = OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: Text(
                    Platform.isMacOS ? l10n.showInFinder : l10n.showInFolder,
                  ),
                  onPressed: () =>
                      downloadProvider.openContainingFolder(item.id),
                );

                final reVerifyButton = OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.reVerifyChecksum),
                  onPressed: () =>
                      downloadProvider.reVerifyChecksum(item.id),
                );

                final reDownloadButton = FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.reDownload),
                  onPressed: () => downloadProvider.redownload(
                    id: item.id,
                    session: authSession,
                  ),
                );

                final openInstallerButton = FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.launch_rounded, size: 16),
                  label: Text(l10n.openInstaller),
                  onPressed: () async {
                    final opened =
                        await downloadProvider.openDownloadedFile(item.id);
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.fileNotFound),
                          backgroundColor: colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );

                final verifyingButton = OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: Text(l10n.statusVerifying),
                  onPressed: null,
                );

                final pauseButton = OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.pause_rounded, size: 16),
                  label: Text(l10n.pause),
                  onPressed: () => downloadProvider.pauseDownload(item.id),
                );

                final resumeButton = FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: Text(l10n.resumeRetry),
                  onPressed: () => downloadProvider.resumeDownload(
                    id: item.id,
                    session: authSession,
                    sessionCookie: authSession?.cookieJar ??
                        authSession?.sessionToken,
                  ),
                );

                if (isCompact) {
                  if (isVerifying) {
                    return Row(
                      children: [
                        Expanded(child: verifyingButton),
                        const SizedBox(width: 4),
                        copyLinkButton,
                        deleteButton,
                      ],
                    );
                  } else if (item.status == DownloadStatus.completed) {
                    if (isFileMissing) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: showInFolderButton),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: reDownloadButton),
                              const SizedBox(width: 4),
                              copyLinkButton,
                              deleteButton,
                            ],
                          ),
                        ],
                      );
                    } else if (isMismatch) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: showInFolderButton),
                              const SizedBox(width: 8),
                              Expanded(child: reVerifyButton),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: reDownloadButton),
                              const SizedBox(width: 4),
                              copyLinkButton,
                              deleteButton,
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Normal completed
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: showInFolderButton),
                              const SizedBox(width: 8),
                              Expanded(child: reVerifyButton),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: openInstallerButton),
                              const SizedBox(width: 4),
                              copyLinkButton,
                              deleteButton,
                            ],
                          ),
                        ],
                      );
                    }
                  } else if (item.status == DownloadStatus.downloading) {
                    return Row(
                      children: [
                        Expanded(child: pauseButton),
                        const SizedBox(width: 4),
                        copyLinkButton,
                        deleteButton,
                      ],
                    );
                  } else if (item.status == DownloadStatus.paused ||
                      item.status == DownloadStatus.failed) {
                    return Row(
                      children: [
                        Expanded(child: resumeButton),
                        const SizedBox(width: 4),
                        copyLinkButton,
                        deleteButton,
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      copyLinkButton,
                      deleteButton,
                    ],
                  );
                }

                return Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (isVerifying)
                        verifyingButton
                      else if (item.status == DownloadStatus.completed) ...[
                        if (isFileMissing) ...[
                          reDownloadButton,
                          showInFolderButton,
                        ] else if (isMismatch) ...[
                          reDownloadButton,
                          reVerifyButton,
                          showInFolderButton,
                        ] else ...[
                          showInFolderButton,
                          reVerifyButton,
                          openInstallerButton,
                        ],
                      ] else if (item.status == DownloadStatus.downloading)
                        pauseButton
                      else if (item.status == DownloadStatus.paused ||
                          item.status == DownloadStatus.failed)
                        resumeButton,
                      copyLinkButton,
                      deleteButton,
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
