import 'dart:io';

import 'package:dosya_gezgini/data/models/file_access_result.dart';

class FileAccessService {
  Future<FileAccessResult> validateDirectory(
    String path, {
    bool requireWriteAccess = false,
  }) async {
    return _validatePath(
      path,
      expectsDirectory: true,
      requireWriteAccess: requireWriteAccess,
    );
  }

  Future<FileAccessResult> validateFile(
    String path, {
    bool requireWriteAccess = false,
  }) async {
    return _validatePath(
      path,
      expectsDirectory: false,
      requireWriteAccess: requireWriteAccess,
    );
  }

  Future<FileAccessResult> _validatePath(
    String rawPath, {
    required bool expectsDirectory,
    required bool requireWriteAccess,
  }) async {
    final path = rawPath.trim();
    if (path.isEmpty) {
      return FileAccessResult(
        path: rawPath,
        expectsDirectory: expectsDirectory,
        exists: false,
        isDirectory: false,
        isFile: false,
        isReadable: false,
        isWritable: false,
        isSymbolicLink: false,
        issueCode: FileAccessIssueCode.invalidPath,
      );
    }

    FileSystemEntityType entityType;
    try {
      entityType = await FileSystemEntity.type(path, followLinks: false);
    } catch (error) {
      return _resultForException(
        path: path,
        expectsDirectory: expectsDirectory,
        error: error,
      );
    }

    if (entityType == FileSystemEntityType.notFound) {
      return FileAccessResult(
        path: path,
        expectsDirectory: expectsDirectory,
        exists: false,
        isDirectory: false,
        isFile: false,
        isReadable: false,
        isWritable: false,
        isSymbolicLink: false,
        issueCode: FileAccessIssueCode.deleted,
      );
    }

    final isSymbolicLink = entityType == FileSystemEntityType.link;
    final isDirectory = entityType == FileSystemEntityType.directory;
    final isFile = entityType == FileSystemEntityType.file;
    final typeMatches = expectsDirectory ? isDirectory : isFile;

    if (isSymbolicLink) {
      return FileAccessResult(
        path: path,
        expectsDirectory: expectsDirectory,
        exists: true,
        isDirectory: false,
        isFile: false,
        isReadable: false,
        isWritable: false,
        isSymbolicLink: true,
        issueCode: FileAccessIssueCode.symbolicLinkUnsupported,
      );
    }

    if (!typeMatches) {
      return FileAccessResult(
        path: path,
        expectsDirectory: expectsDirectory,
        exists: true,
        isDirectory: isDirectory,
        isFile: isFile,
        isReadable: false,
        isWritable: false,
        isSymbolicLink: false,
        issueCode: FileAccessIssueCode.wrongType,
      );
    }

    final readableCheck = await _checkReadAccess(
      path,
      expectsDirectory: expectsDirectory,
    );
    if (readableCheck.error != null) {
      return _resultForException(
        path: path,
        expectsDirectory: expectsDirectory,
        error: readableCheck.error!,
        exists: true,
        isDirectory: isDirectory,
        isFile: isFile,
        isReadable: false,
        isWritable: false,
        isSymbolicLink: false,
      );
    }

    final writable = await _checkWriteAccess(
      path,
      expectsDirectory: expectsDirectory,
    );
    if (requireWriteAccess && !writable) {
      return FileAccessResult(
        path: path,
        expectsDirectory: expectsDirectory,
        exists: true,
        isDirectory: isDirectory,
        isFile: isFile,
        isReadable: true,
        isWritable: false,
        isSymbolicLink: false,
        issueCode: FileAccessIssueCode.readDenied,
      );
    }

    return FileAccessResult(
      path: path,
      expectsDirectory: expectsDirectory,
      exists: true,
      isDirectory: isDirectory,
      isFile: isFile,
      isReadable: true,
      isWritable: writable,
      isSymbolicLink: false,
    );
  }

  Future<_AccessAttempt> _checkReadAccess(
    String path, {
    required bool expectsDirectory,
  }) async {
    try {
      if (expectsDirectory) {
        await Directory(path).list(followLinks: false).isEmpty;
      } else {
        await File(path).length();
      }
      return const _AccessAttempt.success();
    } catch (error) {
      return _AccessAttempt.failure(error);
    }
  }

  Future<bool> _checkWriteAccess(
    String path, {
    required bool expectsDirectory,
  }) async {
    try {
      final stat =
          expectsDirectory
              ? await Directory(path).stat()
              : await File(path).stat();
      final modeString = stat.modeString();
      if (modeString.contains('w')) {
        return true;
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  FileAccessResult _resultForException({
    required String path,
    required bool expectsDirectory,
    required Object error,
    bool exists = false,
    bool isDirectory = false,
    bool isFile = false,
    bool isReadable = false,
    bool isWritable = false,
    bool isSymbolicLink = false,
  }) {
    final normalizedError = error.toString().toLowerCase();
    final issueCode = switch (true) {
      _ when normalizedError.contains('permission denied') =>
        FileAccessIssueCode.permissionDenied,
      _ when normalizedError.contains('access is denied') =>
        FileAccessIssueCode.permissionDenied,
      _ when normalizedError.contains('operation not permitted') =>
        FileAccessIssueCode.permissionDenied,
      _ when normalizedError.contains('cannot open file') =>
        FileAccessIssueCode.readDenied,
      _ when normalizedError.contains('no such file') =>
        FileAccessIssueCode.deleted,
      _ when normalizedError.contains('cannot find the path') =>
        FileAccessIssueCode.deleted,
      _ when normalizedError.contains('path not found') =>
        FileAccessIssueCode.deleted,
      _ => FileAccessIssueCode.invalidPath,
    };

    return FileAccessResult(
      path: path,
      expectsDirectory: expectsDirectory,
      exists: exists,
      isDirectory: isDirectory,
      isFile: isFile,
      isReadable: isReadable,
      isWritable: isWritable,
      isSymbolicLink: isSymbolicLink,
      issueCode: issueCode,
      details: error,
    );
  }
}

class _AccessAttempt {
  const _AccessAttempt.success() : error = null;
  const _AccessAttempt.failure(this.error);

  final Object? error;
}
