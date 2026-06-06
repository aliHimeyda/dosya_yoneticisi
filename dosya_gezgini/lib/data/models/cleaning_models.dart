enum CleaningSourceType {
  temporary,
  cache,
  unusedFiles,
  packages,
  residualFiles,
  memory,
}

enum CleaningCandidateReason {
  stale,
  large,
  staleAndLarge,
  packageInstaller,
  residualJunk,
}

enum CleaningIssueStage { scan, delete }

class CleaningCandidate {
  const CleaningCandidate({
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.source,
    required this.reason,
  });

  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;
  final CleaningSourceType source;
  final CleaningCandidateReason reason;
}

class CleaningIssue {
  const CleaningIssue({
    required this.path,
    required this.stage,
    required this.message,
  });

  final String path;
  final CleaningIssueStage stage;
  final String message;
}

class CleaningScanProgress {
  const CleaningScanProgress({
    required this.source,
    required this.processedFiles,
    required this.candidateCount,
    required this.reclaimableBytes,
    required this.completedSourceCount,
    this.currentPath,
  });

  final CleaningSourceType source;
  final int processedFiles;
  final int candidateCount;
  final int reclaimableBytes;
  final int completedSourceCount;
  final String? currentPath;
}

class CleaningSourceSummary {
  const CleaningSourceSummary({
    required this.source,
    required this.detectedItemCount,
    required this.detectedBytes,
    required this.isCleanable,
  });

  final CleaningSourceType source;
  final int detectedItemCount;
  final int detectedBytes;
  final bool isCleanable;
}

class CleaningScanResult {
  const CleaningScanResult({
    required this.candidates,
    required this.totalBytes,
    required this.processedFiles,
    required this.issues,
    required this.sourceSummaries,
  });

  final List<CleaningCandidate> candidates;
  final int totalBytes;
  final int processedFiles;
  final List<CleaningIssue> issues;
  final List<CleaningSourceSummary> sourceSummaries;

  bool get hasCandidates => candidates.isNotEmpty;

  CleaningSourceSummary? summaryFor(CleaningSourceType source) {
    for (final summary in sourceSummaries) {
      if (summary.source == source) {
        return summary;
      }
    }
    return null;
  }
}

class CleaningDeleteProgress {
  const CleaningDeleteProgress({
    required this.processedItems,
    required this.totalItems,
    required this.deletedCount,
    required this.failedCount,
    required this.deletedBytes,
    this.currentPath,
  });

  final int processedItems;
  final int totalItems;
  final int deletedCount;
  final int failedCount;
  final int deletedBytes;
  final String? currentPath;

  double? get progress {
    if (totalItems <= 0) {
      return null;
    }

    return processedItems / totalItems;
  }
}

class CleaningDeleteResult {
  const CleaningDeleteResult({
    required this.deletedPaths,
    required this.deletedBytes,
    required this.issues,
  });

  final List<String> deletedPaths;
  final int deletedBytes;
  final List<CleaningIssue> issues;

  int get deletedCount => deletedPaths.length;
  bool get hasIssues => issues.isNotEmpty;
}

class CleaningCancelledException implements Exception {
  const CleaningCancelledException();
}
