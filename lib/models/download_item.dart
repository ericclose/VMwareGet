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
  String? directDownloadUrl;

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
    this.directDownloadUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'release': release.toJson(),
        'destinationPath': destinationPath,
        'status': status.name,
        'verificationStatus': verificationStatus.name,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'speedBytesPerSec': speedBytesPerSec,
        'errorMessage': errorMessage,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'directDownloadUrl': directDownloadUrl,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    var stat = DownloadStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => DownloadStatus.paused,
    );
    if (stat == DownloadStatus.downloading ||
        stat == DownloadStatus.verifying ||
        stat == DownloadStatus.queued) {
      stat = DownloadStatus.paused;
    }

    final verStat = VerificationStatus.values.firstWhere(
      (e) => e.name == json['verificationStatus'],
      orElse: () => VerificationStatus.notStarted,
    );

    return DownloadItem(
      id: json['id'] as String,
      release:
          VMwareReleaseItem.fromJson(json['release'] as Map<String, dynamic>),
      destinationPath: json['destinationPath'] as String,
      status: stat,
      verificationStatus: verStat,
      downloadedBytes: (json['downloadedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      speedBytesPerSec: 0.0,
      errorMessage: json['errorMessage'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      directDownloadUrl: json['directDownloadUrl'] as String?,
    );
  }

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
