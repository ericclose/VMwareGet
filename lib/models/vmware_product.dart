enum VMwareProductFamily {
  workstationPro,
  fusion,
}

enum TargetPlatform {
  windows,
  linux,
  macos,
}

class VMwareReleaseItem {
  final String id;
  final VMwareProductFamily family;
  final String version;
  final String buildNumber;
  final TargetPlatform platform;
  final String platformLabel;
  final String fileName;
  final String fileSize;
  final int fileSizeBytes;
  final String releaseDate;
  final String lastUpdated;
  final String sha256;
  final String md5;
  final String officialDownloadUrl;
  final String notes;

  const VMwareReleaseItem({
    required this.id,
    required this.family,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.platformLabel,
    required this.fileName,
    required this.fileSize,
    required this.fileSizeBytes,
    required this.releaseDate,
    required this.lastUpdated,
    required this.sha256,
    required this.md5,
    required this.officialDownloadUrl,
    this.notes = 'Official Broadcom free license release for personal & commercial use.',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'family': family.name,
        'version': version,
        'buildNumber': buildNumber,
        'platform': platform.name,
        'platformLabel': platformLabel,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileSizeBytes': fileSizeBytes,
        'releaseDate': releaseDate,
        'lastUpdated': lastUpdated,
        'sha256': sha256,
        'md5': md5,
        'officialDownloadUrl': officialDownloadUrl,
        'notes': notes,
      };

  factory VMwareReleaseItem.fromJson(Map<String, dynamic> json) {
    return VMwareReleaseItem(
      id: json['id'] as String,
      family: VMwareProductFamily.values.firstWhere(
        (e) => e.name == json['family'],
        orElse: () => VMwareProductFamily.workstationPro,
      ),
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as String,
      platform: TargetPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => TargetPlatform.windows,
      ),
      platformLabel: json['platformLabel'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      releaseDate: json['releaseDate'] as String,
      lastUpdated: json['lastUpdated'] as String,
      sha256: json['sha256'] as String,
      md5: json['md5'] as String,
      officialDownloadUrl: json['officialDownloadUrl'] as String,
      notes: json['notes'] as String? ?? '',
    );
  }
}
