import '../models/vmware_product.dart';

class CatalogService {
  final List<VMwareReleaseItem> _releases = [
    // ----------------------------------------------------
    // VMware Workstation Pro 17.6.2
    // ----------------------------------------------------
    const VMwareReleaseItem(
      id: 'ws-pro-17.6.2-win',
      family: VMwareProductFamily.workstationPro,
      version: '17.6.2',
      buildNumber: '24409262',
      platform: TargetPlatform.windows,
      platformLabel: 'Windows 64-bit (.exe)',
      fileName: 'VMware-workstation-full-17.6.2-24409262.exe',
      fileSize: '596.2 MB',
      fileSizeBytes: 625184256,
      releaseDate: '2024-12-10',
      lastUpdated: '2024-12-10',
      sha256:
          '64a787a718b534b8c62c93d56ebf7b11ee0db4742a7a8d9bcead9b068da6c3e7',
      md5: '02ea44109db8ce4d59fdbb341f938fa2',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
      notes:
          'Maintenance release with security and guest OS support fixes. Free license for commercial and personal use.',
    ),
    const VMwareReleaseItem(
      id: 'ws-pro-17.6.2-linux',
      family: VMwareProductFamily.workstationPro,
      version: '17.6.2',
      buildNumber: '24409262',
      platform: TargetPlatform.linux,
      platformLabel: 'Linux 64-bit (.bundle)',
      fileName: 'VMware-Workstation-Full-17.6.2-24409262.x86_64.bundle',
      fileSize: '512.8 MB',
      fileSizeBytes: 537713664,
      releaseDate: '2024-12-10',
      lastUpdated: '2024-12-10',
      sha256:
          '816174bb0500be87e6fa50e82c5f5904fc1b016d934bb04909a3dc52778ca9ce',
      md5: '37a9170884df002d2948eb309062eb29',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
      notes:
          'Linux kernel compatibility updates. Official Broadcom installer bundle.',
    ),

    // ----------------------------------------------------
    // VMware Workstation Pro 17.6.1
    // ----------------------------------------------------
    const VMwareReleaseItem(
      id: 'ws-pro-17.6.1-win',
      family: VMwareProductFamily.workstationPro,
      version: '17.6.1',
      buildNumber: '24319023',
      platform: TargetPlatform.windows,
      platformLabel: 'Windows 64-bit (.exe)',
      fileName: 'VMware-workstation-full-17.6.1-24319023.exe',
      fileSize: '594.1 MB',
      fileSizeBytes: 622958080,
      releaseDate: '2024-10-15',
      lastUpdated: '2024-10-15',
      sha256:
          '94c6530a6c6e76bc063f9cfbdfbc2ec20fa5bb8a4d402bc0f7194f475a89ebcb',
      md5: '8b14c9f132e4d0b2fbe0e2e92a4a7541',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
      notes:
          'Resolved stability issues and multi-monitor display glitches on Windows 11 24H2.',
    ),
    const VMwareReleaseItem(
      id: 'ws-pro-17.6.1-linux',
      family: VMwareProductFamily.workstationPro,
      version: '17.6.1',
      buildNumber: '24319023',
      platform: TargetPlatform.linux,
      platformLabel: 'Linux 64-bit (.bundle)',
      fileName: 'VMware-Workstation-Full-17.6.1-24319023.x86_64.bundle',
      fileSize: '511.4 MB',
      fileSizeBytes: 536248320,
      releaseDate: '2024-10-15',
      lastUpdated: '2024-10-15',
      sha256:
          '1a1ea865d6ecf5b0adcf997be34079ee77464a4d6409fe6eec4e1f72a4f6be5d',
      md5: '028ca433a4faef8497d3f8fc94c7a2ee',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
      notes:
          'Resolved build issues with Linux kernel 6.10 and GCC 14.',
    ),

    // ----------------------------------------------------
    // VMware Workstation Pro 17.6.0
    // ----------------------------------------------------
    const VMwareReleaseItem(
      id: 'ws-pro-17.6.0-win',
      family: VMwareProductFamily.workstationPro,
      version: '17.6.0',
      buildNumber: '24238078',
      platform: TargetPlatform.windows,
      platformLabel: 'Windows 64-bit (.exe)',
      fileName: 'VMware-workstation-full-17.6.0-24238078.exe',
      fileSize: '592.5 MB',
      fileSizeBytes: 621281280,
      releaseDate: '2024-09-03',
      lastUpdated: '2024-09-03',
      sha256:
          '36ff8b54439cff2940263fca67be567a13c348f0665ba5d11707ea996b12a874',
      md5: 'e3d7a965d1d6a66699eb31c19b84177b',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
      notes:
          'Major update introducing enhanced TPM 2.0 virtualization and updated host OS support.',
    ),
    const VMwareReleaseItem(
      id: 'ws-pro-17.6.0-linux',
      family: VMwareProductFamily.workstationPro,
      version: '17.6.0',
      buildNumber: '24238078',
      platform: TargetPlatform.linux,
      platformLabel: 'Linux 64-bit (.bundle)',
      fileName: 'VMware-Workstation-Full-17.6.0-24238078.x86_64.bundle',
      fileSize: '510.1 MB',
      fileSizeBytes: 534886400,
      releaseDate: '2024-09-03',
      lastUpdated: '2024-09-03',
      sha256:
          'c8d19d2fcba60eb72c050d2bc43632cf4b95f001c9a099a5e2f7b88018e69229',
      md5: 'd866a2f4cf03ebff8e3e4eb651c6e1ca',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
      notes:
          'Major release with support for Ubuntu 24.04 and Fedora 40.',
    ),

    // ----------------------------------------------------
    // VMware Workstation Pro 17.5.2
    // ----------------------------------------------------
    const VMwareReleaseItem(
      id: 'ws-pro-17.5.2-win',
      family: VMwareProductFamily.workstationPro,
      version: '17.5.2',
      buildNumber: '23775571',
      platform: TargetPlatform.windows,
      platformLabel: 'Windows 64-bit (.exe)',
      fileName: 'VMware-workstation-full-17.5.2-23775571.exe',
      fileSize: '575.4 MB',
      fileSizeBytes: 603348992,
      releaseDate: '2024-05-14',
      lastUpdated: '2024-05-14',
      sha256:
          '1f2a3cfefd3f82ee913ef0fa3be895b6d5162a4d3ff537b0292bf188cfcaad19',
      md5: '77626cecfc92f763bc72aa62f6b5b5c5',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
      notes:
          'First release featuring Broadcom free personal & commercial use license option.',
    ),
    const VMwareReleaseItem(
      id: 'ws-pro-17.5.2-linux',
      family: VMwareProductFamily.workstationPro,
      version: '17.5.2',
      buildNumber: '23775571',
      platform: TargetPlatform.linux,
      platformLabel: 'Linux 64-bit (.bundle)',
      fileName: 'VMware-Workstation-Full-17.5.2-23775571.x86_64.bundle',
      fileSize: '498.2 MB',
      fileSizeBytes: 522434560,
      releaseDate: '2024-05-14',
      lastUpdated: '2024-05-14',
      sha256:
          '4bb0e18d6e9bcfeec6c5a2a2253380e2f5b40cfeb5c9c9913197f2613d9cf2ef',
      md5: '1d9c79e6f3b06c88ca88b0d39e7caec4',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
      notes:
          'Initial free licensing transition build for Linux users.',
    ),

    // ----------------------------------------------------
    // VMware Fusion 13.6.2
    // ----------------------------------------------------
    const VMwareReleaseItem(
      id: 'fusion-13.6.2-macos',
      family: VMwareProductFamily.fusion,
      version: '13.6.2',
      buildNumber: '24409261',
      platform: TargetPlatform.macos,
      platformLabel: 'macOS Universal (.dmg)',
      fileName: 'VMware-Fusion-13.6.2-24409261_universal.dmg',
      fileSize: '685.4 MB',
      fileSizeBytes: 718698496,
      releaseDate: '2024-12-10',
      lastUpdated: '2024-12-10',
      sha256:
          'a9cfb058a97be48763f03b543c98889aa046a39d501255e3a35ea2518e388137',
      md5: 'e52ca0c40e1f72cf0e33be327732a316',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Fusion&freeDownloads=true',
      notes:
          'Optimized for macOS Sequoia 15.2 and Apple Silicon M1/M2/M3/M4 + Intel Macs.',
    ),

    // ----------------------------------------------------
    // VMware Fusion 13.6.1
    // ----------------------------------------------------
    const VMwareReleaseItem(
      id: 'fusion-13.6.1-macos',
      family: VMwareProductFamily.fusion,
      version: '13.6.1',
      buildNumber: '24319021',
      platform: TargetPlatform.macos,
      platformLabel: 'macOS Universal (.dmg)',
      fileName: 'VMware-Fusion-13.6.1-24319021_universal.dmg',
      fileSize: '682.1 MB',
      fileSizeBytes: 715239424,
      releaseDate: '2024-10-15',
      lastUpdated: '2024-10-15',
      sha256:
          '78e9999056c701fc3e5953051fe444585c54e0ad3d1f03d15442ee04ba3ae5d5',
      md5: '6db5ca71ef0179a95015e1281db2b271',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Fusion&freeDownloads=true',
      notes:
          'Security fixes and enhanced 3D graphics acceleration on macOS Sequoia.',
    ),

    // ----------------------------------------------------
    // VMware Fusion 13.6.0
    // ----------------------------------------------------
    const VMwareReleaseItem(
      id: 'fusion-13.6.0-macos',
      family: VMwareProductFamily.fusion,
      version: '13.6.0',
      buildNumber: '24238079',
      platform: TargetPlatform.macos,
      platformLabel: 'macOS Universal (.dmg)',
      fileName: 'VMware-Fusion-13.6.0-24238079_universal.dmg',
      fileSize: '679.8 MB',
      fileSizeBytes: 712826880,
      releaseDate: '2024-09-03',
      lastUpdated: '2024-09-03',
      sha256:
          '272b535d259fa6ee155d58caee566d5b035123d58daecdd216cb030999aa7f8e',
      md5: '1d2932e604f387ef92ee020c939fa5a9',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Fusion&freeDownloads=true',
      notes:
          'Full macOS Sequoia compatibility and improved virtual network stack.',
    ),

    // ----------------------------------------------------
    // VMware Fusion 13.5.2
    // ----------------------------------------------------
    const VMwareReleaseItem(
      id: 'fusion-13.5.2-macos',
      family: VMwareProductFamily.fusion,
      version: '13.5.2',
      buildNumber: '23775686',
      platform: TargetPlatform.macos,
      platformLabel: 'macOS Universal (.dmg)',
      fileName: 'VMware-Fusion-13.5.2-23775686_universal.dmg',
      fileSize: '671.0 MB',
      fileSizeBytes: 703594496,
      releaseDate: '2024-05-14',
      lastUpdated: '2024-05-14',
      sha256:
          '8182b81d77a80c98f82f8d839bbcb49257d079366dfef3d002e1b12b509bc737',
      md5: 'b56e6dcf88f28c11aa5051aa7424ad55',
      officialDownloadUrl:
          'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Fusion&freeDownloads=true',
      notes:
          'Milestone release declaring VMware Fusion Pro free for all commercial & personal users.',
    ),
  ];

  List<VMwareReleaseItem> getAllReleases() => List.unmodifiable(_releases);

  List<VMwareReleaseItem> getReleasesForFamily(VMwareProductFamily family) {
    return _releases.where((r) => r.family == family).toList();
  }

  List<VMwareReleaseItem> searchReleases({
    required VMwareProductFamily family,
    String? query,
    TargetPlatform? platform,
  }) {
    return _releases.where((item) {
      if (item.family != family) return false;
      if (platform != null && item.platform != platform) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesVersion = item.version.toLowerCase().contains(q);
        final matchesBuild = item.buildNumber.toLowerCase().contains(q);
        final matchesFile = item.fileName.toLowerCase().contains(q);
        final matchesPlatform = item.platformLabel.toLowerCase().contains(q);
        return matchesVersion || matchesBuild || matchesFile || matchesPlatform;
      }
      return true;
    }).toList();
  }
}
