import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_eo.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('eo'),
    Locale('zh'),
  ];

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @officialCompanion.
  ///
  /// In en, this message translates to:
  /// **'Official Companion'**
  String get officialCompanion;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @sessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// No description provided for @broadcomSession.
  ///
  /// In en, this message translates to:
  /// **'Broadcom Session'**
  String get broadcomSession;

  /// No description provided for @authenticatedUser.
  ///
  /// In en, this message translates to:
  /// **'Authenticated User'**
  String get authenticatedUser;

  /// No description provided for @noActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get noActiveSession;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Light Theme'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Dark Theme'**
  String get switchToDarkMode;

  /// No description provided for @accountOptions.
  ///
  /// In en, this message translates to:
  /// **'Account Options'**
  String get accountOptions;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out? Cached credentials and session tokens will be removed.'**
  String get signOutConfirmContent;

  /// No description provided for @signedOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully.'**
  String get signedOutSuccess;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search version, build, or release file...'**
  String get searchPlaceholder;

  /// No description provided for @allPlatforms.
  ///
  /// In en, this message translates to:
  /// **'All Platforms'**
  String get allPlatforms;

  /// No description provided for @windowsOnly.
  ///
  /// In en, this message translates to:
  /// **'Windows (.exe)'**
  String get windowsOnly;

  /// No description provided for @linuxOnly.
  ///
  /// In en, this message translates to:
  /// **'Linux (.bundle)'**
  String get linuxOnly;

  /// No description provided for @filterPlatform.
  ///
  /// In en, this message translates to:
  /// **'Filter Platform'**
  String get filterPlatform;

  /// No description provided for @syncOnlineCatalog.
  ///
  /// In en, this message translates to:
  /// **'Sync Catalog'**
  String get syncOnlineCatalog;

  /// No description provided for @fetchingReleases.
  ///
  /// In en, this message translates to:
  /// **'Fetching live releases from Broadcom...'**
  String get fetchingReleases;

  /// No description provided for @noOnlineReleasesLoaded.
  ///
  /// In en, this message translates to:
  /// **'No Releases Loaded'**
  String get noOnlineReleasesLoaded;

  /// No description provided for @noReleasesFound.
  ///
  /// In en, this message translates to:
  /// **'No matching releases found.'**
  String get noReleasesFound;

  /// No description provided for @authRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcom Account Required'**
  String get authRequiredTitle;

  /// No description provided for @authRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access official download links, release packages, and verified checksums.'**
  String get authRequiredDesc;

  /// No description provided for @reauthenticate.
  ///
  /// In en, this message translates to:
  /// **'Re-authenticate'**
  String get reauthenticate;

  /// No description provided for @selectItemToView.
  ///
  /// In en, this message translates to:
  /// **'Select an installer package to inspect metadata, checksums, and download links.'**
  String get selectItemToView;

  /// No description provided for @liveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveBadge;

  /// No description provided for @officialReleasePackage.
  ///
  /// In en, this message translates to:
  /// **'Official Release Package'**
  String get officialReleasePackage;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDate;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @sha256Checksum.
  ///
  /// In en, this message translates to:
  /// **'SHA256 Checksum'**
  String get sha256Checksum;

  /// No description provided for @md5Checksum.
  ///
  /// In en, this message translates to:
  /// **'MD5 Checksum'**
  String get md5Checksum;

  /// No description provided for @downloadPackage.
  ///
  /// In en, this message translates to:
  /// **'Download Package'**
  String get downloadPackage;

  /// No description provided for @packageDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Download Completed'**
  String get packageDownloaded;

  /// No description provided for @verifiedAgainstChecksums.
  ///
  /// In en, this message translates to:
  /// **'Integrity Verified (SHA256 & MD5)'**
  String get verifiedAgainstChecksums;

  /// No description provided for @viewManager.
  ///
  /// In en, this message translates to:
  /// **'View Downloads'**
  String get viewManager;

  /// No description provided for @techMetadataSpec.
  ///
  /// In en, this message translates to:
  /// **'Technical Specifications'**
  String get techMetadataSpec;

  /// No description provided for @cryptographicChecksums.
  ///
  /// In en, this message translates to:
  /// **'Cryptographic Checksums'**
  String get cryptographicChecksums;

  /// No description provided for @licensingNote.
  ///
  /// In en, this message translates to:
  /// **'Licensing & Entitlement'**
  String get licensingNote;

  /// No description provided for @viewOnBroadcomPortal.
  ///
  /// In en, this message translates to:
  /// **'Open in Broadcom Support Portal'**
  String get viewOnBroadcomPortal;

  /// No description provided for @selectReleaseToInspect.
  ///
  /// In en, this message translates to:
  /// **'Select a release to inspect technical metadata'**
  String get selectReleaseToInspect;

  /// No description provided for @showInFinder.
  ///
  /// In en, this message translates to:
  /// **'Show in Finder'**
  String get showInFinder;

  /// No description provided for @showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in Folder'**
  String get showInFolder;

  /// No description provided for @openInstaller.
  ///
  /// In en, this message translates to:
  /// **'Open Installer'**
  String get openInstaller;

  /// No description provided for @reVerifyChecksum.
  ///
  /// In en, this message translates to:
  /// **'Re-verify Hash'**
  String get reVerifyChecksum;

  /// No description provided for @activeRecentTransfers.
  ///
  /// In en, this message translates to:
  /// **'Active & Recent Transfers'**
  String get activeRecentTransfers;

  /// No description provided for @noDownloadsYet.
  ///
  /// In en, this message translates to:
  /// **'No Downloads'**
  String get noDownloadsYet;

  /// No description provided for @noDownloadsDesc.
  ///
  /// In en, this message translates to:
  /// **'Select VMware Workstation Pro or Fusion in the Catalog to begin.'**
  String get noDownloadsDesc;

  /// No description provided for @browseCatalog.
  ///
  /// In en, this message translates to:
  /// **'Browse Catalog'**
  String get browseCatalog;

  /// No description provided for @downloadDirectoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get downloadDirectoryLabel;

  /// No description provided for @resolvingLocalPath.
  ///
  /// In en, this message translates to:
  /// **'Resolving path...'**
  String get resolvingLocalPath;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resumeRetry.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeRetry;

  /// No description provided for @deleteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get deleteRemove;

  /// No description provided for @statusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get statusDownloading;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying Integrity...'**
  String get statusVerifying;

  /// No description provided for @statusPassed.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusPassed;

  /// No description provided for @statusMismatch.
  ///
  /// In en, this message translates to:
  /// **'Checksum Mismatch'**
  String get statusMismatch;

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @speedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedLabel;

  /// No description provided for @etaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get etaLabel;

  /// No description provided for @setDownloadDirTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Storage Directory'**
  String get setDownloadDirTitle;

  /// No description provided for @setDownloadDirSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where should VMware packages and disk images be saved?'**
  String get setDownloadDirSubtitle;

  /// No description provided for @systemDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'System Downloads'**
  String get systemDownloadsTitle;

  /// No description provided for @systemDownloadsDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard default path (~/Downloads/VMwareGet)'**
  String get systemDownloadsDesc;

  /// No description provided for @chooseCustomFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Location'**
  String get chooseCustomFolderTitle;

  /// No description provided for @chooseCustomFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse and choose another destination on disk'**
  String get chooseCustomFolderDesc;

  /// No description provided for @selectDownloadDirPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select VMware Download Directory'**
  String get selectDownloadDirPrompt;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmAndDownload.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Download'**
  String get confirmAndDownload;

  /// No description provided for @technicalDiagnosticsSection.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics & Logs'**
  String get technicalDiagnosticsSection;

  /// No description provided for @diagnosticLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical Diagnostic Logs'**
  String get diagnosticLogsTitle;

  /// No description provided for @diagnosticSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time pipeline tracking: authentication, token lifecycle, and transfer metrics'**
  String get diagnosticSubtitle;

  /// No description provided for @filterLogsHint.
  ///
  /// In en, this message translates to:
  /// **'Filter logs by keyword or payload...'**
  String get filterLogsHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get filterErrors;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No diagnostic logs yet. Trigger a sync or login to inspect activity.'**
  String get noLogsYet;

  /// No description provided for @noLogsMatching.
  ///
  /// In en, this message translates to:
  /// **'No logs matching current filter.'**
  String get noLogsMatching;

  /// No description provided for @copyAllLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy All Logs'**
  String get copyAllLogs;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @diagnosticCopied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic report copied to clipboard.'**
  String get diagnosticCopied;

  /// No description provided for @viewDiagnosticLogs.
  ///
  /// In en, this message translates to:
  /// **'View Diagnostics'**
  String get viewDiagnosticLogs;

  /// No description provided for @settingsAndAccount.
  ///
  /// In en, this message translates to:
  /// **'Settings & Account'**
  String get settingsAndAccount;

  /// No description provided for @exportComplianceScreening.
  ///
  /// In en, this message translates to:
  /// **'Export Compliance Screening:'**
  String get exportComplianceScreening;

  /// No description provided for @complianceApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved (Global Free Personal Use)'**
  String get complianceApproved;

  /// No description provided for @sessionPersistence.
  ///
  /// In en, this message translates to:
  /// **'Session Storage:'**
  String get sessionPersistence;

  /// No description provided for @encryptedStorageActive.
  ///
  /// In en, this message translates to:
  /// **'Hardware-Encrypted Secure Storage Active'**
  String get encryptedStorageActive;

  /// No description provided for @downloadStorageSection.
  ///
  /// In en, this message translates to:
  /// **'Download Storage'**
  String get downloadStorageSection;

  /// No description provided for @downloadDestinationDir.
  ///
  /// In en, this message translates to:
  /// **'Destination Directory'**
  String get downloadDestinationDir;

  /// No description provided for @downloadDirSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All installer packages and disk images will be saved here'**
  String get downloadDirSubtitle;

  /// No description provided for @changeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Change Location...'**
  String get changeDirectory;

  /// No description provided for @openInFinderOrExplorer.
  ///
  /// In en, this message translates to:
  /// **'Open Directory'**
  String get openInFinderOrExplorer;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to System Default'**
  String get resetToDefault;

  /// No description provided for @multiThreadingSection.
  ///
  /// In en, this message translates to:
  /// **'Range Concurrency'**
  String get multiThreadingSection;

  /// No description provided for @multiThreadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Concurrent HTTP Range connections for accelerated throughput'**
  String get multiThreadingSubtitle;

  /// No description provided for @threadsLabel.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get threadsLabel;

  /// No description provided for @threadsSingle.
  ///
  /// In en, this message translates to:
  /// **'1 (Single)'**
  String get threadsSingle;

  /// No description provided for @threadsDefault.
  ///
  /// In en, this message translates to:
  /// **'16 (Default)'**
  String get threadsDefault;

  /// No description provided for @threadsMax.
  ///
  /// In en, this message translates to:
  /// **'64 (Turbo)'**
  String get threadsMax;

  /// No description provided for @multiThreadingHint.
  ///
  /// In en, this message translates to:
  /// **'💡 Pure Dart native Range concurrency writes directly to disk offsets without external tools.'**
  String get multiThreadingHint;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @maxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxLabel;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Display Language'**
  String get languageSection;

  /// No description provided for @displayLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface Language'**
  String get displayLanguage;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Theme'**
  String get appearanceSection;

  /// No description provided for @materialThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Material Design 3 Theme'**
  String get materialThemeMode;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @appInformationSection.
  ///
  /// In en, this message translates to:
  /// **'About Application'**
  String get appInformationSection;

  /// No description provided for @appIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Bundle Identifier'**
  String get appIdentifier;

  /// No description provided for @frameworkEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine & Runtime'**
  String get frameworkEngine;

  /// No description provided for @designSystem.
  ///
  /// In en, this message translates to:
  /// **'Design System'**
  String get designSystem;

  /// No description provided for @targetPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Supported Platforms'**
  String get targetPlatforms;

  /// No description provided for @broadcomAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcom Authentication'**
  String get broadcomAuthTitle;

  /// No description provided for @broadcomAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your official Broadcom support portal session'**
  String get broadcomAuthSubtitle;

  /// No description provided for @tabInAppBrowser.
  ///
  /// In en, this message translates to:
  /// **'In-App Web'**
  String get tabInAppBrowser;

  /// No description provided for @tabManualImport.
  ///
  /// In en, this message translates to:
  /// **'cURL / Manual Import'**
  String get tabManualImport;

  /// No description provided for @inAppBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'In-App Browser Authentication'**
  String get inAppBrowserTitle;

  /// No description provided for @inAppBrowserDesc.
  ///
  /// In en, this message translates to:
  /// **'Opens secure WKWebView window & auto-captures session cookies upon login'**
  String get inAppBrowserDesc;

  /// No description provided for @signInViaInApp.
  ///
  /// In en, this message translates to:
  /// **'Sign In via In-App Browser'**
  String get signInViaInApp;

  /// No description provided for @authenticatingInApp.
  ///
  /// In en, this message translates to:
  /// **'Authenticating in-app portal...'**
  String get authenticatingInApp;

  /// No description provided for @instantDemoSession.
  ///
  /// In en, this message translates to:
  /// **'Instant Demo Session'**
  String get instantDemoSession;

  /// No description provided for @externalBrowser.
  ///
  /// In en, this message translates to:
  /// **'External Browser'**
  String get externalBrowser;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @copyHelperSnippet.
  ///
  /// In en, this message translates to:
  /// **'Copy Capture Snippet'**
  String get copyHelperSnippet;

  /// No description provided for @importPlaywrightSession.
  ///
  /// In en, this message translates to:
  /// **'Import active session from local test cache'**
  String get importPlaywrightSession;

  /// No description provided for @accountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Email'**
  String get accountEmailLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @tokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Broadcom Cookie String or cURL Command'**
  String get tokenLabel;

  /// No description provided for @tokenHint.
  ///
  /// In en, this message translates to:
  /// **'Paste Cookie header or curl command here'**
  String get tokenHint;

  /// No description provided for @tokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your session cookie or token'**
  String get tokenRequired;

  /// No description provided for @connectSession.
  ///
  /// In en, this message translates to:
  /// **'Connect Session'**
  String get connectSession;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty.'**
  String get clipboardEmpty;

  /// No description provided for @payloadPasted.
  ///
  /// In en, this message translates to:
  /// **'Session payload pasted from clipboard.'**
  String get payloadPasted;

  /// No description provided for @cookieHelperCopied.
  ///
  /// In en, this message translates to:
  /// **'Cookie capture snippet copied. Paste into browser console on Broadcom page.'**
  String get cookieHelperCopied;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to VMwareGet'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The clean, native companion to authenticate, browse, and securely download official VMware Workstation Pro and Fusion releases.'**
  String get welcomeSubtitle;

  /// No description provided for @feature1Title.
  ///
  /// In en, this message translates to:
  /// **'Official Broadcom Software Packages'**
  String get feature1Title;

  /// No description provided for @feature1Desc.
  ///
  /// In en, this message translates to:
  /// **'Direct and authentic downloads for VMware Workstation Pro and VMware Fusion.'**
  String get feature1Desc;

  /// No description provided for @feature2Title.
  ///
  /// In en, this message translates to:
  /// **'Automated Cryptographic Verification'**
  String get feature2Title;

  /// No description provided for @feature2Desc.
  ///
  /// In en, this message translates to:
  /// **'Automated post-download SHA-256 and MD5 verification against published checksums.'**
  String get feature2Desc;

  /// No description provided for @feature3Title.
  ///
  /// In en, this message translates to:
  /// **'Range Concurrent Transfer Engine'**
  String get feature3Title;

  /// No description provided for @feature3Desc.
  ///
  /// In en, this message translates to:
  /// **'Native multi-connection Range chunking, pause/resume capability, and live metrics.'**
  String get feature3Desc;

  /// No description provided for @logInWithBroadcom.
  ///
  /// In en, this message translates to:
  /// **'Log In with Broadcom'**
  String get logInWithBroadcom;

  /// No description provided for @registerAccount.
  ///
  /// In en, this message translates to:
  /// **'Register Account'**
  String get registerAccount;

  /// No description provided for @quickDemoAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Demo Access'**
  String get quickDemoAccess;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English (Default)'**
  String get langEnglish;

  /// No description provided for @langChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get langChinese;

  /// No description provided for @langEsperanto.
  ///
  /// In en, this message translates to:
  /// **'Esperanto'**
  String get langEsperanto;

  /// Auto-generated entry for activeCountBadge
  ///
  /// In en, this message translates to:
  /// **'\$count active'**
  String activeCountBadge(int count);

  /// Auto-generated entry for copiedLogLines
  ///
  /// In en, this message translates to:
  /// **'Copied \$count log entries to clipboard.'**
  String copiedLogLines(int count);

  /// Auto-generated entry for copiedToClipboard
  ///
  /// In en, this message translates to:
  /// **'\$label copied to clipboard.'**
  String copiedToClipboard(String label);

  /// Auto-generated entry for copyLabel
  ///
  /// In en, this message translates to:
  /// **'Copy \$label'**
  String copyLabel(String label);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'eo', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'eo':
      return AppLocalizationsEo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
