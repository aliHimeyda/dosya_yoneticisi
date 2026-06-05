import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/data/models/cleaning_models.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

class Temizliksayfasi extends StatefulWidget {
  const Temizliksayfasi({super.key});

  @override
  State<Temizliksayfasi> createState() => _TemizliksayfasiState();
}

class _TemizliksayfasiState extends State<Temizliksayfasi> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<Dosyaislemleri>();
      provider.startCleanupScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dosyaIslemleri = context.watch<Dosyaislemleri>();
    final scanProgress = dosyaIslemleri.cleanupScanProgress;
    final scanResult = dosyaIslemleri.cleanupScanResult;
    final deleteProgress = dosyaIslemleri.cleanupDeleteProgress;
    final deleteResult = dosyaIslemleri.cleanupDeleteResult;
    final scanIssues = dosyaIslemleri.cleanupIssues
        .where((issue) => issue.stage == CleaningIssueStage.scan)
        .toList(growable: false);
    final deleteIssues = dosyaIslemleri.cleanupIssues
        .where((issue) => issue.stage == CleaningIssueStage.delete)
        .toList(growable: false);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            dosyaIslemleri.isCleanupDeleting
                ? Icons.delete_sweep_rounded
                : dosyaIslemleri.isCleanupScanning
                ? Icons.cleaning_services_rounded
                : dosyaIslemleri.hasCleanupCandidates
                ? Icons.warning_amber_rounded
                : Icons.verified_rounded,
            size: 72,
            color:
                dosyaIslemleri.hasCleanupCandidates
                    ? Colors.orange.shade700
                    : theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            _resolveHeadline(l10n, dosyaIslemleri),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _resolveSummary(
              l10n: l10n,
              owner: dosyaIslemleri,
              scanProgress: scanProgress,
              scanResult: scanResult,
              deleteResult: deleteResult,
            ),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _InfoCard(
            title: l10n.cleanupInProgress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dosyaIslemleri.isCleanupScanning) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                if (dosyaIslemleri.isCleanupDeleting) ...[
                  LinearProgressIndicator(value: deleteProgress?.progress),
                  const SizedBox(height: 12),
                ],
                _buildMetricRow(
                  context,
                  l10n.cleanupScannedFiles(
                    scanProgress?.processedFiles ??
                        scanResult?.processedFiles ??
                        0,
                  ),
                ),
                _buildMetricRow(
                  context,
                  l10n.cleanupCandidatesFound(
                    scanResult?.candidates.length ??
                        scanProgress?.candidateCount ??
                        0,
                  ),
                ),
                _buildMetricRow(
                  context,
                  l10n.cleanupRecoverableSpace(
                    _formatBytes(
                      scanResult?.totalBytes ??
                          scanProgress?.reclaimableBytes ??
                          0,
                    ),
                  ),
                ),
                if (deleteProgress != null) ...[
                  const SizedBox(height: 8),
                  _buildMetricRow(
                    context,
                    l10n.cleanupDeletedCount(deleteProgress.deletedCount),
                  ),
                  _buildMetricRow(
                    context,
                    l10n.cleanupFailedCount(deleteProgress.failedCount),
                  ),
                ],
                if ((scanProgress?.currentPath ??
                        deleteProgress?.currentPath) !=
                    null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.cleanupCurrentFile,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path.basename(
                      scanProgress?.currentPath ??
                          deleteProgress?.currentPath ??
                          '',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: l10n.operationCompleted,
            child: Column(
              children: [
                _buildSourceRow(
                  context,
                  label: l10n.temporaryFilesCollected,
                  completed: dosyaIslemleri.gecicidosyalaralinmasi,
                  active:
                      dosyaIslemleri.isCleanupScanning &&
                      !(dosyaIslemleri.gecicidosyalaralinmasi),
                ),
                const SizedBox(height: 10),
                _buildSourceRow(
                  context,
                  label: l10n.cacheFilesCollected,
                  completed: dosyaIslemleri.onbellekdosyalarialinmasi,
                  active:
                      dosyaIslemleri.isCleanupScanning &&
                      dosyaIslemleri.gecicidosyalaralinmasi &&
                      !(dosyaIslemleri.onbellekdosyalarialinmasi),
                ),
              ],
            ),
          ),
          if (deleteResult != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: l10n.cleanupReportTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricRow(
                    context,
                    l10n.cleanupDeletedCount(deleteResult.deletedCount),
                  ),
                  _buildMetricRow(
                    context,
                    l10n.cleanupFailedCount(deleteResult.issues.length),
                  ),
                  _buildMetricRow(
                    context,
                    l10n.cleanupFreedSpace(
                      _formatBytes(deleteResult.deletedBytes),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (scanIssues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _IssueCard(
              title: l10n.cleanupScanIssues(scanIssues.length),
              issues: scanIssues,
            ),
          ],
          if (deleteIssues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _IssueCard(
              title: l10n.cleanupDeleteIssues(deleteIssues.length),
              issues: deleteIssues,
            ),
          ],
          if (dosyaIslemleri.cleanupError != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: l10n.errorOccurred,
              child: Text(dosyaIslemleri.cleanupError.toString()),
            ),
          ],
          const SizedBox(height: 20),
          if (!dosyaIslemleri.isCleanupScanning &&
              !dosyaIslemleri.isCleanupDeleting)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: dosyaIslemleri.startCleanupScan,
                    child: Text(l10n.tryAgain),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        dosyaIslemleri.hasCleanupCandidates
                            ? () => _confirmCleanup(context)
                            : () => Navigator.of(context).maybePop(),
                    child: Text(
                      dosyaIslemleri.hasCleanupCandidates
                          ? l10n.clean
                          : l10n.ok,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmCleanup(BuildContext context) async {
    final owner = context.read<Dosyaislemleri>();
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.cleanupConfirmTitle),
            content: Text(
              l10n.cleanupConfirmMessage(
                owner.cleanupCandidateCount,
                _formatBytes(owner.cleanupCandidateBytes),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.clean),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await owner.startCleanupDelete();
    }
  }

  String _resolveHeadline(AppLocalizations l10n, Dosyaislemleri owner) {
    if (owner.isCleanupDeleting) {
      return l10n.cleanupDeleting;
    }
    if (owner.isCleanupScanning) {
      return l10n.cleanupInProgress;
    }
    if (owner.cleanupError != null) {
      return l10n.errorOccurred;
    }
    if (owner.cleanupDeleteResult != null) {
      return l10n.cleanupReportTitle;
    }
    if (owner.hasCleanupCandidates) {
      return l10n.cleanupReady;
    }
    return l10n.cleanupNothingToClean;
  }

  String _resolveSummary({
    required AppLocalizations l10n,
    required Dosyaislemleri owner,
    required CleaningScanProgress? scanProgress,
    required CleaningScanResult? scanResult,
    required CleaningDeleteResult? deleteResult,
  }) {
    if (owner.isCleanupDeleting) {
      return l10n.cleanupConfirmMessage(
        owner.cleanupCandidateCount,
        _formatBytes(owner.cleanupCandidateBytes),
      );
    }
    if (deleteResult != null) {
      return l10n.cleanupFreedSpace(_formatBytes(deleteResult.deletedBytes));
    }
    if (scanResult != null && scanResult.hasCandidates) {
      return l10n.cleanupRecoverableSpace(_formatBytes(scanResult.totalBytes));
    }
    return l10n.cleanupScannedFiles(
      scanProgress?.processedFiles ?? scanResult?.processedFiles ?? 0,
    );
  }

  Widget _buildSourceRow(
    BuildContext context, {
    required String label,
    required bool completed,
    required bool active,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        if (completed)
          const Icon(Icons.check_circle_rounded, color: Colors.green)
        else if (active)
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text('....', style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildMetricRow(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    final fractionDigits = unitIndex == 0 ? 0 : 2;
    return '${size.toStringAsFixed(fractionDigits)} ${units[unitIndex]}';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.title, required this.issues});

  final String title;
  final List<CleaningIssue> issues;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: issues
            .map(
              (issue) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path.basename(issue.path),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(issue.path),
                    const SizedBox(height: 4),
                    Text(issue.message),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
