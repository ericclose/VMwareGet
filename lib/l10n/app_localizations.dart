import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Application Localization engine following official Flutter l10n guidelines.
/// Provides refined, professional, and elegant ("信达雅") terminology in:
/// - English (`en`, default)
/// - Simplified Chinese (`zh`)
/// - Esperanto (`eo`)
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
    Locale('eo'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isZh => locale.languageCode == 'zh';
  bool get isEo => locale.languageCode == 'eo';

  String _t({required String en, required String zh, required String eo}) {
    if (locale.languageCode == 'zh') return zh;
    if (locale.languageCode == 'eo') return eo;
    return en;
  }

  // ==================== Navigation & Shell ====================
  String get catalog => _t(
        en: 'Catalog',
        zh: '软件目录',
        eo: 'Katalogo',
      );
  String get downloads => _t(
        en: 'Downloads',
        zh: '传输管理',
        eo: 'Elŝutoj',
      );
  String get settings => _t(
        en: 'Settings',
        zh: '偏好设置',
        eo: 'Agordoj',
      );
  String get officialCompanion => _t(
        en: 'Official Companion',
        zh: '官方分发助手',
        eo: 'Oficiala Kunulo',
      );
  String get signOut => _t(
        en: 'Sign Out',
        zh: '退出登录',
        eo: 'Elsaluti',
      );
  String get signIn => _t(
        en: 'Sign In',
        zh: '登录',
        eo: 'Ensaluti',
      );
  String get sessionDetails => _t(
        en: 'Session Details',
        zh: '账户会话',
        eo: 'Detaloj de Seanco',
      );
  String get broadcomSession => _t(
        en: 'Broadcom Session',
        zh: 'Broadcom 授权会话',
        eo: 'Broadcom-Seanco',
      );
  String get authenticatedUser => _t(
        en: 'Authenticated User',
        zh: '已认证用户',
        eo: 'Aŭtentigita Uzanto',
      );
  String get noActiveSession => _t(
        en: 'No active session',
        zh: '未登录有效会话',
        eo: 'Neniu aktiva seanco',
      );
  String get switchToLightMode => _t(
        en: 'Switch to Light Theme',
        zh: '切换浅色模式',
        eo: 'Ŝanĝi al hela etoso',
      );
  String get switchToDarkMode => _t(
        en: 'Switch to Dark Theme',
        zh: '切换深色模式',
        eo: 'Ŝanĝi al malhela etoso',
      );
  String get accountOptions => _t(
        en: 'Account Options',
        zh: '账户选项',
        eo: 'Konto kaj Seanco',
      );
  String get signOutConfirmTitle => _t(
        en: 'Sign Out',
        zh: '确认退出登录',
        eo: 'Konfirmi Elsaluton',
      );
  String get signOutConfirmContent => _t(
        en: 'Are you sure you want to sign out? Cached credentials and session tokens will be removed.',
        zh: '确定退出登录？本地缓存的 Broadcom 会话凭证与访问令牌将被清除。',
        eo: 'Ĉu vi certas, ke vi volas elsaluti? Viaj konservitaj ensakreditoj estos forigitaj.',
      );
  String get signedOutSuccess => _t(
        en: 'Signed out successfully.',
        zh: '已安全退出登录。',
        eo: 'Sukcese elsalutita.',
      );

  // ==================== Catalog View ====================
  String get searchPlaceholder => _t(
        en: 'Search version, build, or release file...',
        zh: '搜索版本号、Build 或文件名...',
        eo: 'Serĉi version, konstruon aŭ dosieron...',
      );
  String get allPlatforms => _t(
        en: 'All Platforms',
        zh: '全平台',
        eo: 'Ĉiuj platformoj',
      );
  String get windowsOnly => _t(
        en: 'Windows (.exe)',
        zh: 'Windows (.exe)',
        eo: 'Windows (.exe)',
      );
  String get linuxOnly => _t(
        en: 'Linux (.bundle)',
        zh: 'Linux (.bundle)',
        eo: 'Linux (.bundle)',
      );
  String get filterPlatform => _t(
        en: 'Filter Platform',
        zh: '筛选平台',
        eo: 'Filtri platformon',
      );
  String get syncOnlineCatalog => _t(
        en: 'Sync Catalog',
        zh: '同步最新目录',
        eo: 'Sinkronigi katalogon',
      );
  String get fetchingReleases => _t(
        en: 'Fetching live releases from Broadcom...',
        zh: '正在同步 Broadcom 官方版本库...',
        eo: 'Sinkronigante versiojn de Broadcom...',
      );
  String get noOnlineReleasesLoaded => _t(
        en: 'No Releases Loaded',
        zh: '未加载到版本数据',
        eo: 'Neniuj eldonoj ŝarĝitaj',
      );
  String get noReleasesFound => _t(
        en: 'No matching releases found.',
        zh: '未找到匹配的安装包。',
        eo: 'Neniu kongrua eldono trovita.',
      );
  String get authRequiredTitle => _t(
        en: 'Broadcom Account Required',
        zh: '需登录 Broadcom 账户',
        eo: 'Necesas Broadcom-konto',
      );
  String get authRequiredDesc => _t(
        en: 'Sign in to access official download links, release packages, and verified checksums.',
        zh: '请登录 Broadcom 账户以获取官方授权下载链接与校验元数据。',
        eo: 'Bonvolu ensaluti per Broadcom-konto por elŝuti oficialajn pakaĵojn.',
      );
  String get reauthenticate => _t(
        en: 'Re-authenticate',
        zh: '重新认证',
        eo: 'Reaŭtentigi',
      );
  String get selectItemToView => _t(
        en: 'Select an installer package to inspect metadata, checksums, and download links.',
        zh: '请选择版本以查看规格参数、防篡改校验哈希与下载链接。',
        eo: 'Elektu eldonon por inspekti detalojn, haketkodojn kaj elŝutajn ligilojn.',
      );
  String get liveBadge => _t(
        en: 'Live',
        zh: '实时',
        eo: 'Reala',
      );

  // ==================== Metadata Panel ====================
  String get officialReleasePackage => _t(
        en: 'Official Release Package',
        zh: '官方安装包',
        eo: 'Oficiala Instalilo',
      );
  String get version => _t(
        en: 'Version',
        zh: '版本号',
        eo: 'Versio',
      );
  String get releaseDate => _t(
        en: 'Release Date',
        zh: '发布日期',
        eo: 'Eldonita',
      );
  String get lastUpdated => _t(
        en: 'Last Updated',
        zh: '更新时间',
        eo: 'Laste ĝisdatigita',
      );
  String get fileSize => _t(
        en: 'File Size',
        zh: '文件大小',
        eo: 'Dosiergrando',
      );
  String get fileName => _t(
        en: 'File Name',
        zh: '文件名',
        eo: 'Dosiernomo',
      );
  String get buildNumber => _t(
        en: 'Build Number',
        zh: 'Build 编号',
        eo: 'Konstruo',
      );
  String get sha256Checksum => _t(
        en: 'SHA256 Checksum',
        zh: 'SHA256 校验码',
        eo: 'SHA256 Haketkodo',
      );
  String get md5Checksum => _t(
        en: 'MD5 Checksum',
        zh: 'MD5 校验码',
        eo: 'MD5 Haketkodo',
      );
  String get downloadPackage => _t(
        en: 'Download Package',
        zh: '开始下载',
        eo: 'Komenci Elŝuton',
      );
  String get packageDownloaded => _t(
        en: 'Download Completed',
        zh: '下载已完成',
        eo: 'Elŝuto Finita',
      );
  String get verifiedAgainstChecksums => _t(
        en: 'Integrity Verified (SHA256 & MD5)',
        zh: '完整性校验通过 (SHA256 & MD5)',
        eo: 'Integreco Konfirmita (SHA256 & MD5)',
      );
  String get viewManager => _t(
        en: 'View Downloads',
        zh: '查看进度',
        eo: 'Vidi Elŝutojn',
      );
  String get techMetadataSpec => _t(
        en: 'Technical Specifications',
        zh: '技术规格',
        eo: 'Teknikaj Detaloj',
      );
  String get cryptographicChecksums => _t(
        en: 'Cryptographic Checksums',
        zh: '防篡改校验哈希',
        eo: 'Sekuraj Haketkodoj',
      );
  String get licensingNote => _t(
        en: 'Licensing & Entitlement',
        zh: '许可与授权说明',
        eo: 'Permesilo kaj Rajto',
      );
  String get viewOnBroadcomPortal => _t(
        en: 'Open in Broadcom Support Portal',
        zh: '前往 Broadcom 支持门户',
        eo: 'Malfermi en Broadcom-Portalo',
      );
  String get selectReleaseToInspect => _t(
        en: 'Select a release to inspect technical metadata',
        zh: '选择版本以查看技术规格与校验信息',
        eo: 'Elektu eldonon por inspekti detalojn',
      );
  String get showInFinder => _t(
        en: 'Show in Finder',
        zh: '在访达中显示',
        eo: 'Montri en Finder',
      );
  String get showInFolder => _t(
        en: 'Show in Folder',
        zh: '打开所在文件夹',
        eo: 'Montri en Dosierujo',
      );
  String get openInstaller => _t(
        en: 'Open Installer',
        zh: '打开安装包',
        eo: 'Malfermi Instalilon',
      );
  String get reVerifyChecksum => _t(
        en: 'Re-verify Hash',
        zh: '重新校验',
        eo: 'Rekontroli Haketkodon',
      );

  // ==================== Downloads View & Progress Tile ====================
  String get activeRecentTransfers => _t(
        en: 'Active & Recent Transfers',
        zh: '传输任务',
        eo: 'Aktivaj kaj Lastaj Elŝutoj',
      );
  String get noDownloadsYet => _t(
        en: 'No Downloads',
        zh: '暂无传输任务',
        eo: 'Neniuj Elŝutoj Ankoraŭ',
      );
  String get noDownloadsDesc => _t(
        en: 'Select VMware Workstation Pro or Fusion in the Catalog to begin.',
        zh: '在软件目录中选择对应版本即可发起下载。',
        eo: 'Elektu version en la katalogo por komenci elŝuton.',
      );
  String get browseCatalog => _t(
        en: 'Browse Catalog',
        zh: '前往软件目录',
        eo: 'Iri al Katalogo',
      );
  String get downloadDirectoryLabel => _t(
        en: 'Storage Location',
        zh: '存储目录',
        eo: 'Konserva Dosierujo',
      );
  String get resolvingLocalPath => _t(
        en: 'Resolving path...',
        zh: '正在解析存储路径...',
        eo: 'Solvante vojon...',
      );
  String activeCountBadge(int count) => _t(
        en: '$count active',
        zh: '$count 个进行中',
        eo: '$count aktivaj',
      );
  String get openFolder => _t(
        en: 'Open Folder',
        zh: '打开目录',
        eo: 'Malfermi Dosierujon',
      );
  String get pause => _t(
        en: 'Pause',
        zh: '暂停',
        eo: 'Paŭzi',
      );
  String get resumeRetry => _t(
        en: 'Resume',
        zh: '继续 / 重试',
        eo: 'Rekomenci',
      );
  String get deleteRemove => _t(
        en: 'Remove',
        zh: '删除任务',
        eo: 'Forigi',
      );
  String get statusDownloading => _t(
        en: 'Downloading',
        zh: '下载中',
        eo: 'Elŝutante',
      );
  String get statusPaused => _t(
        en: 'Paused',
        zh: '已暂停',
        eo: 'Paŭzita',
      );
  String get statusCompleted => _t(
        en: 'Completed',
        zh: '已完成',
        eo: 'Finita',
      );
  String get statusFailed => _t(
        en: 'Failed',
        zh: '下载失败',
        eo: 'Malsukcesis',
      );
  String get statusVerifying => _t(
        en: 'Verifying Integrity...',
        zh: '正在校验完整性...',
        eo: 'Kontrolante...',
      );
  String get statusPassed => _t(
        en: 'Verified',
        zh: '完整性校验通过',
        eo: 'Kontrolo Sukcesis',
      );
  String get statusMismatch => _t(
        en: 'Checksum Mismatch',
        zh: '校验哈希不匹配',
        eo: 'Malkongruo de Haketkodo',
      );
  String get statusQueued => _t(
        en: 'Queued',
        zh: '排队中',
        eo: 'En Vico',
      );
  String get statusCancelled => _t(
        en: 'Cancelled',
        zh: '已取消',
        eo: 'Nuligita',
      );
  String get speedLabel => _t(
        en: 'Speed',
        zh: '速率',
        eo: 'Rapido',
      );
  String get etaLabel => _t(
        en: 'ETA',
        zh: '预计剩余',
        eo: 'Restas',
      );

  // ==================== Download Directory Dialog ====================
  String get setDownloadDirTitle => _t(
        en: 'Set Storage Directory',
        zh: '选择存储目录',
        eo: 'Agordi Elŝutan Dosierujon',
      );
  String get setDownloadDirSubtitle => _t(
        en: 'Where should VMware packages and disk images be saved?',
        zh: '请设置安装包与磁盘映像的存储位置：',
        eo: 'Elektu kie konservi VMware-pakaĵojn kaj diskobildojn:',
      );
  String get systemDownloadsTitle => _t(
        en: 'System Downloads',
        zh: '系统下载文件夹',
        eo: 'Sistema Elŝutujo',
      );
  String get systemDownloadsDesc => _t(
        en: 'Standard default path (~/Downloads/VMwareGet)',
        zh: '推荐默认路径 (~/Downloads/VMwareGet)',
        eo: 'Defaŭlta rekomendita vojo (~/Downloads/VMwareGet)',
      );
  String get chooseCustomFolderTitle => _t(
        en: 'Custom Location',
        zh: '自定义目标文件夹',
        eo: 'Propra Dosierujo',
      );
  String get chooseCustomFolderDesc => _t(
        en: 'Browse and choose another destination on disk',
        zh: '选择磁盘上的其他存储文件夹',
        eo: 'Elekti alian lokon en la disko',
      );
  String get selectDownloadDirPrompt => _t(
        en: 'Select VMware Download Directory',
        zh: '选择 VMware 下载存储目录',
        eo: 'Elekti elŝutan dosierujon por VMware',
      );
  String get recommended => _t(
        en: 'Recommended',
        zh: '推荐',
        eo: 'Rekomendita',
      );
  String get cancel => _t(
        en: 'Cancel',
        zh: '取消',
        eo: 'Nuligi',
      );
  String get confirmAndDownload => _t(
        en: 'Confirm & Download',
        zh: '确认并下载',
        eo: 'Konfirmi kaj Elŝuti',
      );

  // ==================== Technical Diagnostic Dialog ====================
  String get technicalDiagnosticsSection => _t(
        en: 'Diagnostics & Logs',
        zh: '诊断日志',
        eo: 'Diagnozoj kaj Protokoloj',
      );
  String get diagnosticLogsTitle => _t(
        en: 'Technical Diagnostic Logs',
        zh: '技术诊断日志',
        eo: 'Teknikaj Diagnozoj',
      );
  String get diagnosticSubtitle => _t(
        en: 'Real-time pipeline tracking: authentication, token lifecycle, and transfer metrics',
        zh: '实时记录认证会话、网络请求耗时与切片下载状态',
        eo: 'Realtempa sekvado: seanco, ĵetonoj kaj elŝuta stato',
      );
  String get filterLogsHint => _t(
        en: 'Filter logs by keyword or payload...',
        zh: '按关键词、Tag 或载荷过滤日志...',
        eo: 'Filtri protokolojn per ŝlosilvorto...',
      );
  String get filterAll => _t(
        en: 'All',
        zh: '全部',
        eo: 'Ĉiuj',
      );
  String get filterErrors => _t(
        en: 'Errors',
        zh: '错误',
        eo: 'Eraroj',
      );
  String get clearLogs => _t(
        en: 'Clear Logs',
        zh: '清空日志',
        eo: 'Vakigi Protokolojn',
      );
  String get noLogsYet => _t(
        en: 'No diagnostic logs yet. Trigger a sync or login to inspect activity.',
        zh: '暂无诊断日志。发起登录或目录同步即可实时追踪。',
        eo: 'Neniuj protokoloj ankoraŭ. Sinkronigu aŭ ensalutu por vidi agadon.',
      );
  String get noLogsMatching => _t(
        en: 'No logs matching current filter.',
        zh: '未找到符合条件的日志。',
        eo: 'Neniuj protokoloj kongruas kun la filtro.',
      );
  String copiedLogLines(int count) => _t(
        en: 'Copied $count log entries to clipboard.',
        zh: '已复制 $count 条日志至剪贴板。',
        eo: 'Kopiis $count protokolajn liniojn al tondujo.',
      );
  String get copyAllLogs => _t(
        en: 'Copy All Logs',
        zh: '复制全部日志',
        eo: 'Kopii Ĉiujn Protokolojn',
      );
  String get close => _t(
        en: 'Close',
        zh: '关闭',
        eo: 'Fermi',
      );
  String get diagnosticCopied => _t(
        en: 'Diagnostic report copied to clipboard.',
        zh: '诊断报告已复制至剪贴板。',
        eo: 'Diagnoza raporto kopiita al tondujo.',
      );
  String get viewDiagnosticLogs => _t(
        en: 'View Diagnostics',
        zh: '查看诊断',
        eo: 'Vidi Diagnozojn',
      );

  // ==================== Settings View ====================
  String get settingsAndAccount => _t(
        en: 'Settings & Account',
        zh: '偏好设置与账户',
        eo: 'Agordoj kaj Konto',
      );
  String get exportComplianceScreening => _t(
        en: 'Export Compliance Screening:',
        zh: '出口合规审查：',
        eo: 'Eksporta Konformeco:',
      );
  String get complianceApproved => _t(
        en: 'Approved (Global Free Personal Use)',
        zh: '已通过（全球免费个人许可）',
        eo: 'Aprobita (Tutmonda senkosta persona uzo)',
      );
  String get sessionPersistence => _t(
        en: 'Session Storage:',
        zh: '会话存储：',
        eo: 'Seanca Memoro:',
      );
  String get encryptedStorageActive => _t(
        en: 'Hardware-Encrypted Secure Storage Active',
        zh: '本地安全加密存储已就绪',
        eo: 'Ĉifrita sekura memoro aktiva',
      );
  String get downloadStorageSection => _t(
        en: 'Download Storage',
        zh: '存储配置',
        eo: 'Elŝuta Memoro',
      );
  String get downloadDestinationDir => _t(
        en: 'Destination Directory',
        zh: '安装包存储目录',
        eo: 'Konserva Dosierujo',
      );
  String get downloadDirSubtitle => _t(
        en: 'All installer packages and disk images will be saved here',
        zh: '下载的所有安装包与磁盘映像均存储于此文件夹',
        eo: 'Ĉiuj instaliloj kaj diskobildoj estos konservitaj ĉi tie',
      );
  String get changeDirectory => _t(
        en: 'Change Location...',
        zh: '更改目录...',
        eo: 'Ŝanĝi Lokon...',
      );
  String get openInFinderOrExplorer => _t(
        en: 'Open Directory',
        zh: '打开目录',
        eo: 'Malfermi Dosierujon',
      );
  String get resetToDefault => _t(
        en: 'Reset to System Default',
        zh: '恢复默认',
        eo: 'Restarigi Defaŭlton',
      );
  String get multiThreadingSection => _t(
        en: 'Range Concurrency',
        zh: '切片分块并发',
        eo: 'Range-Samtempeco',
      );
  String get multiThreadingSubtitle => _t(
        en: 'Concurrent HTTP Range connections for accelerated throughput',
        zh: '利用 HTTP Range 分块并发请求以跑满网络带宽',
        eo: 'Samtempaj HTTP Range konektoj por plirapidigi elŝuton',
      );
  String get threadsLabel => _t(
        en: 'Connections',
        zh: '线程数',
        eo: 'Fadenoj',
      );
  String get threadsSingle => _t(
        en: '1 (Single)',
        zh: '1 (单连接)',
        eo: '1 (Unuobla)',
      );
  String get threadsDefault => _t(
        en: '16 (Default)',
        zh: '16 (推荐)',
        eo: '16 (Defaŭlto)',
      );
  String get threadsMax => _t(
        en: '64 (Turbo)',
        zh: '64 (极速)',
        eo: '64 (Maksimumo)',
      );
  String get multiThreadingHint => _t(
        en: '💡 Pure Dart native Range concurrency writes directly to disk offsets without external tools.',
        zh: '💡 原生 Dart Range 并发切片传输，按偏移量直接定点落盘，配置即刻生效。',
        eo: '💡 Pura Dart Range-samtempeco skribas rekte al diskaj deŝovoj sen eksteraj iloj.',
      );
  String get defaultLabel => _t(
        en: 'Default',
        zh: '默认',
        eo: 'Defaŭlto',
      );
  String get maxLabel => _t(
        en: 'Max',
        zh: '极速',
        eo: 'Maks',
      );
  String get languageSection => _t(
        en: 'Display Language',
        zh: '显示语言',
        eo: 'Lingvo',
      );
  String get displayLanguage => _t(
        en: 'Interface Language',
        zh: '界面语言',
        eo: 'Interfaca Lingvo',
      );
  String get langEnglish => 'English (Default)';
  String get langChinese => '简体中文';
  String get langEsperanto => 'Esperanto';
  String get appearanceSection => _t(
        en: 'Appearance & Theme',
        zh: '外观与主题',
        eo: 'Aspekto kaj Etoso',
      );
  String get materialThemeMode => _t(
        en: 'Material Design 3 Theme',
        zh: 'Material Design 3 风格',
        eo: 'Material Design 3 Etoso',
      );
  String get themeModeSystem => _t(
        en: 'System',
        zh: '跟随系统',
        eo: 'Sistema',
      );
  String get themeModeLight => _t(
        en: 'Light',
        zh: '浅色',
        eo: 'Hela',
      );
  String get themeModeDark => _t(
        en: 'Dark',
        zh: '深色',
        eo: 'Malhela',
      );
  String get appInformationSection => _t(
        en: 'About Application',
        zh: '关于',
        eo: 'Pri la Aplikaĵo',
      );
  String get appIdentifier => _t(
        en: 'Bundle Identifier',
        zh: '应用标识符',
        eo: 'Aplikaĵa Identigilo',
      );
  String get frameworkEngine => _t(
        en: 'Engine & Runtime',
        zh: '核心引擎',
        eo: 'Kerna Motoro',
      );
  String get designSystem => _t(
        en: 'Design System',
        zh: '设计系统',
        eo: 'Dezajna Sistemo',
      );
  String get targetPlatforms => _t(
        en: 'Supported Platforms',
        zh: '支持平台',
        eo: 'Subtenataj Platformoj',
      );

  // ==================== Login Dialog ====================
  String get broadcomAuthTitle => _t(
        en: 'Broadcom Authentication',
        zh: 'Broadcom 账户认证',
        eo: 'Aŭtentigo de Broadcom',
      );
  String get broadcomAuthSubtitle => _t(
        en: 'Connect your official Broadcom support portal session',
        zh: '连接 Broadcom 官方支持门户会话',
        eo: 'Konekti vian oficialan Broadcom-seancon',
      );
  String get tabInAppBrowser => _t(
        en: 'In-App Web',
        zh: '内嵌 Web 视图登录',
        eo: 'En-aplikaĵa Reto',
      );
  String get tabManualImport => _t(
        en: 'cURL / Manual Import',
        zh: '凭证 / cURL 导入',
        eo: 'Mana Importo / cURL',
      );
  String get inAppBrowserTitle => _t(
        en: 'In-App Browser Authentication',
        zh: '内嵌浏览器一键登录',
        eo: 'En-aplikaĵa Ensaluto',
      );
  String get inAppBrowserDesc => _t(
        en: 'Opens secure WKWebView window & auto-captures session cookies upon login',
        zh: '打开安全 Web 视图，登录成功后自动捕获并导入会话凭证',
        eo: 'Malfermas sekuran fenestron kaj aŭtomate kaptas la seancon',
      );
  String get signInViaInApp => _t(
        en: 'Sign In via In-App Browser',
        zh: '启动内嵌浏览器登录',
        eo: 'Ensaluti en Retumilo',
      );
  String get authenticatingInApp => _t(
        en: 'Authenticating in-app portal...',
        zh: '正在等待登录完成...',
        eo: 'Aŭtentigante...',
      );
  String get instantDemoSession => _t(
        en: 'Instant Demo Session',
        zh: '快速体验',
        eo: 'Ekzamena Seanco',
      );
  String get externalBrowser => _t(
        en: 'External Browser',
        zh: '系统默认浏览器',
        eo: 'Ekstera Retumilo',
      );
  String get pasteFromClipboard => _t(
        en: 'Paste from Clipboard',
        zh: '从剪贴板粘贴',
        eo: 'Alglui el Tondujo',
      );
  String get copyHelperSnippet => _t(
        en: 'Copy Capture Snippet',
        zh: '复制抓取脚本',
        eo: 'Kopii Helpilon',
      );
  String get importPlaywrightSession => _t(
        en: 'Import active session from local test cache',
        zh: '从本地测试缓存导入有效会话',
        eo: 'Importi aktivan seancon el loka kaŝmemoro',
      );
  String get accountEmailLabel => _t(
        en: 'Account Email',
        zh: '账户邮箱',
        eo: 'Konta Retpoŝto',
      );
  String get emailRequired => _t(
        en: 'Please enter your email',
        zh: '请输入邮箱',
        eo: 'Bonvolu enigi retpoŝton',
      );
  String get emailInvalid => _t(
        en: 'Enter a valid email address',
        zh: '请输入有效的邮箱地址',
        eo: 'Nevalida retpoŝtadreso',
      );
  String get tokenLabel => _t(
        en: 'Broadcom Cookie String or cURL Command',
        zh: 'Cookie 字符串或 cURL 命令',
        eo: 'Kuketaro aŭ cURL-komando',
      );
  String get tokenHint => _t(
        en: 'Paste Cookie header or curl command here',
        zh: '在此粘贴 Cookie 请求头或 cURL 命令',
        eo: 'Alglui kuketon aŭ cURL ĉi tie',
      );
  String get tokenRequired => _t(
        en: 'Please enter your session cookie or token',
        zh: '请输入会话 Cookie 或 Token',
        eo: 'Bonvolu enigi vian seancon',
      );
  String get connectSession => _t(
        en: 'Connect Session',
        zh: '接入会话',
        eo: 'Konekti Seancon',
      );
  String get clipboardEmpty => _t(
        en: 'Clipboard is empty.',
        zh: '剪贴板内容为空。',
        eo: 'Tondujo estas malplena.',
      );
  String get payloadPasted => _t(
        en: 'Session payload pasted from clipboard.',
        zh: '已读取并填充剪贴板凭证。',
        eo: 'Seanco sukcese algluita el tondujo.',
      );
  String get cookieHelperCopied => _t(
        en: 'Cookie capture snippet copied. Paste into browser console on Broadcom page.',
        zh: '提取脚本已复制，可在浏览器开发者控制台中粘贴运行。',
        eo: 'Kaptoskripto kopiita. Algluu en la retumilan konzolon.',
      );

  // ==================== Onboarding View ====================
  String get welcomeTitle => _t(
        en: 'Welcome to VMwareGet',
        zh: '欢迎使用 VMwareGet',
        eo: 'Bonvenon al VMwareGet',
      );
  String get welcomeSubtitle => _t(
        en: 'The clean, native companion to authenticate, browse, and securely download official VMware Workstation Pro and Fusion releases.',
        zh: '专为 macOS 与跨平台打造的官方分发助手，助您一键连接 Broadcom 渠道，高速下载并自动校验 VMware 安装包。',
        eo: 'Moderna kunulo por aŭtentigi, foliumi kaj sekure elŝuti oficialajn VMware-eldonojn.',
      );
  String get feature1Title => _t(
        en: 'Official Broadcom Software Packages',
        zh: '官方软件渠道',
        eo: 'Oficialaj Eldonoj',
      );
  String get feature1Desc => _t(
        en: 'Direct and authentic downloads for VMware Workstation Pro and VMware Fusion.',
        zh: '直连官方安全下载源，全面支持 VMware Workstation Pro 与 Fusion。',
        eo: 'Rektaj kaj aŭtentikaj elŝutaj kanaloj por VMware Workstation Pro kaj Fusion.',
      );
  String get feature2Title => _t(
        en: 'Automated Cryptographic Verification',
        zh: '哈希完整性自动比对',
        eo: 'Aŭtomata Haketkoda Kontrolo',
      );
  String get feature2Desc => _t(
        en: 'Automated post-download SHA-256 and MD5 verification against published checksums.',
        zh: '下载完成后自动执行 SHA-256 与 MD5 比对，确保安装包完整无篡改。',
        eo: 'Aŭtomata kontrolo de SHA-256 kaj MD5 post elŝuto kontraŭ oficialaj kodoj.',
      );
  String get feature3Title => _t(
        en: 'Range Concurrent Transfer Engine',
        zh: '分块并发下载引擎',
        eo: 'Range-Elŝuta Motoro',
      );
  String get feature3Desc => _t(
        en: 'Native multi-connection Range chunking, pause/resume capability, and live metrics.',
        zh: '原生切片并发传输、断点续传与精确速率耗时预测。',
        eo: 'Plurera elŝutado, paŭzo/rekomenco kaj realtempa rapideco.',
      );
  String get logInWithBroadcom => _t(
        en: 'Log In with Broadcom',
        zh: '登录 Broadcom 账户',
        eo: 'Ensaluti per Broadcom',
      );
  String get registerAccount => _t(
        en: 'Register Account',
        zh: '注册官方账户',
        eo: 'Registri Konton',
      );
  String get quickDemoAccess => _t(
        en: 'Quick Demo Access',
        zh: '免登录快速体验',
        eo: 'Ekzamena Reĝimo (Sen Ensaluto)',
      );

  // ==================== Common / Helpers ====================
  String copiedToClipboard(String label) => _t(
        en: '$label copied to clipboard.',
        zh: '已将 $label 复制至剪贴板。',
        eo: '$label kopiita al tondujo.',
      );
  String copyLabel(String label) => _t(
        en: 'Copy $label',
        zh: '复制 $label',
        eo: 'Kopii $label',
      );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh', 'eo'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
