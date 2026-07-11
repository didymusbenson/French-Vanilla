import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/content_update_service.dart';
import '../services/rules_data_service.dart';
import '../services/judge_docs_service.dart';
import '../services/card_data_service.dart';
import '../services/data_preloader.dart';

/// "Content Updates" — lets the user pull newer reference data (Comprehensive
/// Rules, MTR, IPG, card rulings) between app releases. Presents each data set
/// as a single named category, flags which have updates, confirms the user's
/// selection, then downloads with a progress bar.
class ContentUpdatesScreen extends StatefulWidget {
  const ContentUpdatesScreen({super.key});

  @override
  State<ContentUpdatesScreen> createState() => _ContentUpdatesScreenState();
}

class _ContentUpdatesScreenState extends State<ContentUpdatesScreen> {
  List<CategoryUpdate>? _updates;
  bool _checking = false;
  bool _downloading = false;
  String? _error;

  // Keys of categories the user has selected to download.
  final Set<String> _selected = {};

  // Active download progress.
  double _progress = 0;
  String _progressLabel = '';
  int _doneCount = 0;
  int _totalToDownload = 0;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checking = true;
      _error = null;
      _updates = null;
      _selected.clear();
    });
    try {
      final updates = await ContentUpdateService.instance.checkForUpdates();
      if (!mounted) return;
      setState(() {
        _updates = updates;
        // Pre-select everything that has an update available.
        _selected
          ..clear()
          ..addAll(updates.where((u) => u.available).map((u) => u.remote.key));
        _checking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _checking = false;
      });
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException &&
        (e.type == DioExceptionType.connectionError ||
            e.error.toString().contains('SocketException'))) {
      return 'No internet connection. Check your network and try again.';
    }
    return 'Could not check for updates. Please try again.';
  }

  Future<void> _downloadSelected() async {
    final updates = _updates;
    if (updates == null) return;
    final toDownload = updates
        .where((u) => u.available && _selected.contains(u.remote.key))
        .toList();
    if (toDownload.isEmpty) return;

    setState(() {
      _downloading = true;
      _doneCount = 0;
      _totalToDownload = toDownload.length;
      _progress = 0;
    });

    final failed = <String>[];
    for (final update in toDownload) {
      _cancelToken = CancelToken();
      setState(() {
        _progressLabel = update.remote.label;
        _progress = 0;
      });
      try {
        await ContentUpdateService.instance.downloadCategory(
          update.remote,
          cancelToken: _cancelToken,
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
        );
        _applyToLoadedData(update.remote.key);
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          break; // user cancelled — stop the queue
        }
        failed.add(update.remote.label);
      } catch (_) {
        failed.add(update.remote.label);
      }
      setState(() => _doneCount += 1);
    }

    if (!mounted) return;
    setState(() {
      _downloading = false;
      _cancelToken = null;
    });

    // Kick off a background re-preload so already-warmed singletons refill from
    // the new data without blocking the UI.
    DataPreloader().reload();

    final messenger = ScaffoldMessenger.of(context);
    if (failed.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Content updated. Changes apply as you browse.'),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(
            'Some updates failed: ${failed.join(', ')}. Other data is unchanged.'),
      ));
    }

    await _checkForUpdates(); // refresh versions / override state
  }

  /// Drop the in-memory cache for whichever service backs [category] so the
  /// next read picks up the freshly-installed override.
  void _applyToLoadedData(String category) {
    switch (category) {
      case 'rules':
        RulesDataService().reset();
        break;
      case 'mtr':
      case 'ipg':
        JudgeDocsService().clearCache();
        break;
      case 'rulings':
        CardDataService().reset();
        break;
    }
  }

  Future<void> _revert(CategoryUpdate update) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset ${update.remote.label}?'),
        content: const Text(
          'This removes the downloaded data and reverts to the version '
          'bundled with this app build.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ContentUpdateService.instance.revertCategory(update.remote.key);
    _applyToLoadedData(update.remote.key);
    DataPreloader().reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${update.remote.label} reset to built-in version.'),
    ));
    await _checkForUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Content Updates')),
      body: _downloading ? _buildDownloadingView() : _buildMainView(),
    );
  }

  Widget _buildDownloadingView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _totalToDownload > 1
                ? 'Downloading $_progressLabel  (${_doneCount + 1} of $_totalToDownload)'
                : 'Downloading $_progressLabel',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => _cancelToken?.cancel(),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    if (_checking) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildMessage(
        icon: Icons.cloud_off,
        text: _error!,
        action: FilledButton.icon(
          onPressed: _checkForUpdates,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      );
    }

    final updates = _updates ?? const [];
    final available = updates.where((u) => u.available).toList();
    final selectedCount =
        available.where((u) => _selected.contains(u.remote.key)).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                available.isEmpty
                    ? 'Everything is up to date.'
                    : '${available.length} update${available.length == 1 ? '' : 's'} available. '
                        'Choose what to download.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final update in updates) _buildCategoryTile(update),
            ],
          ),
        ),
        if (available.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      selectedCount == 0 ? null : _confirmAndDownload,
                  icon: const Icon(Icons.download),
                  label: Text(selectedCount == 0
                      ? 'Select updates to download'
                      : 'Download $selectedCount '
                          '(${_formatBytes(_selectedBytes(available))})'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  int _selectedBytes(List<CategoryUpdate> available) => available
      .where((u) => _selected.contains(u.remote.key))
      .fold(0, (sum, u) => sum + u.remote.size);

  Future<void> _confirmAndDownload() async {
    final bytes = _selectedBytes(
        (_updates ?? const []).where((u) => u.available).toList());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download updates?'),
        content: Text(
          'This will download ${_formatBytes(bytes)} of data over your current '
          'connection. Downloaded content replaces the built-in version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (confirmed == true) _downloadSelected();
  }

  Widget _buildCategoryTile(CategoryUpdate update) {
    final theme = Theme.of(context);
    final remote = update.remote;

    Widget trailing;
    if (update.available) {
      trailing = Checkbox(
        value: _selected.contains(remote.key),
        onChanged: (checked) => setState(() {
          if (checked == true) {
            _selected.add(remote.key);
          } else {
            _selected.remove(remote.key);
          }
        }),
      );
    } else {
      trailing = Icon(Icons.check_circle,
          color: theme.colorScheme.primary, size: 22);
    }

    final subtitleParts = <String>[];
    if (remote.updated != null) subtitleParts.add('Updated ${remote.updated}');
    if (update.available) {
      subtitleParts.add('${_formatBytes(remote.size)} download');
    } else {
      subtitleParts.add('Up to date');
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(remote.label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitleParts.join('  ·  ')),
            trailing: trailing,
          ),
          if (update.hasOverride)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: TextButton.icon(
                  onPressed: () => _revert(update),
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Reset to built-in'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(
      {required IconData icon, required String text, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}
