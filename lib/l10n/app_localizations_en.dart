// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get catalog => 'Catalog';

  @override
  String get downloads => 'Downloads';

  @override
  String get settings => 'Settings';

  @override
  String get officialCompanion => 'Official Companion';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signIn => 'Sign In';

  @override
  String get sessionDetails => 'Session Details';

  @override
  String get broadcomSession => 'Broadcom Session';

  @override
  String get authenticatedUser => 'Authenticated User';

  @override
  String get noActiveSession => 'No active session';

  @override
  String get switchToLightMode => 'Switch to Light Theme';

  @override
  String get switchToDarkMode => 'Switch to Dark Theme';

  @override
  String get accountOptions => 'Account Options';

  @override
  String get signOutConfirmTitle => 'Sign Out';

  @override
  String get signOutConfirmContent =>
      'Are you sure you want to sign out? Cached credentials and session tokens will be removed.';

  @override
  String get signedOutSuccess => 'Signed out successfully.';

  @override
  String get searchPlaceholder => 'Search version, build, or release file...';

  @override
  String get allPlatforms => 'All Platforms';

  @override
  String get windowsOnly => 'Windows (.exe)';

  @override
  String get linuxOnly => 'Linux (.bundle)';

  @override
  String get filterPlatform => 'Filter Platform';

  @override
  String get syncOnlineCatalog => 'Sync Catalog';

  @override
  String get fetchingReleases => 'Fetching live releases from Broadcom...';

  @override
  String get noOnlineReleasesLoaded => 'No Releases Loaded';

  @override
  String get noReleasesFound => 'No matching releases found.';

  @override
  String get authRequiredTitle => 'Broadcom Account Required';

  @override
  String get authRequiredDesc =>
      'Sign in to access official download links, release packages, and verified checksums.';

  @override
  String get reauthenticate => 'Re-authenticate';

  @override
  String get selectItemToView =>
      'Select an installer package to inspect metadata, checksums, and download links.';

  @override
  String get liveBadge => 'Live';

  @override
  String get officialReleasePackage => 'Official Release Package';

  @override
  String get version => 'Version';

  @override
  String get releaseDate => 'Release Date';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get fileSize => 'File Size';

  @override
  String get fileName => 'File Name';

  @override
  String get buildNumber => 'Build Number';

  @override
  String get sha256Checksum => 'SHA256 Checksum';

  @override
  String get md5Checksum => 'MD5 Checksum';

  @override
  String get downloadPackage => 'Download Package';

  @override
  String get packageDownloaded => 'Download Completed';

  @override
  String get verifiedAgainstChecksums => 'Integrity Verified (SHA256 & MD5)';

  @override
  String get viewManager => 'View Downloads';

  @override
  String get techMetadataSpec => 'Technical Specifications';

  @override
  String get cryptographicChecksums => 'Cryptographic Checksums';

  @override
  String get licensingNote => 'Licensing & Entitlement';

  @override
  String get viewOnBroadcomPortal => 'Open in Broadcom Support Portal';

  @override
  String get selectReleaseToInspect =>
      'Select a release to inspect technical metadata';

  @override
  String get showInFinder => 'Show in Finder';

  @override
  String get showInFolder => 'Show in Folder';

  @override
  String get openInstaller => 'Open Installer';

  @override
  String get reVerifyChecksum => 'Re-verify Hash';

  @override
  String get activeRecentTransfers => 'Active & Recent Transfers';

  @override
  String get noDownloadsYet => 'No Downloads';

  @override
  String get noDownloadsDesc =>
      'Select VMware Workstation Pro or Fusion in the Catalog to begin.';

  @override
  String get browseCatalog => 'Browse Catalog';

  @override
  String get downloadDirectoryLabel => 'Storage Location';

  @override
  String get resolvingLocalPath => 'Resolving path...';

  @override
  String get openFolder => 'Open Folder';

  @override
  String get pause => 'Pause';

  @override
  String get resumeRetry => 'Resume';

  @override
  String get deleteRemove => 'Remove';

  @override
  String get statusDownloading => 'Downloading';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusVerifying => 'Verifying Integrity...';

  @override
  String get statusPassed => 'Verified';

  @override
  String get statusMismatch => 'Checksum Mismatch';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get speedLabel => 'Speed';

  @override
  String get etaLabel => 'ETA';

  @override
  String get setDownloadDirTitle => 'Set Storage Directory';

  @override
  String get setDownloadDirSubtitle =>
      'Where should VMware packages and disk images be saved?';

  @override
  String get systemDownloadsTitle => 'System Downloads';

  @override
  String get systemDownloadsDesc =>
      'Standard default path (~/Downloads/VMwareGet)';

  @override
  String get chooseCustomFolderTitle => 'Custom Location';

  @override
  String get chooseCustomFolderDesc =>
      'Browse and choose another destination on disk';

  @override
  String get selectDownloadDirPrompt => 'Select VMware Download Directory';

  @override
  String get recommended => 'Recommended';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmAndDownload => 'Confirm & Download';

  @override
  String get technicalDiagnosticsSection => 'Diagnostics & Logs';

  @override
  String get diagnosticLogsTitle => 'Technical Diagnostic Logs';

  @override
  String get diagnosticSubtitle =>
      'Real-time pipeline tracking: authentication, token lifecycle, and transfer metrics';

  @override
  String get filterLogsHint => 'Filter logs by keyword or payload...';

  @override
  String get filterAll => 'All';

  @override
  String get filterErrors => 'Errors';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get noLogsYet =>
      'No diagnostic logs yet. Trigger a sync or login to inspect activity.';

  @override
  String get noLogsMatching => 'No logs matching current filter.';

  @override
  String get copyAllLogs => 'Copy All Logs';

  @override
  String get close => 'Close';

  @override
  String get diagnosticCopied => 'Diagnostic report copied to clipboard.';

  @override
  String get viewDiagnosticLogs => 'View Diagnostics';

  @override
  String get settingsAndAccount => 'Settings & Account';

  @override
  String get exportComplianceScreening => 'Export Compliance Screening:';

  @override
  String get complianceApproved => 'Approved (Global Free Personal Use)';

  @override
  String get sessionPersistence => 'Session Storage:';

  @override
  String get encryptedStorageActive =>
      'Hardware-Encrypted Secure Storage Active';

  @override
  String get downloadStorageSection => 'Download Storage';

  @override
  String get downloadDestinationDir => 'Destination Directory';

  @override
  String get downloadDirSubtitle =>
      'All installer packages and disk images will be saved here';

  @override
  String get changeDirectory => 'Change Location...';

  @override
  String get openInFinderOrExplorer => 'Open Directory';

  @override
  String get resetToDefault => 'Reset to System Default';

  @override
  String get multiThreadingSection => 'Range Concurrency';

  @override
  String get multiThreadingSubtitle =>
      'Concurrent HTTP Range connections for accelerated throughput';

  @override
  String get threadsLabel => 'Connections';

  @override
  String get threadsSingle => '1';

  @override
  String get threadsDefault => '16';

  @override
  String get threadsMax => '64';

  @override
  String get multiThreadingHint =>
      '💡 Pure Dart native Range concurrency writes directly to disk offsets without external tools.';

  @override
  String get defaultLabel => 'Default';

  @override
  String get maxLabel => 'Max';

  @override
  String get languageSection => 'Display Language';

  @override
  String get displayLanguage => 'Interface Language';

  @override
  String get appearanceSection => 'Appearance & Theme';

  @override
  String get materialThemeMode => 'Material Design 3 Theme';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get appInformationSection => 'About Application';

  @override
  String get appIdentifier => 'Bundle Identifier';

  @override
  String get frameworkEngine => 'Engine & Runtime';

  @override
  String get designSystem => 'Design System';

  @override
  String get targetPlatforms => 'Supported Platforms';

  @override
  String get broadcomAuthTitle => 'Broadcom Authentication';

  @override
  String get broadcomAuthSubtitle =>
      'Connect your official Broadcom support portal session';

  @override
  String get tabInAppBrowser => 'In-App Web';

  @override
  String get tabManualImport => 'cURL / Manual Import';

  @override
  String get inAppBrowserTitle => 'In-App Browser Authentication';

  @override
  String get inAppBrowserDesc =>
      'Opens secure WKWebView window & auto-captures session cookies upon login';

  @override
  String get signInViaInApp => 'Sign In via In-App Browser';

  @override
  String get authenticatingInApp => 'Authenticating in-app portal...';

  @override
  String get instantDemoSession => 'Instant Demo Session';

  @override
  String get externalBrowser => 'External Browser';

  @override
  String get pasteFromClipboard => 'Paste from Clipboard';

  @override
  String get copyHelperSnippet => 'Copy Capture Snippet';

  @override
  String get importPlaywrightSession =>
      'Import active session from local test cache';

  @override
  String get accountEmailLabel => 'Account Email';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get tokenLabel => 'Broadcom Cookie String or cURL Command';

  @override
  String get tokenHint => 'Paste Cookie header or curl command here';

  @override
  String get tokenRequired => 'Please enter your session cookie or token';

  @override
  String get connectSession => 'Connect Session';

  @override
  String get clipboardEmpty => 'Clipboard is empty.';

  @override
  String get payloadPasted => 'Session payload pasted from clipboard.';

  @override
  String get cookieHelperCopied =>
      'Cookie capture snippet copied. Paste into browser console on Broadcom page.';

  @override
  String get welcomeTitle => 'Welcome to VMwareGet';

  @override
  String get welcomeSubtitle =>
      'The clean, native companion to authenticate, browse, and securely download official VMware Workstation Pro and Fusion releases.';

  @override
  String get feature1Title => 'Official Broadcom Software Packages';

  @override
  String get feature1Desc =>
      'Direct and authentic downloads for VMware Workstation Pro and VMware Fusion.';

  @override
  String get feature2Title => 'Automated Cryptographic Verification';

  @override
  String get feature2Desc =>
      'Automated post-download SHA-256 and MD5 verification against published checksums.';

  @override
  String get feature3Title => 'Range Concurrent Transfer Engine';

  @override
  String get feature3Desc =>
      'Native multi-connection Range chunking, pause/resume capability, and live metrics.';

  @override
  String get logInWithBroadcom => 'Log In with Broadcom';

  @override
  String get registerAccount => 'Register Account';

  @override
  String get quickDemoAccess => 'Quick Demo Access';

  @override
  String get langEnglish => 'English';

  @override
  String get langChinese => '简体中文';

  @override
  String get langEsperanto => 'Esperanto';

  @override
  String activeCountBadge(int count) {
    return '$count active';
  }

  @override
  String copiedLogLines(int count) {
    return 'Copied $count log entries to clipboard.';
  }

  @override
  String copiedToClipboard(String label) {
    return '$label copied to clipboard.';
  }

  @override
  String copyLabel(String label) {
    return 'Copy $label';
  }
}
