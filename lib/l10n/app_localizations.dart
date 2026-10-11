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

  // ==================== Navigation & Shell ====================
  String get catalog => isZh ? '产品目录' : 'Catalog';
  String get downloads => isZh ? '下载列表' : 'Downloads';
  String get settings => isZh ? '设置' : 'Settings';
  String get officialCompanion => isZh ? '官方获取助手' : 'Official Companion';
  String get signOut => isZh ? '退出登录' : 'Sign Out';
  String get signIn => isZh ? '登录' : 'Sign In';
  String get sessionDetails => isZh ? '会话详情' : 'Session Details';
  String get broadcomSession => isZh ? 'Broadcom 账号会话' : 'Broadcom Session';
  String get authenticatedUser => isZh ? '已验证用户' : 'Authenticated User';
  String get noActiveSession => isZh ? '暂无有效会话' : 'No active session';
  String get switchToLightMode => isZh ? '切换为浅色主题' : 'Switch to Light Theme';
  String get switchToDarkMode => isZh ? '切换为深色主题' : 'Switch to Dark Theme';
  String get accountOptions => isZh ? '账号与会话选项' : 'Account & Session Options';
  String get signOutConfirmTitle => isZh ? '确认退出登录' : 'Sign Out Confirmation';
  String get signOutConfirmContent => isZh
      ? '确定要退出登录吗？您本地缓存的 Broadcom 会话凭证将被清除。'
      : 'Are you sure you want to sign out? Your cached Broadcom session and access tokens will be cleared.';
  String get signedOutSuccess =>
      isZh ? '已成功退出登录，会话已清除。' : 'Signed out successfully. Session cleared.';

  // ==================== Catalog View ====================
  String get searchPlaceholder =>
      isZh ? '搜索版本号、Build 或文件名...' : 'Search version, build, or release file...';
  String get allPlatforms => isZh ? '全部平台' : 'All Platforms';
  String get windowsOnly => isZh ? '仅 Windows (.exe)' : 'Windows only (.exe)';
  String get linuxOnly => isZh ? '仅 Linux (.bundle)' : 'Linux only (.bundle)';
  String get filterPlatform => isZh ? '筛选平台' : 'Filter Platform';
  String get syncOnlineCatalog => isZh ? '刷新在线目录' : 'Sync Online Catalog';
  String get fetchingReleases =>
      isZh ? '正在从 Broadcom 同步实时版本...' : 'Fetching releases live from Broadcom...';
  String get noOnlineReleasesLoaded =>
      isZh ? '未加载到在线版本' : 'No Online Releases Loaded';
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
  String get liveBadge => isZh ? '实时' : 'Live';

  // ==================== Metadata Panel ====================
  String get officialReleasePackage =>
      isZh ? '官方发行版安装包' : 'Official Release Package';
  String get version => isZh ? '版本号' : 'Version';
  String get releaseDate => isZh ? '发布日期' : 'Release Date';
  String get lastUpdated => isZh ? '最近更新' : 'Last Updated';
  String get fileSize => isZh ? '文件大小' : 'File Size';
  String get fileName => isZh ? '文件名' : 'File Name';
  String get buildNumber => isZh ? 'Build 编号' : 'Build Number';
  String get sha256Checksum => isZh ? 'SHA256 校验哈希' : 'SHA256 Checksum';
  String get md5Checksum => isZh ? 'MD5 校验哈希' : 'MD5 Checksum';
  String get downloadPackage => isZh ? '立即下载安装包' : 'Download Installer Package';
  String get packageDownloaded => isZh ? '安装包已下载' : 'Package Downloaded';
  String get verifiedAgainstChecksums =>
      isZh ? '已完成 SHA256 与 MD5 双重校验' : 'Verified against SHA256 & MD5';
  String get viewManager => isZh ? '查看下载任务' : 'View Manager';
  String get techMetadataSpec =>
      isZh ? '技术元数据规格' : 'Technical Metadata Specification';
  String get cryptographicChecksums =>
      isZh ? '官方防篡改校验哈希' : 'Cryptographic Checksums';
  String get licensingNote =>
      isZh ? '授权与合规许可说明' : 'Licensing & Entitlement Note';
  String get viewOnBroadcomPortal =>
      isZh ? '在 Broadcom 支持门户中查看' : 'View on Broadcom Support Portal';
  String get selectReleaseToInspect =>
      isZh ? '选择版本以查看详细技术元数据' : 'Select a release to inspect technical metadata';
  String get showInFinder => isZh ? '在访达中显示' : 'Show in Finder';
  String get showInFolder => isZh ? '在文件夹中显示' : 'Show in Folder';
  String get openInstaller => isZh ? '运行安装包' : 'Open Installer';
  String get reVerifyChecksum => isZh ? '重新校验哈希' : 'Re-verify Hash';

  // ==================== Downloads View & Progress Tile ====================
  String get activeRecentTransfers =>
      isZh ? '当前与历史下载任务' : 'Active & Recent Transfers';
  String get noDownloadsYet => isZh ? '暂无下载记录' : 'No active or past downloads';
  String get noDownloadsDesc => isZh
      ? '在产品目录中选择 VMware Workstation Pro 或 Fusion 即可开始下载与自动校验。'
      : 'Choose VMware Workstation Pro or Fusion to start downloading';
  String get browseCatalog =>
      isZh ? '浏览官方软件目录' : 'Browse Software Catalog';
  String get downloadDirectoryLabel => isZh ? '下载保存目录' : 'Download Directory';
  String get resolvingLocalPath =>
      isZh ? '正在解析本地路径...' : 'Resolving local path...';
  String activeCountBadge(int count) =>
      isZh ? '$count 个进行中' : '$count active';
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
  String get statusQueued => isZh ? '排队中' : 'Queued';
  String get statusCancelled => isZh ? '已取消' : 'Cancelled';
  String get speedLabel => isZh ? '速度' : 'Speed';
  String get etaLabel => isZh ? '剩余时间' : 'ETA';

  // ==================== Download Directory Dialog ====================
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
  String get selectDownloadDirPrompt =>
      isZh ? '选择 VMware 下载保存目录' : 'Select VMware Download Directory';
  String get recommended => isZh ? '推荐' : 'Recommended';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get confirmAndDownload =>
      isZh ? '确认并开始下载' : 'Confirm & Start Download';

  // ==================== Technical Diagnostic Dialog ====================
  String get technicalDiagnosticsSection =>
      isZh ? '技术诊断与实时日志' : 'Technical Diagnostics & Live Logs';
  String get diagnosticLogsTitle =>
      isZh ? '技术排查诊断日志' : 'Technical Diagnostic Logs';
  String get diagnosticSubtitle => isZh
      ? '记录 SSO 会话、CSRF Token、REST 接口耗时与并发切片下载状态'
      : 'Capture & inspect SSO cookies, CSRF tokens, and Broadcom REST endpoints';
  String get filterLogsHint =>
      isZh ? '过滤日志消息、Tag 或数据载荷...' : 'Filter log message, tag, or payload...';
  String get filterAll => isZh ? '全部' : 'All';
  String get filterErrors => isZh ? '错误' : 'Errors';
  String get clearLogs => isZh ? '清空日志' : 'Clear Logs';
  String get noLogsYet => isZh
      ? '暂无诊断日志。发起登录或刷新目录即可查看实时跟踪记录。'
      : 'No diagnostic logs yet. Trigger a login or catalog sync to see live trace.';
  String get noLogsMatching =>
      isZh ? '未找到符合当前过滤条件的日志。' : 'No logs matching current filter.';
  String copiedLogLines(int count) => isZh
      ? '已复制 $count 行日志到剪贴板！'
      : 'Copied $count log lines to clipboard!';
  String get copyAllLogs => isZh ? '一键复制全部日志' : 'Copy All Logs';
  String get close => isZh ? '关闭' : 'Close';
  String get diagnosticCopied =>
      isZh ? '诊断日志已复制到剪贴板！' : 'Diagnostic report copied to clipboard!';
  String get viewDiagnosticLogs => isZh ? '查看诊断日志' : 'View Diagnostic Logs';

  // ==================== Settings View ====================
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
  String get appInformationSection => isZh ? '关于应用' : 'Application Information';
  String get appIdentifier => isZh ? '应用标识符 / Bundle ID' : 'App Identifier / Bundle ID';
  String get frameworkEngine => isZh ? '技术框架' : 'Framework Engine';
  String get designSystem => isZh ? '设计系统' : 'Design System';
  String get targetPlatforms => isZh ? '支持平台' : 'Target Platforms';

  // ==================== Login Dialog ====================
  String get broadcomAuthTitle => isZh ? 'Broadcom 账户认证' : 'Broadcom Authentication';
  String get broadcomAuthSubtitle =>
      isZh ? '连接您的官方 Broadcom 支持门户会话' : 'Connect your official Broadcom session';
  String get tabInAppBrowser => isZh ? '内置安全浏览器' : 'In-App Browser';
  String get tabManualImport => isZh ? '手动导入 / cURL' : 'Manual / cURL Import';
  String get inAppBrowserTitle => isZh ? '内置安全浏览器登录' : 'In-App Browser Login';
  String get inAppBrowserDesc => isZh
      ? '打开安全 Web 视图，登录成功后自动捕获并提取会话'
      : 'Opens secure WKWebView window & auto-captures session upon login';
  String get signInViaInApp => isZh ? '通过内置浏览器登录' : 'Sign In via In-App Browser';
  String get authenticatingInApp =>
      isZh ? '正在内置浏览器中验证...' : 'Authenticating in-app...';
  String get instantDemoSession => isZh ? '快速演示会话' : 'Instant Demo Session';
  String get externalBrowser => isZh ? '外部浏览器登录' : 'External Browser';
  String get pasteFromClipboard => isZh ? '从剪贴板粘贴' : 'Paste from Clipboard';
  String get copyHelperSnippet => isZh ? '复制提取脚本' : 'Copy Helper Snippet';
  String get importPlaywrightSession => isZh
      ? '从本地 Playwright 测试缓存导入有效会话'
      : 'Import active session from local Playwright test cache';
  String get accountEmailLabel => isZh ? '账户邮箱' : 'Account Email';
  String get emailRequired => isZh ? '请输入您的邮箱' : 'Please enter your email';
  String get emailInvalid => isZh ? '请输入有效的邮箱地址' : 'Enter a valid email address';
  String get tokenLabel =>
      isZh ? 'Broadcom Cookie 字符串或 cURL 命令' : 'Broadcom Cookie String or cURL Command';
  String get tokenHint => isZh ? '在此粘贴 Cookie 或 cURL' : 'Paste Cookie or cURL';
  String get tokenRequired =>
      isZh ? '请输入您的会话 Cookie 或 Token' : 'Please enter your session cookie or token';
  String get connectSession => isZh ? '连接并登录会话' : 'Connect Session';
  String get clipboardEmpty => isZh ? '剪贴板为空' : 'Clipboard is empty';
  String get payloadPasted => isZh ? '已成功从剪贴板粘贴会话载荷！' : 'Session payload pasted from clipboard!';
  String get cookieHelperCopied => isZh
      ? '提取脚本已复制！可在浏览器开发者工具控制台中粘贴运行。'
      : 'Cookie capture helper copied! Paste into browser console or bookmark bar on Broadcom page.';

  // ==================== Onboarding View ====================
  String get welcomeTitle => isZh ? '欢迎使用 VMwareGet' : 'Welcome to VMwareGet';
  String get welcomeSubtitle => isZh
      ? '现代化跨平台下载助手，助您一键连接 Broadcom 官方渠道，安全高速下载 VMware Workstation Pro 及 VMware Fusion 官方安装包。'
      : 'The modern cross-platform companion to authenticate, browse, and securely download official VMware Workstation Pro and VMware Fusion packages.';
  String get feature1Title =>
      isZh ? 'Broadcom 官方软件发布渠道' : 'Official Broadcom Software Packages';
  String get feature1Desc => isZh
      ? '直接连接官方安全下载源，全面支持 VMware Workstation Pro 与 VMware Fusion。'
      : 'Direct and authentic download channels for VMware Workstation Pro and VMware Fusion.';
  String get feature2Title =>
      isZh ? 'SHA-256 与 MD5 完整性自动校验' : 'SHA-256 & MD5 Checksum Integrity';
  String get feature2Desc => isZh
      ? '下载完成后自动执行密码学哈希比对，确保与官方公布校验值 100% 一致。'
      : 'Live and automated post-download verification against official published cryptographic hashes.';
  String get feature3Title =>
      isZh ? '原生 Range 高并发下载引擎' : 'Advanced Download Manager';
  String get feature3Desc => isZh
      ? '原生切片多线程并发、暂停/断点续传、实时下载速率监控及剩余时间预测。'
      : 'Chunked downloading, pause/resume capability, real-time speed metrics, and ETA tracking.';
  String get logInWithBroadcom =>
      isZh ? '使用 Broadcom 账号登录' : 'Log In with Broadcom';
  String get registerAccount => isZh ? '注册官方账号' : 'Register Account';
  String get quickDemoAccess =>
      isZh ? '快速演示体验（免登录预览）' : 'Quick Demo Access (Explore without login)';

  // ==================== Common / Helpers ====================
  String copiedToClipboard(String label) =>
      isZh ? '已将 $label 复制到剪贴板！' : '$label copied to clipboard!';
  String copyLabel(String label) => isZh ? '复制 $label' : 'Copy $label';
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
