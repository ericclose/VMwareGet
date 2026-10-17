// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get catalog => '软件目录';

  @override
  String get downloads => '传输管理';

  @override
  String get settings => '偏好设置';

  @override
  String get officialCompanion => '下载分发助手';

  @override
  String get signOut => '退出登录';

  @override
  String get signIn => '登录';

  @override
  String get sessionDetails => '账户会话';

  @override
  String get broadcomSession => 'Broadcom 授权会话';

  @override
  String get authenticatedUser => '已认证用户';

  @override
  String get noActiveSession => '未登录有效会话';

  @override
  String get switchToLightMode => '切换浅色模式';

  @override
  String get switchToDarkMode => '切换深色模式';

  @override
  String get accountOptions => '账户选项';

  @override
  String get signOutConfirmTitle => '确认退出登录';

  @override
  String get signOutConfirmContent => '确定退出登录？本地缓存的 Broadcom 会话凭证与访问令牌将被清除。';

  @override
  String get signedOutSuccess => '已安全退出登录。';

  @override
  String get searchPlaceholder => '搜索版本号、Build 或文件名...';

  @override
  String get allPlatforms => '全平台';

  @override
  String get windowsOnly => 'Windows (.exe)';

  @override
  String get linuxOnly => 'Linux (.bundle)';

  @override
  String get filterPlatform => '筛选平台';

  @override
  String get syncOnlineCatalog => '同步最新目录';

  @override
  String get fetchingReleases => '正在同步 Broadcom 版本库...';

  @override
  String get noOnlineReleasesLoaded => '未加载到版本数据';

  @override
  String get noReleasesFound => '未找到匹配的安装包。';

  @override
  String get authRequiredTitle => '需登录 Broadcom 账户';

  @override
  String get authRequiredDesc => '请登录 Broadcom 账户以获取授权下载链接与校验元数据。';

  @override
  String get reauthenticate => '重新认证';

  @override
  String get selectItemToView => '请选择版本以查看规格参数、防篡改校验哈希与下载链接。';

  @override
  String get liveBadge => '实时';

  @override
  String get officialReleasePackage => '原厂安装包';

  @override
  String get version => '版本号';

  @override
  String get releaseDate => '发布日期';

  @override
  String get lastUpdated => '更新时间';

  @override
  String get fileSize => '文件大小';

  @override
  String get fileName => '文件名';

  @override
  String get buildNumber => 'Build 编号';

  @override
  String get sha256Checksum => 'SHA256 校验码';

  @override
  String get md5Checksum => 'MD5 校验码';

  @override
  String get downloadPackage => '开始下载';

  @override
  String get packageDownloaded => '下载已完成';

  @override
  String get verifiedAgainstChecksums => '完整性校验通过 (SHA256 & MD5)';

  @override
  String get viewManager => '查看进度';

  @override
  String get techMetadataSpec => '技术规格';

  @override
  String get cryptographicChecksums => '防篡改校验哈希';

  @override
  String get licensingNote => '许可与授权说明';

  @override
  String get viewOnBroadcomPortal => '前往 Broadcom 支持门户';

  @override
  String get selectReleaseToInspect => '选择版本以查看技术规格与校验信息';

  @override
  String get showInFinder => '在访达中显示';

  @override
  String get showInFolder => '打开所在文件夹';

  @override
  String get openInstaller => '打开安装包';

  @override
  String get reVerifyChecksum => '重新校验';

  @override
  String get activeRecentTransfers => '传输任务';

  @override
  String get noDownloadsYet => '暂无传输任务';

  @override
  String get noDownloadsDesc => '在软件目录中选择对应版本即可发起下载。';

  @override
  String get browseCatalog => '前往软件目录';

  @override
  String get downloadDirectoryLabel => '存储目录';

  @override
  String get resolvingLocalPath => '正在解析存储路径...';

  @override
  String get openFolder => '打开目录';

  @override
  String get pause => '暂停';

  @override
  String get resumeRetry => '继续 / 重试';

  @override
  String get deleteRemove => '删除任务';

  @override
  String get statusDownloading => '下载中';

  @override
  String get statusPaused => '已暂停';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusFailed => '下载失败';

  @override
  String get statusVerifying => '正在校验完整性...';

  @override
  String get statusPassed => '完整性校验通过';

  @override
  String get statusMismatch => '校验哈希不匹配';

  @override
  String get statusQueued => '排队中';

  @override
  String get statusCancelled => '已取消';

  @override
  String get speedLabel => '速率';

  @override
  String get etaLabel => '预计剩余';

  @override
  String get setDownloadDirTitle => '选择存储目录';

  @override
  String get setDownloadDirSubtitle => '请设置安装包与磁盘映像的存储位置：';

  @override
  String get systemDownloadsTitle => '系统下载文件夹';

  @override
  String get systemDownloadsDesc => '推荐默认路径 (~/Downloads/VMwareGet)';

  @override
  String get chooseCustomFolderTitle => '自定义目标文件夹';

  @override
  String get chooseCustomFolderDesc => '选择磁盘上的其他存储文件夹';

  @override
  String get selectDownloadDirPrompt => '选择 VMware 下载存储目录';

  @override
  String get recommended => '推荐';

  @override
  String get cancel => '取消';

  @override
  String get confirmAndDownload => '确认并下载';

  @override
  String get technicalDiagnosticsSection => '诊断日志';

  @override
  String get diagnosticLogsTitle => '技术诊断日志';

  @override
  String get diagnosticSubtitle => '实时记录认证会话、网络请求耗时与切片下载状态';

  @override
  String get filterLogsHint => '按关键词、Tag 或载荷过滤日志...';

  @override
  String get filterAll => '全部';

  @override
  String get filterErrors => '错误';

  @override
  String get clearLogs => '清空日志';

  @override
  String get noLogsYet => '暂无诊断日志。发起登录或目录同步即可实时追踪。';

  @override
  String get noLogsMatching => '未找到符合条件的日志。';

  @override
  String get copyAllLogs => '复制全部日志';

  @override
  String get close => '关闭';

  @override
  String get diagnosticCopied => '诊断报告已复制至剪贴板。';

  @override
  String get viewDiagnosticLogs => '查看诊断';

  @override
  String get settingsAndAccount => '偏好设置与账户';

  @override
  String get exportComplianceScreening => '出口合规审查：';

  @override
  String get complianceApproved => '已通过（全球免费个人许可）';

  @override
  String get sessionPersistence => '会话存储：';

  @override
  String get encryptedStorageActive => '本地安全加密存储已就绪';

  @override
  String get downloadStorageSection => '存储配置';

  @override
  String get downloadDestinationDir => '安装包存储目录';

  @override
  String get downloadDirSubtitle => '下载的所有安装包与磁盘映像均存储于此文件夹';

  @override
  String get changeDirectory => '更改目录...';

  @override
  String get openInFinderOrExplorer => '打开目录';

  @override
  String get resetToDefault => '恢复默认';

  @override
  String get multiThreadingSection => '切片分块并发';

  @override
  String get multiThreadingSubtitle => '利用 HTTP Range 分块并发请求以跑满网络带宽';

  @override
  String get threadsLabel => '线程数';

  @override
  String get threadsSingle => '1';

  @override
  String get threadsDefault => '16';

  @override
  String get threadsMax => '64';

  @override
  String get multiThreadingHint => '💡 原生 Dart Range 并发切片传输，按偏移量直接定点落盘，配置即刻生效。';

  @override
  String get defaultLabel => '默认';

  @override
  String get maxLabel => '极速';

  @override
  String get languageSection => '显示语言';

  @override
  String get displayLanguage => '界面语言';

  @override
  String get appearanceSection => '外观与主题';

  @override
  String get materialThemeMode => 'Material Design 3 风格';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get appInformationSection => '关于';

  @override
  String get appIdentifier => '应用标识符';

  @override
  String get frameworkEngine => '核心引擎';

  @override
  String get designSystem => '设计系统';

  @override
  String get targetPlatforms => '支持平台';

  @override
  String get broadcomAuthTitle => 'Broadcom 账户认证';

  @override
  String get broadcomAuthSubtitle => '连接 Broadcom 支持门户会话';

  @override
  String get tabInAppBrowser => '内嵌 Web 视图登录';

  @override
  String get tabManualImport => '手动导入';

  @override
  String get inAppBrowserTitle => '内嵌浏览器一键登录';

  @override
  String get inAppBrowserDesc => '打开安全 Web 视图，登录成功后自动捕获并导入会话凭证';

  @override
  String get signInViaInApp => '启动内嵌浏览器登录';

  @override
  String get authenticatingInApp => '正在等待登录完成...';

  @override
  String get instantDemoSession => '快速体验';

  @override
  String get externalBrowser => '系统默认浏览器';

  @override
  String get pasteFromClipboard => '从剪贴板粘贴';

  @override
  String get copyHelperSnippet => '复制抓取脚本';

  @override
  String get importPlaywrightSession => '从本地测试缓存导入有效会话';

  @override
  String get accountEmailLabel => '账户邮箱';

  @override
  String get emailRequired => '请输入邮箱';

  @override
  String get emailInvalid => '请输入有效的邮箱地址';

  @override
  String get tokenLabel => 'Cookie 字符串或 cURL 命令';

  @override
  String get tokenHint => '在此粘贴 Cookie 请求头或 cURL 命令';

  @override
  String get tokenRequired => '请输入会话 Cookie 或 Token';

  @override
  String get connectSession => '接入会话';

  @override
  String get clipboardEmpty => '剪贴板内容为空。';

  @override
  String get payloadPasted => '已读取并填充剪贴板凭证。';

  @override
  String get cookieHelperCopied => '提取脚本已复制，可在浏览器开发者控制台中粘贴运行。';

  @override
  String get welcomeTitle => '欢迎使用 VMwareGet';

  @override
  String get welcomeSubtitle => '极简的 VMware 安装包高速下载与完整性校验工具';

  @override
  String get feature1Title => '正版软件渠道';

  @override
  String get feature1Desc => '直连原厂安全下载源，全面支持 VMware Workstation Pro 与 Fusion。';

  @override
  String get feature2Title => '哈希完整性自动比对';

  @override
  String get feature2Desc => '下载完成后自动执行 SHA-256 与 MD5 比对，确保安装包完整无篡改。';

  @override
  String get feature3Title => '分块并发下载引擎';

  @override
  String get feature3Desc => '原生切片并发传输、断点续传与精确速率耗时预测。';

  @override
  String get feature1Pill => '原包直链';

  @override
  String get feature2Pill => '哈希自动校验';

  @override
  String get feature3Pill => '多线程高速下载';

  @override
  String get manualCookieGuideTitle => '如何获取 Cookies？';

  @override
  String get manualCookieStep1 => '1. 浏览器访问并登录 access.broadcom.com';

  @override
  String get manualCookieStep2 =>
      '2. 按 F12 打开开发者工具 ➔ 网络(Network) ➔ 右键任意请求选择「复制为 cURL」（或在控制台输入 document.cookie 复制）';

  @override
  String get manualCookieStep3 => '3. 点击下方「从剪贴板粘贴」，程序将自动解析 Cookie 与邮箱并接入会话';

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get logInWithBroadcom => '登录 Broadcom 账户';

  @override
  String get registerAccount => '注册 Broadcom 账户';

  @override
  String get quickDemoAccess => '免登录快速体验';

  @override
  String get langEnglish => 'English';

  @override
  String get langChinese => '简体中文';

  @override
  String get langEsperanto => 'Esperanto';

  @override
  String activeCountBadge(int count) {
    return '$count 个进行中';
  }

  @override
  String copiedLogLines(int count) {
    return '已复制 $count 条日志至剪贴板。';
  }

  @override
  String copiedToClipboard(String label) {
    return '已将 $label 复制至剪贴板。';
  }

  @override
  String copyLabel(String label) {
    return '复制 $label';
  }

  @override
  String get copyDirectDownloadLink => '复制下载直链';

  @override
  String get copyDirectDownloadLinkSuccess => '安装包下载直链已复制至剪贴板。';

  @override
  String get generatingDownloadLink => '正在生成授权下载直链...';

  @override
  String get clearCompletedDownloads => '清除已完成记录';

  @override
  String get broadcomSessionExpiredTip => 'Broadcom 登录凭据已过期，请重新登录以换取高速下载直链。';

  @override
  String get reloginAction => '重新登录';

  @override
  String get sessionExpiredTitle => '登录会话已过期';
}
