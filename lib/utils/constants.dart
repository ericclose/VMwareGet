class AppConstants {
  static const String appName = 'VMwareGet';
  static const String appId = 'io.github.vmwareget';
  static const String appVersion = '1.0.0';

  // Broadcom Portal Endpoints
  static const String workstationPortalUrl =
      'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true';
  static const String broadcomLoginUrl = workstationPortalUrl;
  static const String broadcomProductDownloadsUrl = workstationPortalUrl;
  static const String broadcomRegisterUrl =
      'https://profile.broadcom.com/web/registration';
  static const String fusionPortalUrl =
      'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Fusion&freeDownloads=true';

  // Standard Browser User-Agent (modern, avoids Cloudflare/Akamai bot WAF blocks)
  static const String broadcomUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36';

  // Storage Keys
  static const String storageKeySession = 'vmwareget_auth_session';
  static const String storageKeyThemeMode = 'vmwareget_theme_mode';
  static const String storageKeyDownloadDir = 'vmwareget_download_dir';
  static const String storageKeyDownloadThreads = 'vmwareget_download_threads';
  static const String storageKeyLocale = 'vmwareget_locale';
  static const String storageKeyDownloadHistory = 'vmwareget_download_history';

  // Multi-threading Download Engine Defaults
  static const int defaultDownloadThreads = 16;
  static const int minDownloadThreads = 1;
  static const int maxDownloadThreads = 64;
}
