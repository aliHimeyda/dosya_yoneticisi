// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'File Explorer';

  @override
  String get actionLabel => 'Action';

  @override
  String get languageLabel => 'Language';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get deepCleanup => 'Deep Cleanup';

  @override
  String get privateFiles => 'Private Files';

  @override
  String get savedFiles => 'Saved Files';

  @override
  String get errorOccurred => 'Something went wrong';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get recentlyVisited => 'Recently Visited';

  @override
  String get noOpenedFolder => 'No opened folder yet.';

  @override
  String get listEnd => '----------  End of List  ----------';

  @override
  String get categoryFiles => 'files';

  @override
  String get categoryExcel => 'excel';

  @override
  String get categoryImages => 'images';

  @override
  String get categoryVideos => 'videos';

  @override
  String get categoryAudio => 'audio';

  @override
  String get categoryWord => 'word';

  @override
  String get categoryPowerPoint => 'slides';

  @override
  String get categoryArchives => 'archive';

  @override
  String get categoryPdf => 'pdf';

  @override
  String get categoryText => 'text';

  @override
  String get folderEmpty => 'There are no files or folders in this directory.';

  @override
  String get searchHint => 'Search';

  @override
  String searchMinCharacters(int count) {
    return 'Type at least $count characters to search.';
  }

  @override
  String get noSearchResults => 'No search results found.';

  @override
  String get createFolder => 'Create Folder';

  @override
  String get hiddenFiles => 'Hidden Files';

  @override
  String get paste => 'Paste';

  @override
  String get deleteWarning => 'Warning, selected items will be deleted!';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get cut => 'Cut';

  @override
  String get cutReady => 'Added to clipboard for moving';

  @override
  String get save => 'Save';

  @override
  String get hide => 'Hide';

  @override
  String get share => 'Share';

  @override
  String get rename => 'Rename';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get copyWithNewName => 'Copy with new name';

  @override
  String get skip => 'Skip';

  @override
  String get passwordHint => 'Enter password';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get newFolderDefaultName => 'new folder';

  @override
  String get deleteSuccess => 'Delete completed successfully';

  @override
  String get copied => 'Copied';

  @override
  String get newFolderCreated => 'New folder created';

  @override
  String get newFileAdded => 'New file added';

  @override
  String get renameSuccess => 'Rename completed successfully';

  @override
  String get savedSuccess => 'Saved';

  @override
  String get hiddenSuccess => 'Hidden';

  @override
  String get pasteSuccess => 'Paste completed successfully';

  @override
  String get invalidName => 'Enter a valid name';

  @override
  String get itemAlreadyExists => 'An item with the same name already exists';

  @override
  String get insufficientStorageSpace => 'Not enough free space';

  @override
  String get operationDeleting => 'Deleting items...';

  @override
  String get operationCopying => 'Copying items...';

  @override
  String get operationMoving => 'Moving items...';

  @override
  String get nameConflictTitle => 'Name conflict';

  @override
  String nameConflictMessage(String name) {
    return '$name already exists. How would you like to continue?';
  }

  @override
  String get cleanupInProgress => 'Cleanup in progress...';

  @override
  String get operationCompleted => 'Operation completed';

  @override
  String get temporaryFilesCollected => 'Temporary files scanned';

  @override
  String get cacheFilesCollected => 'Cache files scanned';

  @override
  String cleanupWillFree(String size) {
    return '$size MB will be freed';
  }

  @override
  String get cleanupReady => 'Cleanup ready';

  @override
  String get cleanupNothingToClean => 'No files matched the cleanup rules';

  @override
  String get cleanupDeleting => 'Applying cleanup...';

  @override
  String cleanupScannedFiles(int count) {
    return 'Scanned files: $count';
  }

  @override
  String cleanupCandidatesFound(int count) {
    return 'Cleanup candidates: $count';
  }

  @override
  String cleanupRecoverableSpace(String size) {
    return 'Recoverable space: $size';
  }

  @override
  String get cleanupConfirmTitle => 'Start cleanup';

  @override
  String cleanupConfirmMessage(int count, String size) {
    return '$count files will be deleted and $size will be freed. Continue?';
  }

  @override
  String cleanupDeletedCount(int count) {
    return 'Deleted files: $count';
  }

  @override
  String cleanupFailedCount(int count) {
    return 'Failed files: $count';
  }

  @override
  String get cleanupCurrentFile => 'Current file';

  @override
  String get cleanupReportTitle => 'Cleanup report';

  @override
  String cleanupFreedSpace(String size) {
    return 'Freed space: $size';
  }

  @override
  String cleanupScanIssues(int count) {
    return 'Scan issues ($count)';
  }

  @override
  String cleanupDeleteIssues(int count) {
    return 'Delete issues ($count)';
  }

  @override
  String get clean => 'Clean';

  @override
  String categoryIndexPreparing(String category) {
    return 'Preparing $category files...';
  }

  @override
  String get navigationMenu => 'Menu';

  @override
  String get navigationRecent => 'Recent';

  @override
  String get navigationFolders => 'Folders';

  @override
  String get navigationSearch => 'Search';
}
