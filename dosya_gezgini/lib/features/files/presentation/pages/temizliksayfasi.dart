import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/data/models/cleaning_models.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/temizliksayfasi_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Temizliksayfasi extends StatelessWidget {
  const Temizliksayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TemizliksayfasiProvider>(
      create:
          (context) =>
              TemizliksayfasiProvider(owner: context.read<Dosyaislemleri>()),
      child: const _TemizliksayfasiBody(),
    );
  }
}

class _TemizliksayfasiBody extends StatelessWidget {
  const _TemizliksayfasiBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.watch<TemizliksayfasiProvider>();
    final scanProgress = provider.scanProgress;
    final scanResult = provider.scanResult;
    final deleteProgress = provider.deleteProgress;
    final deleteResult = provider.deleteResult;
    final scanIssues = provider.scanIssues;
    final deleteIssues = provider.deleteIssues;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            provider.statusIcon,
            size: 72,
            color: provider.resolveIconColor(theme),
          ),
          const SizedBox(height: 16),
          Text(
            provider.resolveHeadline(l10n),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            provider.resolveSummary(l10n),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _InfoCard(
            title: l10n.cleanupInProgress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.isCleanupScanning) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                if (provider.isCleanupDeleting) ...[
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
                    provider.formatBytes(
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
                if (provider.currentPathBasename != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.cleanupCurrentFile,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.currentPathBasename!,
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
                  completed: provider.geciciDosyalarTamamlandi,
                  active:
                      provider.isCleanupScanning &&
                      !provider.geciciDosyalarTamamlandi,
                ),
                const SizedBox(height: 10),
                _buildSourceRow(
                  context,
                  label: l10n.cacheFilesCollected,
                  completed: provider.onbellekDosyalariTamamlandi,
                  active:
                      provider.isCleanupScanning &&
                      provider.geciciDosyalarTamamlandi &&
                      !provider.onbellekDosyalariTamamlandi,
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
                      provider.formatBytes(deleteResult.deletedBytes),
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
          if (provider.cleanupError != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: l10n.errorOccurred,
              child: Text(provider.cleanupError.toString()),
            ),
          ],
          const SizedBox(height: 20),
          if (provider.isIdle)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: provider.retryScan,
                    child: Text(l10n.tryAgain),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        provider.hasCleanupCandidates
                            ? () => provider.confirmCleanup(context)
                            : () => Navigator.of(context).maybePop(),
                    child: Text(
                      provider.hasCleanupCandidates ? l10n.clean : l10n.ok,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
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
                      providerPathBasename(issue.path),
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

  String providerPathBasename(String value) {
    final segments = value.split(RegExp(r'[\\/]'));
    return segments.isEmpty ? value : segments.last;
  }
}
