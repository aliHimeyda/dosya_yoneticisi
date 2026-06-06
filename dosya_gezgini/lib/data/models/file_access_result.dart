enum FileAccessIssueCode {
  invalidPath,
  deleted,
  wrongType,
  readDenied,
  permissionDenied,
  symbolicLinkUnsupported,
}

class FileAccessResult {
  const FileAccessResult({
    required this.path,
    required this.expectsDirectory,
    required this.exists,
    required this.isDirectory,
    required this.isFile,
    required this.isReadable,
    required this.isWritable,
    required this.isSymbolicLink,
    this.issueCode,
    this.details,
  });

  final String path;
  final bool expectsDirectory;
  final bool exists;
  final bool isDirectory;
  final bool isFile;
  final bool isReadable;
  final bool isWritable;
  final bool isSymbolicLink;
  final FileAccessIssueCode? issueCode;
  final Object? details;

  bool get isAccessible => issueCode == null;

  bool get shouldPruneCaches {
    switch (issueCode) {
      case FileAccessIssueCode.invalidPath:
      case FileAccessIssueCode.deleted:
      case FileAccessIssueCode.wrongType:
        return true;
      case FileAccessIssueCode.readDenied:
      case FileAccessIssueCode.permissionDenied:
      case FileAccessIssueCode.symbolicLinkUnsupported:
      case null:
        return false;
    }
  }

  String get debugCode => issueCode?.name ?? 'ok';
}
