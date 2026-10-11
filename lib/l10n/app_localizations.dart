import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isZh => locale.languageCode == 'zh';

  // Navigation & Shell
  String get catalog => isZh ? '产品目录' : 'Catalog';
  String get downloads => isZh ? '下载列表' : 'Downloads';
  String get settings => isZh ? '设置' : 'Settings';
  String get officialCompanion => isZh ? '官方获取助手' : 'Official Companion';
  String get signOut => isZh ? '退出登录' : 'Sign Out';
  String get signIn => isZh ? '登录' : 'Sign In';
  String get sessionDetails => isZh ? '会话详情' : 'Session Details';
  String get broadcomSession => isZh ? 'Broadcom 账号会话' : 'Broadcom Session';

  // Catalog View
  String get searchPlaceholder =>
      isZh ? '搜索版本号、Build 或文件名...' : 'Search version, build, or release file...';
  String get allPlatforms => isZh ? '全部平台' : 'All Platforms';
  String get windowsPlatform => 'Windows';
  String get linuxPlatform => 'Linux';
  String get macosPlatform => 'macOS';
  String get syncOnlineCatalog => isZh ? '刷新在线目录' : 'Sync Online Catalog';
  String get fetchingReleases =>
      isZh ? '正在从 Broadcom 同步实时版本...' : 'Fetching releases live from Broadcom...';
  String get noReleasesFound =>
      isZh ? '未找到匹配的 VMware 安装包。' : 'No matching VMware releases found.';
  String get authRequiredTitle =>
      isZh ? '需要登录 Broadcom 账户' : 'Broadcom Account Required';
  String get authRequiredDesc => isZh
      ? '请使用 Broadcom 支持门户账户登录以获取官方下载链接与元数据。'
      : 'Sign in with your Broadcom Support Portal account to view official download links and metadata.';
  String get reauthenticate => isZh ? '重新登录' : 'Re-authenticate';
  String get selectItemToView => isZh
      ? '从列表中选择安装包以查看校验哈希、详细元数据及下载链接。'
      : 'Select an installer from the list to view technical metadata, release notes, and verified SHA256 checksums.';

  // Metadata Panel
  String get officialReleasePackage =>
      isZh ? '官方发行版安装包' : 'Official Release Package';
  String get version => isZh ? '版本号' : 'Version';
  String get releaseDate => isZh ? '发布日期' : 'Release Date';
  String get fileSize => isZh ? '文件大小' : 'File Size';
  String get buildNumber => isZh ? 'Build 编号' : 'Build Number';
  String get sha256Checksum => isZh ? 'SHA256 校验哈希' : 'SHA256 Checksum';
  String get md5Checksum => isZh ? 'MD5 校验哈希' : 'MD5 Checksum';
  String get downloadPackage => isZh ? '立即下载' : 'Download Package';
  String get showInFinder => isZh ? '在访达中显示' : 'Show in Finder';
  String get showInFolder => isZh ? '在文件夹中显示' : 'Show in Folder';
  String get openInstaller => isZh ? '运行安装包' : 'Open Installer';
  String get reVerifyChecksum => isZh ? '重新校验哈希' : 'Re-verify Hash';

  // Downloads View & Progress Tile
  String get activeRecentTransfers =>
      isZh ? '当前与历史下载任务' : 'Active & Recent Transfers';
  String get noDownloadsYet => isZh ? '暂无下载记录' : 'No downloads yet';
  String get noDownloadsDesc => isZh
      ? '在产品目录中点击下载，即可在此追踪进度与自动校验。'
      : 'Download releases from the Catalog to track progress and automatic SHA256 checksum verification.';
  String get downloadDirectoryLabel => isZh ? '下载目录' : 'Download Directory';
  String get openFolder => isZh ? '打开目录' : 'Open Folder';
  String get pause => isZh ? '暂停' : 'Pause';
  String get resumeRetry => isZh ? '继续 / 重试' : 'Resume / Retry';
  String get deleteRemove => isZh ? '删除记录' : 'Delete / Remove';
  String get statusDownloading => isZh ? '下载中' : 'Downloading';
  String get statusPaused => isZh ? '已暂停' : 'Paused';
  String get statusCompleted => isZh ? '已完成' : 'Completed';
  String get statusFailed => isZh ? '下载失败' : 'Failed';
  String get statusVerifying => isZh ? '正在校验哈希...' : 'Verifying Hash...';
  String get statusPassed => isZh ? '哈希校验通过' : 'SHA256 & MD5 Verified';
  String get statusMismatch => isZh ? '哈希校验不匹配' : 'Checksum Mismatch';

  // Download Directory Dialog
  String get setDownloadDirTitle =>
      isZh ? '设置下载保存目录' : 'Set Download Directory';
  String get setDownloadDirSubtitle => isZh
      ? '请选择 VMware 安装包及磁盘映像的默认存储目录：'
      : 'Where would you like to save VMware installer packages?';
  String get systemDownloadsTitle =>
      isZh ? '系统下载目录' : 'System Downloads Folder';
  String get systemDownloadsDesc =>
      isZh ? '默认推荐存储位置 (~/Downloads/VMwareGet)' : 'Default recommended location (~/Downloads/VMwareGet)';
  String get chooseCustomFolderTitle =>
      isZh ? '选择自定义目录' : 'Choose Custom Folder';
  String get chooseCustomFolderDesc =>
      isZh ? '浏览并选择本地磁盘上的其他文件夹' : 'Browse and select another folder on disk';
  String get rememberChoice =>
      isZh ? '记住我的选择，后续下载不再提示' : 'Remember my choice and don\'t ask again';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get confirmAndDownload =>
      isZh ? '确认并开始下载' : 'Confirm & Start Download';

  // Diagnostic Dialog
  String get diagnosticLogsTitle =>
      isZh ? '技术排查诊断日志' : 'Technical Diagnostic Logs';
  String get diagnosticSubtitle => isZh
      ? '记录 SSO 会话、CSRF Token、REST 接口耗时与并发切片下载状态'
      : 'Capture & inspect SSO cookies, CSRF tokens, and Broadcom REST endpoints';
  String get copyAllLogs => isZh ? '一键复制全部日志' : 'Copy All Logs';
  String get close => isZh ? '关闭' : 'Close';
  String get diagnosticCopied =>
      isZh ? '诊断日志已复制到剪贴板！' : 'Diagnostic report copied to clipboard!';

  // Settings View
  String get settingsAndAccount => isZh ? '应用设置与账号' : 'Settings & Account';
  String get exportComplianceScreening =>
      isZh ? '合规出口审查状态：' : 'Export Compliance Screening:';
  String get complianceApproved =>
      isZh ? '已通过（具备全球免费个人许可下载权限）' : 'Approved (Global Free License Access)';
  String get sessionPersistence => isZh ? '会话持久化：' : 'Session Persistence:';
  String get encryptedStorageActive =>
      isZh ? '已启用本地加密安全存储' : 'Encrypted Storage Active';
  String get downloadStorageSection =>
      isZh ? '下载目录配置' : 'Download Storage & Directory';
  String get downloadDestinationDir =>
      isZh ? '下载保存目录' : 'Download Destination Directory';
  String get downloadDirSubtitle =>
      isZh ? '所有下载的安装包与磁盘映像将保存至该文件夹' : 'Installer packages and disk images will be saved here';
  String get changeDirectory => isZh ? '更改目录...' : 'Change Directory...';
  String get openInFinderOrExplorer =>
      isZh ? '打开目录' : 'Open Directory';
  String get resetToDefault =>
      isZh ? '恢复系统默认' : 'Reset to System Default';
  String get multiThreadingSection =>
      isZh ? '并发下载线程数' : 'Native Range Multi-threading';
  String get multiThreadingSubtitle => isZh
      ? '基于 HTTP Range 原生分块并发请求，充分跑满网络带宽'
      : 'Concurrent HTTP Range connections for accelerated throughput';
  String get threadsLabel => isZh ? '线程' : 'Threads';
  String get threadsSingle => isZh ? '1 (单连接)' : '1 (Single)';
  String get threadsDefault => isZh ? '16 (默认)' : '16 (Default)';
  String get threadsMax => isZh ? '64 (极速)' : '64 (Max Turbo)';
  String get multiThreadingHint => isZh
      ? '💡 原生 Dart Range 并发切片下载，无需重型外部进程依赖，自动分段定点写入，设置自动持久化生效。'
      : '💡 Pure Dart native Range concurrency writes directly to disk offsets without external dependencies.';
  String get defaultLabel => isZh ? '默认' : 'Default';
  String get maxLabel => isZh ? '最大' : 'Max';
  String get languageSection => isZh ? '界面语言' : 'Language';
  String get displayLanguage =>
      isZh ? '界面显示语言' : 'Application Display Language';
  String get langEnglish => 'English (Default)';
  String get langChinese => '简体中文';
  String get appearanceSection => isZh ? '外观与主题' : 'Appearance & Theme';
  String get materialThemeMode =>
      isZh ? 'Material 3 主题外观' : 'Material Design 3 Theme Mode';
  String get themeModeSystem => isZh ? '跟随系统' : 'System';
  String get themeModeLight => isZh ? '浅色' : 'Light';
  String get themeModeDark => isZh ? '深色' : 'Dark';
  String get technicalDiagnosticsSection =>
      isZh ? '技术诊断与实时日志' : 'Technical Diagnostics & Live Logs';
  String get viewDiagnosticLogs => isZh ? '查看诊断日志' : 'View Diagnostic Logs';
  String get appInformationSection => isZh ? '关于应用' : 'Application Information';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
