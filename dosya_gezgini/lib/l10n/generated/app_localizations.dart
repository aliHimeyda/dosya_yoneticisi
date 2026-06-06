import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'File Explorer'**
  String get appTitle;

  /// No description provided for @actionLabel.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get actionLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @deepCleanup.
  ///
  /// In en, this message translates to:
  /// **'Deep Cleanup'**
  String get deepCleanup;

  /// No description provided for @privateFiles.
  ///
  /// In en, this message translates to:
  /// **'Private Files'**
  String get privateFiles;

  /// No description provided for @savedFiles.
  ///
  /// In en, this message translates to:
  /// **'Saved Files'**
  String get savedFiles;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorOccurred;

  /// No description provided for @fileAccessUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is not accessible right now.'**
  String get fileAccessUnavailable;

  /// No description provided for @fileAccessInvalidPath.
  ///
  /// In en, this message translates to:
  /// **'The path is invalid or corrupted.'**
  String get fileAccessInvalidPath;

  /// No description provided for @fileAccessDeleted.
  ///
  /// In en, this message translates to:
  /// **'The item can no longer be found.'**
  String get fileAccessDeleted;

  /// No description provided for @fileAccessExpectedDirectory.
  ///
  /// In en, this message translates to:
  /// **'This path is not a valid folder.'**
  String get fileAccessExpectedDirectory;

  /// No description provided for @fileAccessReadDenied.
  ///
  /// In en, this message translates to:
  /// **'This folder cannot be read.'**
  String get fileAccessReadDenied;

  /// No description provided for @fileAccessPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Access to this path was denied.'**
  String get fileAccessPermissionDenied;

  /// No description provided for @fileAccessSymbolicLinkUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Symbolic link paths are not supported.'**
  String get fileAccessSymbolicLinkUnsupported;

  /// No description provided for @fileSyncItemsMissing.
  ///
  /// In en, this message translates to:
  /// **'{count} tracked items could not be found and were removed from the lists.'**
  String fileSyncItemsMissing(int count);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @recentlyVisited.
  ///
  /// In en, this message translates to:
  /// **'Recently Visited'**
  String get recentlyVisited;

  /// No description provided for @noOpenedFolder.
  ///
  /// In en, this message translates to:
  /// **'No opened folder yet.'**
  String get noOpenedFolder;

  /// No description provided for @listEnd.
  ///
  /// In en, this message translates to:
  /// **'----------  End of List  ----------'**
  String get listEnd;

  /// No description provided for @categoryFiles.
  ///
  /// In en, this message translates to:
  /// **'files'**
  String get categoryFiles;

  /// No description provided for @categoryExcel.
  ///
  /// In en, this message translates to:
  /// **'excel'**
  String get categoryExcel;

  /// No description provided for @categoryImages.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get categoryImages;

  /// No description provided for @categoryVideos.
  ///
  /// In en, this message translates to:
  /// **'videos'**
  String get categoryVideos;

  /// No description provided for @categoryAudio.
  ///
  /// In en, this message translates to:
  /// **'audio'**
  String get categoryAudio;

  /// No description provided for @categoryWord.
  ///
  /// In en, this message translates to:
  /// **'word'**
  String get categoryWord;

  /// No description provided for @categoryPowerPoint.
  ///
  /// In en, this message translates to:
  /// **'slides'**
  String get categoryPowerPoint;

  /// No description provided for @categoryArchives.
  ///
  /// In en, this message translates to:
  /// **'archive'**
  String get categoryArchives;

  /// No description provided for @categoryPdf.
  ///
  /// In en, this message translates to:
  /// **'pdf'**
  String get categoryPdf;

  /// No description provided for @categoryText.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get categoryText;

  /// No description provided for @folderEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no files or folders in this directory.'**
  String get folderEmpty;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @searchMinCharacters.
  ///
  /// In en, this message translates to:
  /// **'Type at least {count} characters to search.'**
  String searchMinCharacters(int count);

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results found.'**
  String get noSearchResults;

  /// No description provided for @createFolder.
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createFolder;

  /// No description provided for @hiddenFiles.
  ///
  /// In en, this message translates to:
  /// **'Hidden Files'**
  String get hiddenFiles;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning, selected items will be deleted!'**
  String get deleteWarning;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @cutReady.
  ///
  /// In en, this message translates to:
  /// **'Added to clipboard for moving'**
  String get cutReady;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @copyWithNewName.
  ///
  /// In en, this message translates to:
  /// **'Copy with new name'**
  String get copyWithNewName;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get passwordHint;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @newFolderDefaultName.
  ///
  /// In en, this message translates to:
  /// **'new folder'**
  String get newFolderDefaultName;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delete completed successfully'**
  String get deleteSuccess;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @newFolderCreated.
  ///
  /// In en, this message translates to:
  /// **'New folder created'**
  String get newFolderCreated;

  /// No description provided for @newFileAdded.
  ///
  /// In en, this message translates to:
  /// **'New file added'**
  String get newFileAdded;

  /// No description provided for @renameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rename completed successfully'**
  String get renameSuccess;

  /// No description provided for @savedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedSuccess;

  /// No description provided for @hiddenSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hiddenSuccess;

  /// No description provided for @pasteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Paste completed successfully'**
  String get pasteSuccess;

  /// No description provided for @targetFolderNotFound.
  ///
  /// In en, this message translates to:
  /// **'The destination folder can no longer be found.'**
  String get targetFolderNotFound;

  /// No description provided for @destinationInsideSource.
  ///
  /// In en, this message translates to:
  /// **'A folder cannot be copied or moved into itself.'**
  String get destinationInsideSource;

  /// No description provided for @operationRolledBack.
  ///
  /// In en, this message translates to:
  /// **'The operation could not be completed and all changes were rolled back.'**
  String get operationRolledBack;

  /// No description provided for @operationRollbackFailed.
  ///
  /// In en, this message translates to:
  /// **'The operation failed and rollback could not be completed.'**
  String get operationRollbackFailed;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name'**
  String get invalidName;

  /// No description provided for @itemAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An item with the same name already exists'**
  String get itemAlreadyExists;

  /// No description provided for @insufficientStorageSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough free space'**
  String get insufficientStorageSpace;

  /// No description provided for @operationDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting items...'**
  String get operationDeleting;

  /// No description provided for @operationCopying.
  ///
  /// In en, this message translates to:
  /// **'Copying items...'**
  String get operationCopying;

  /// No description provided for @operationMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving items...'**
  String get operationMoving;

  /// No description provided for @operationDeletingProgress.
  ///
  /// In en, this message translates to:
  /// **'Delete operation in progress'**
  String get operationDeletingProgress;

  /// No description provided for @operationCopyingProgress.
  ///
  /// In en, this message translates to:
  /// **'Copy operation in progress'**
  String get operationCopyingProgress;

  /// No description provided for @operationMovingProgress.
  ///
  /// In en, this message translates to:
  /// **'Move operation in progress'**
  String get operationMovingProgress;

  /// No description provided for @operationCreatingFolderProgress.
  ///
  /// In en, this message translates to:
  /// **'Folder creation in progress'**
  String get operationCreatingFolderProgress;

  /// No description provided for @operationRenamingProgress.
  ///
  /// In en, this message translates to:
  /// **'Rename operation in progress'**
  String get operationRenamingProgress;

  /// No description provided for @operationSyncingRecordsProgress.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing records'**
  String get operationSyncingRecordsProgress;

  /// No description provided for @operationRefreshingRootProgress.
  ///
  /// In en, this message translates to:
  /// **'Refreshing folder list'**
  String get operationRefreshingRootProgress;

  /// No description provided for @operationRefreshingFolderProgress.
  ///
  /// In en, this message translates to:
  /// **'Refreshing folder content'**
  String get operationRefreshingFolderProgress;

  /// No description provided for @operationRefreshingIndexProgress.
  ///
  /// In en, this message translates to:
  /// **'Refreshing search and category index'**
  String get operationRefreshingIndexProgress;

  /// No description provided for @nameConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Name conflict'**
  String get nameConflictTitle;

  /// No description provided for @nameConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} already exists. How would you like to continue?'**
  String nameConflictMessage(String name);

  /// No description provided for @cleanupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Cleanup in progress...'**
  String get cleanupInProgress;

  /// No description provided for @operationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Operation completed'**
  String get operationCompleted;

  /// No description provided for @temporaryFilesCollected.
  ///
  /// In en, this message translates to:
  /// **'Temporary files scanned'**
  String get temporaryFilesCollected;

  /// No description provided for @cacheFilesCollected.
  ///
  /// In en, this message translates to:
  /// **'Cache files scanned'**
  String get cacheFilesCollected;

  /// No description provided for @cleanupWillFree.
  ///
  /// In en, this message translates to:
  /// **'{size} MB will be freed'**
  String cleanupWillFree(String size);

  /// No description provided for @cleanupReady.
  ///
  /// In en, this message translates to:
  /// **'Cleanup ready'**
  String get cleanupReady;

  /// No description provided for @cleanupNothingToClean.
  ///
  /// In en, this message translates to:
  /// **'No files matched the cleanup rules'**
  String get cleanupNothingToClean;

  /// No description provided for @cleanupDeleting.
  ///
  /// In en, this message translates to:
  /// **'Applying cleanup...'**
  String get cleanupDeleting;

  /// No description provided for @cleanupScannedFiles.
  ///
  /// In en, this message translates to:
  /// **'Scanned files: {count}'**
  String cleanupScannedFiles(int count);

  /// No description provided for @cleanupCandidatesFound.
  ///
  /// In en, this message translates to:
  /// **'Cleanup candidates: {count}'**
  String cleanupCandidatesFound(int count);

  /// No description provided for @cleanupRecoverableSpace.
  ///
  /// In en, this message translates to:
  /// **'Recoverable space: {size}'**
  String cleanupRecoverableSpace(String size);

  /// No description provided for @cleanupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Start cleanup'**
  String get cleanupConfirmTitle;

  /// No description provided for @cleanupConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} files will be deleted and {size} will be freed. Continue?'**
  String cleanupConfirmMessage(int count, String size);

  /// No description provided for @cleanupDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'Deleted files: {count}'**
  String cleanupDeletedCount(int count);

  /// No description provided for @cleanupFailedCount.
  ///
  /// In en, this message translates to:
  /// **'Failed files: {count}'**
  String cleanupFailedCount(int count);

  /// No description provided for @cleanupCurrentFile.
  ///
  /// In en, this message translates to:
  /// **'Current file'**
  String get cleanupCurrentFile;

  /// No description provided for @cleanupReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleanup report'**
  String get cleanupReportTitle;

  /// No description provided for @cleanupFreedSpace.
  ///
  /// In en, this message translates to:
  /// **'Freed space: {size}'**
  String cleanupFreedSpace(String size);

  /// No description provided for @cleanupScanIssues.
  ///
  /// In en, this message translates to:
  /// **'Scan issues ({count})'**
  String cleanupScanIssues(int count);

  /// No description provided for @cleanupDeleteIssues.
  ///
  /// In en, this message translates to:
  /// **'Delete issues ({count})'**
  String cleanupDeleteIssues(int count);

  /// No description provided for @clean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get clean;

  /// No description provided for @categoryIndexPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing {category} files...'**
  String categoryIndexPreparing(String category);

  /// No description provided for @navigationMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navigationMenu;

  /// No description provided for @navigationRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get navigationRecent;

  /// No description provided for @navigationFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get navigationFolders;

  /// No description provided for @navigationSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navigationSearch;
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
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
