import 'package:flutter/material.dart';
import '../services/rules_data_service.dart';
import '../services/search_history_service.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/formatted_content_mixin.dart';
import '../mixins/preview_bottom_sheet_mixin.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with RuleLinkMixin, FormattedContentMixin, PreviewBottomSheetMixin {
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

    // If an initial query was provided, perform the search
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
      });
    }
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
                _showRulePreview(result);
              } else if (result.type == SearchResultType.glossary) {
                _showGlossaryPreview(result);
              }
            },
          ),
        );
      },
    );
  }

  void _showRulePreview(SearchResult result) {
    // Start preloading the rule data for faster navigation
    if (result.sectionNumber != null) {
      print('Preloading section ${result.sectionNumber} for faster navigation');
      _dataService.getRulesForSection(result.sectionNumber!);
    }

    // Handle top-level rule matches (no specific subrule)
    // Show the first subrule in the preview, but navigate to the whole rule
    final subruleGroup = result.subruleGroup ?? result.rule!.subruleGroups.first;

    // Use mixin method
    showRuleBottomSheet(
      rule: result.rule!,
      sectionNumber: result.sectionNumber!,
      subruleNumber: subruleGroup.number,
      content: subruleGroup.content,
      highlightSubruleNumber: result.subruleGroup?.number, // null for top-level matches
    );
  }

  void _showGlossaryPreview(SearchResult result) {
    // Use mixin method instead of dialog
    showGlossaryBottomSheet(
      term: result.glossaryTerm!.term,
      definition: result.glossaryTerm!.definition,
    );
  }
}
