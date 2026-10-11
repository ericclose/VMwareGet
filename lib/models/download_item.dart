import 'vmware_product.dart';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  verifying,
  completed,
  failed,
  cancelled,
}

enum VerificationStatus {
  notStarted,
  verifying,
  passed,
  failedMismatch,
}

class DownloadItem {
  final String id;
  final VMwareReleaseItem release;
  final String destinationPath;
  DownloadStatus status;
  VerificationStatus verificationStatus;
  int downloadedBytes;
  int totalBytes;
  double speedBytesPerSec;
  String? errorMessage;
  DateTime startedAt;
  DateTime? completedAt;

  DownloadItem({
    required this.id,
    required this.release,
    required this.destinationPath,
    this.status = DownloadStatus.queued,
    this.verificationStatus = VerificationStatus.notStarted,
    this.downloadedBytes = 0,
    required this.totalBytes,
    this.speedBytesPerSec = 0.0,
    this.errorMessage,
    required this.startedAt,
    this.completedAt,
  });

  double get progress {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  String get formattedSpeed {
    if (speedBytesPerSec <= 0) return '0 KB/s';
    if (speedBytesPerSec >= 1024 * 1024) {
      return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(speedBytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }

  String get estimatedRemainingTime {
    if (speedBytesPerSec <= 0 || downloadedBytes >= totalBytes) return '--';
    final remainingBytes = totalBytes - downloadedBytes;
    final seconds = (remainingBytes / speedBytesPerSec).round();
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes < 60) return '${minutes}m ${secs}s';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
