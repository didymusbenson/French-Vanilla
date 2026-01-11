import 'package:flutter/material.dart';
import '../services/rules_data_service.dart';
import '../services/search_history_service.dart';
import 'rule_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _dataService = RulesDataService();
  final _historyService = SearchHistoryService();
  List<SearchResult> _results = [];
  List<SearchHistoryEntry> _recentSearches = [];
  bool _isLoading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final history = await _historyService.getHistory();
    setState(() {
      _recentSearches = history;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Search History'),
        content: const Text('Are you sure you want to clear all recent searches?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
      await _loadRecentSearches();
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _query = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _query = query;
    });

    try {
      final results = await _dataService.search(query);

      // Save to history
      await _historyService.addSearch(query, results.length);
      await _loadRecentSearches();

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search rules...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 18),
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _results = [];
                  _query = '';
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_query.isEmpty) {
      if (_recentSearches.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Search the comprehensive rules',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }

      // Show recent searches
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._recentSearches.map((entry) {
            return ListTile(
              leading: Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(entry.query),
              subtitle: Text('${entry.resultCount} result${entry.resultCount == 1 ? '' : 's'}'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                _searchController.text = entry.query;
                _performSearch(entry.query);
              },
            );
          }),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear Search History'),
            ),
          ),
        ],
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_query"',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(
              result.type == SearchResultType.rule
                  ? Icons.rule
                  : Icons.list_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              result.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              result.snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (result.type == SearchResultType.rule && result.rule != null) {
                _showRuleBottomSheet(result);
              } else if (result.type == SearchResultType.glossary) {
                _showGlossaryTermDialog(result);
              }
            },
          ),
        );
      },
    );
  }

  /// Builds formatted subrule content with spacing between subsections
  Widget _buildFormattedContent(String content) {
    final lines = content.split('\n');
    final subsections = <String>[];
    // Matches "100.1." or "100.1a" (note: letter variants have NO dot after them)
    final subsectionPattern = RegExp(r'^\d{3}\.\d+([a-z]|\.)\s');

    var currentSubsection = StringBuffer();

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Check if this is the start of a new subsection
      if (subsectionPattern.hasMatch(trimmedLine)) {
        // Save the previous subsection if it exists
        if (currentSubsection.isNotEmpty) {
          subsections.add(currentSubsection.toString().trim());
          currentSubsection = StringBuffer();
        }
        currentSubsection.writeln(line);
      } else if (trimmedLine.isNotEmpty) {
        currentSubsection.writeln(line);
      }
    }

    // Don't forget the last subsection
    if (currentSubsection.isNotEmpty) {
      subsections.add(currentSubsection.toString().trim());
    }

    // Build the widget with spacing between subsections
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < subsections.length; i++) ...[
          SelectableText(
            subsections[i],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
          if (i < subsections.length - 1)
            Center(
              child: Text(
                '—',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ],
    );
  }

  void _showRuleBottomSheet(SearchResult result) {
    // Start preloading the rule data for faster navigation
    if (result.sectionNumber != null) {
      print('Preloading section ${result.sectionNumber} for faster navigation');
      _dataService.getRulesForSection(result.sectionNumber!);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                result.subruleGroup != null
                    ? '${result.rule!.number}. ${result.rule!.title}'
                    : result.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (result.subruleGroup != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Subrule ${result.subruleGroup!.number}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Content - scrollable if needed
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: result.subruleGroup != null
                        ? _buildFormattedContent(result.subruleGroup!.content)
                        : SelectableText(
                            result.snippet,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RuleDetailScreen(
                          rule: result.rule!,
                          sectionNumber: result.sectionNumber!,
                          highlightSubruleNumber: result.subruleGroup?.number,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Go to Rule ${result.rule!.number}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGlossaryTermDialog(SearchResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.glossaryTerm!.term),
        content: SingleChildScrollView(
          child: SelectableText(result.glossaryTerm!.definition),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
