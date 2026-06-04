import 'package:path/path.dart' as pathinfo;

enum ClipboardOperation { copy, cut }

enum FileOperationType { copy, move, delete, rename, createFolder }

enum FileConflictResolution { overwrite, createUniqueName, skip, cancel }

class FileOperationErrorCodes {
  FileOperationErrorCodes._();

  static const String alreadyExists = 'already_exists';
  static const String conflict = 'conflict';
  static const String destinationInSource = 'destination_in_source';
  static const String insufficientSpace = 'insufficient_space';
  static const String invalidName = 'invalid_name';
  static const String parentNotFound = 'parent_not_found';
  static const String sameDestination = 'same_destination';
  static const String sourceNotFound = 'source_not_found';
}

class FileOperationEntry {
  const FileOperationEntry({required this.path, required this.isDirectory});

  final String path;
  final bool isDirectory;

  String get name => pathinfo.basename(path);
}

class FileConflictRequest {
  const FileConflictRequest({
    required this.source,
    required this.destinationPath,
    required this.operationType,
  });

  final FileOperationEntry source;
  final String destinationPath;
  final FileOperationType operationType;

  String get destinationName => pathinfo.basename(destinationPath);
}

class FileOperationProgress {
  const FileOperationProgress({
    required this.operationType,
    required this.processedItems,
    required this.totalItems,
    this.currentPath,
  });

  final FileOperationType operationType;
  final int processedItems;
  final int totalItems;
  final String? currentPath;

  double? get progress {
    if (totalItems <= 0) {
      return null;
    }

    return processedItems / totalItems;
  }
}

class FileOperationFailure {
  const FileOperationFailure({
    required this.path,
    required this.errorCode,
    this.details,
  });

  final String path;
  final String errorCode;
  final Object? details;
}

class FileOperationResult {
  const FileOperationResult({
    this.createdPaths = const <String>[],
    this.removedPaths = const <String>[],
    this.skippedPaths = const <String>[],
    this.failures = const <FileOperationFailure>[],
    this.impactedDirectoryPaths = const <String>{},
    this.cancelled = false,
  });

  final List<String> createdPaths;
  final List<String> removedPaths;
  final List<String> skippedPaths;
  final List<FileOperationFailure> failures;
  final Set<String> impactedDirectoryPaths;
  final bool cancelled;

  bool get hasChanges => createdPaths.isNotEmpty || removedPaths.isNotEmpty;
  bool get hasIssues => skippedPaths.isNotEmpty || failures.isNotEmpty;
}

class FileCreateResult {
  const FileCreateResult({
    this.createdPath,
    this.errorCode,
    this.impactedDirectoryPaths = const <String>{},
  });

  final String? createdPath;
  final String? errorCode;
  final Set<String> impactedDirectoryPaths;

  bool get isSuccess => createdPath != null && errorCode == null;
}

class FileRenameResult {
  const FileRenameResult({
    required this.oldPath,
    this.newPath,
    required this.isDirectory,
    this.errorCode,
    this.impactedDirectoryPaths = const <String>{},
  });

  final String oldPath;
  final String? newPath;
  final bool isDirectory;
  final String? errorCode;
  final Set<String> impactedDirectoryPaths;

  bool get isSuccess => newPath != null && errorCode == null;
}
