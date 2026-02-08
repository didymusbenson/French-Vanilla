import 'package:flutter/material.dart';
import '../services/rules_data_service.dart';
import '../services/search_history_service.dart';
import '../services/card_data_service.dart';
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
  final _cardDataService = CardDataService();
  final _historyService = SearchHistoryService();
  List<SearchResult> _results = [];
  List<SearchResult> _filteredResults = [];
  List<SearchHistoryEntry> _recentSearches = [];
  bool _isLoading = false;
  String _query = '';
  Set<SearchResultType> _activeFilters = {}; // Empty = show all

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
        _filteredResults = [];
        _activeFilters.clear();
        _query = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _query = query;
    });

    try {
      // Run searches in parallel
      final searchFutures = await Future.wait([
        _dataService.search(query),
        _cardDataService.searchCardRulings(query),
      ]);

      final rulesResults = searchFutures[0] as List<SearchResult>;
      final cards = searchFutures[1] as List;

      // Convert cards to SearchResults with relevance scoring
      final lowerQuery = query.toLowerCase();
      final cardResults = cards.map((card) {
        // Calculate relevance score for card names
        int score = 0;
        final lowerCardName = card.name.toLowerCase();

        if (lowerCardName == lowerQuery) {
          score = 100; // Exact match
        } else {
          // Word boundary match
          final wordBoundaryRegex = RegExp(r'\b' + RegExp.escape(lowerQuery) + r'\b');
          if (wordBoundaryRegex.hasMatch(lowerCardName)) {
            score = 90;
          } else if (lowerCardName.startsWith(lowerQuery)) {
            score = 75; // Starts with
          } else if (lowerCardName.contains(lowerQuery)) {
            score = 50; // Contains
          }
        }

        return SearchResult(
          type: SearchResultType.card,
          title: card.name,
          snippet: card.type,
          card: card,
          relevanceScore: score,
        );
      }).toList();

      // Combine and sort all results by relevance
      final allResults = [...rulesResults, ...cardResults];
      allResults.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      // Save to history
      await _historyService.addSearch(query, allResults.length);
      await _loadRecentSearches();

      setState(() {
        _results = allResults;
        _filteredResults = _applyFilters(allResults);
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

  List<SearchResult> _applyFilters(List<SearchResult> results) {
    if (_activeFilters.isEmpty) {
      return results; // Show all if no filters active
    }
    return results.where((result) => _activeFilters.contains(result.type)).toList();
  }

  void _toggleFilter(SearchResultType type) {
    setState(() {
      if (_activeFilters.contains(type)) {
        _activeFilters.remove(type);
      } else {
        _activeFilters.add(type);
      }
      _filteredResults = _applyFilters(_results);
    });
  }

  int _getCountForType(SearchResultType type) {
    return _results.where((result) => result.type == type).length;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Get counts for each type
          final ruleCounts = _getCountForType(SearchResultType.rule);
          final glossaryCounts = _getCountForType(SearchResultType.glossary);
          final mtrCounts = _getCountForType(SearchResultType.mtr);
          final ipgCounts = _getCountForType(SearchResultType.ipg);
          final cardCounts = _getCountForType(SearchResultType.card);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Results',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_activeFilters.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _activeFilters.clear();
                            _filteredResults = _applyFilters(_results);
                          });
                          setModalState(() {});
                        },
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select sources to search',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                // All option
                CheckboxListTile(
                  title: Text(_results.isEmpty
                    ? 'All Sources'
                    : 'All Sources (${_results.length} results)'),
                  value: _activeFilters.isEmpty,
                  onChanged: (value) {
                    setState(() {
                      _activeFilters.clear();
                      _filteredResults = _applyFilters(_results);
                    });
                    setModalState(() {});
                  },
                ),
                const Divider(),
                // Individual filters - always show all options
                CheckboxListTile(
                  title: Text(_results.isEmpty ? 'Rules' : 'Rules ($ruleCounts)'),
                  secondary: const Icon(Icons.rule),
                  value: _activeFilters.contains(SearchResultType.rule),
                  onChanged: (value) {
                    _toggleFilter(SearchResultType.rule);
                    setModalState(() {});
                  },
                ),
                CheckboxListTile(
                  title: Text(_results.isEmpty ? 'Glossary' : 'Glossary ($glossaryCounts)'),
                  secondary: const Icon(Icons.list_alt),
                  value: _activeFilters.contains(SearchResultType.glossary),
                  onChanged: (value) {
                    _toggleFilter(SearchResultType.glossary);
                    setModalState(() {});
                  },
                ),
                CheckboxListTile(
                  title: Text(_results.isEmpty ? 'MTR' : 'MTR ($mtrCounts)'),
                  secondary: const Icon(Icons.gavel),
                  value: _activeFilters.contains(SearchResultType.mtr),
                  onChanged: (value) {
                    _toggleFilter(SearchResultType.mtr);
                    setModalState(() {});
                  },
                ),
                CheckboxListTile(
                  title: Text(_results.isEmpty ? 'IPG' : 'IPG ($ipgCounts)'),
                  secondary: const Icon(Icons.warning_amber),
                  value: _activeFilters.contains(SearchResultType.ipg),
                  onChanged: (value) {
                    _toggleFilter(SearchResultType.ipg);
                    setModalState(() {});
                  },
                ),
                CheckboxListTile(
                  title: Text(_results.isEmpty ? 'Cards' : 'Cards ($cardCounts)'),
                  secondary: Transform.rotate(
                    angle: 3.14159, // π radians = 180 degrees
                    child: const Icon(Icons.style),
                  ),
                  value: _activeFilters.contains(SearchResultType.card),
                  onChanged: (value) {
                    _toggleFilter(SearchResultType.card);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search',
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
                  _filteredResults = [];
                  _activeFilters.clear();
                  _query = '';
                });
              },
            ),
          // Filter button with badge (always visible)
          IconButton(
            icon: Badge(
              isLabelVisible: _activeFilters.isNotEmpty,
              label: Text(_activeFilters.length.toString()),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterBottomSheet,
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
                'Search rules, cards, and judge docs',
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

    // If filters are active but no results match
    if (_filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 64,
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results match the selected filters',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _activeFilters.clear();
                  _filteredResults = _applyFilters(_results);
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    // Show results
    return ListView.builder(
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final result = _filteredResults[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: result.type == SearchResultType.card
                ? Transform.rotate(
                    angle: 3.14159, // π radians = 180 degrees
                    child: Icon(
                      Icons.style,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Icon(
                    switch (result.type) {
                      SearchResultType.rule => Icons.rule,
                      SearchResultType.glossary => Icons.list_alt,
                      SearchResultType.mtr => Icons.gavel,
                      SearchResultType.ipg => Icons.warning_amber,
                      SearchResultType.card => Icons.style, // Shouldn't reach here
                    },
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
              } else if (result.type == SearchResultType.mtr && result.mtrRule != null) {
                _showMtrPreview(result);
              } else if (result.type == SearchResultType.ipg && result.ipgInfraction != null) {
                _showIpgPreview(result);
              } else if (result.type == SearchResultType.card && result.card != null) {
                _showCardPreview(result);
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

  void _showMtrPreview(SearchResult result) {
    showMtrBottomSheet(
      rule: result.mtrRule!,
      sectionNumber: result.mtrSectionNumber!,
      sectionTitle: result.mtrSectionTitle!,
    );
  }

  void _showIpgPreview(SearchResult result) {
    showIpgBottomSheet(
      infraction: result.ipgInfraction!,
    );
  }

  void _showCardPreview(SearchResult result) {
    showCardBottomSheet(
      card: result.card!,
    );
  }
}
