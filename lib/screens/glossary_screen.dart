import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../services/rules_data_service.dart';
import '../services/favorites_service.dart';
import '../models/glossary_term.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/aggregating_snackbar_mixin.dart';
import '../widgets/glossary_filter_sheet.dart';

class GlossaryScreen extends StatefulWidget {
  final String? highlightTerm;

  const GlossaryScreen({super.key, this.highlightTerm});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryItemViewModel {
  final GlossaryTerm term;
  final List<RuleLinkMatch> links;

  const _GlossaryItemViewModel({required this.term, required this.links});
}

class _GlossaryScreenState extends State<GlossaryScreen>
    with RuleLinkMixin, AggregatingSnackBarMixin {
  final _dataService = RulesDataService();
  final _favoritesService = FavoritesService();
  final _searchController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  List<_GlossaryItemViewModel> _allTerms = [];
  List<_GlossaryItemViewModel> _filteredTerms = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, bool> _bookmarkStatus = {};
  Set<GlossaryTermType> _selectedFilters = {};
  late Map<GlossaryTermType, int> _termCounts;
  Timer? _debounce;
  String _searchQuery = '';
  String? _highlightTermLowerCase;

  @override
  void initState() {
    super.initState();
    if (widget.highlightTerm != null) {
      _highlightTermLowerCase = widget.highlightTerm!.toLowerCase();
    }
    _loadGlossary();
  }

  void _scrollToTerm(String termName) {
    if (_highlightTermLowerCase == null) return;

    final targetIndex = _filteredTerms.indexWhere(
      (vm) => vm.term.term.toLowerCase() == _highlightTermLowerCase,
    );

    if (targetIndex != -1) {
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.01,
      );
    }
  }

  Future<void> _loadBookmarkStatuses() async {
    for (final vm in _allTerms) {
      final isBookmarked = await _favoritesService.isBookmarked(
        vm.term.term,
        BookmarkType.glossary,
      );
      if (mounted) {
        setState(() {
          _bookmarkStatus[vm.term.term] = isBookmarked;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGlossary() async {
    try {
      final terms = await _dataService.getGlossaryTerms();

      // Calculate term counts by type
      final counts = <GlossaryTermType, int>{};
      for (final type in GlossaryTermType.values) {
        counts[type] = terms.where((t) => t.type == type).length;
      }

      // Convert to view models with pre-calculated links
      final viewModels = terms
          .map(
            (term) => _GlossaryItemViewModel(
              term: term,
              links: findRuleLinks(term.definition),
            ),
          )
          .toList();

      setState(() {
        _allTerms = viewModels;
        _filteredTerms = viewModels;
        _termCounts = counts;
        _isLoading = false;
      });
      await _loadBookmarkStatuses();

      // Scroll to highlighted term if provided
      if (widget.highlightTerm != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToTerm(widget.highlightTerm!);
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load glossary: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
      _filterTerms(query);
    });
  }

  void _filterTerms(String query) {
    setState(() {
      final lowerQuery = query.toLowerCase();

      final matches = _allTerms.where((vm) {
        // Apply text search filter
        final matchesSearch =
            query.isEmpty ||
            vm.term.term.toLowerCase().contains(lowerQuery) ||
            vm.term.definition.toLowerCase().contains(lowerQuery);

        // Apply category filter
        final matchesCategory =
            _selectedFilters.isEmpty || _selectedFilters.contains(vm.term.type);

        return matchesSearch && matchesCategory;
      }).toList();

      // Sort results by relevance if there is a query
      if (lowerQuery.isNotEmpty) {
        matches.sort((a, b) {
          final aTerm = a.term.term.toLowerCase();
          final bTerm = b.term.term.toLowerCase();

          // 1. Exact match
          if (aTerm == lowerQuery && bTerm != lowerQuery) return -1;
          if (bTerm == lowerQuery && aTerm != lowerQuery) return 1;

          // 2. Starts with
          final aStarts = aTerm.startsWith(lowerQuery);
          final bStarts = bTerm.startsWith(lowerQuery);
          if (aStarts && !bStarts) return -1;
          if (bStarts && !aStarts) return 1;

          // 3. Name match vs Definition match
          final aNameMatch = aTerm.contains(lowerQuery);
          final bNameMatch = bTerm.contains(lowerQuery);
          if (aNameMatch && !bNameMatch) return -1;
          if (bNameMatch && !aNameMatch) return 1;

          // 4. Alphabetical fallback
          return aTerm.compareTo(bTerm);
        });
      } else {
        // Default alphabetical sort when no query
        matches.sort((a, b) => a.term.term.compareTo(b.term.term));
      }

      _filteredTerms = matches;
    });
  }

  Future<void> _showFilterSheet() async {
    await showGlossaryFilterSheet(
      context: context,
      currentFilters: _selectedFilters,
      termCounts: _termCounts,
      onFiltersChanged: (newFilters) {
        setState(() {
          _selectedFilters = newFilters;
        });
        _filterTerms(_searchController.text);
      },
    );
  }

  Future<void> _toggleBookmark(String termName, String definition) async {
    await _favoritesService.toggleBookmark(
      termName,
      definition,
      BookmarkType.glossary,
    );
    final isBookmarked = await _favoritesService.isBookmarked(
      termName,
      BookmarkType.glossary,
    );
    setState(() {
      _bookmarkStatus[termName] = isBookmarked;
    });

    if (mounted) {
      showAggregatingSnackBar(
        isBookmarked ? 'Bookmark added' : 'Bookmark removed',
      );
    }
  }

  void _copyTermContent(String termName, String definition) {
    final plainText = '$termName\n\n$definition';
    Clipboard.setData(ClipboardData(text: plainText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Term copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _shareTermContent(String termName, String definition) {
    final plainText = '$termName\n\n$definition';

    // Get the render box for positioning on iPad
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    Share.share(plainText, sharePositionOrigin: sharePositionOrigin);
  }

  void _showContextMenu(String termName, String definition) {
    final isBookmarked = _bookmarkStatus[termName] ?? false;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(isBookmarked ? 'Remove Bookmark' : 'Add Bookmark'),
              onTap: () {
                Navigator.pop(context);
                _toggleBookmark(termName, definition);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.copy,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Copy Term'),
              onTap: () {
                Navigator.pop(context);
                _copyTermContent(termName, definition);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Share Term'),
              onTap: () {
                Navigator.pop(context);
                _shareTermContent(termName, definition);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search glossary terms...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter button with badge
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          _selectedFilters.isEmpty
                              ? Icons.filter_alt_outlined
                              : Icons.filter_alt,
                        ),
                        onPressed: _showFilterSheet,
                        tooltip: 'Filter by category',
                      ),
                      if (_selectedFilters.isNotEmpty)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${_selectedFilters.length}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Clear button
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      tooltip: 'Clear search',
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );

    // Wrap in Scaffold when used standalone (with highlightTerm)
    if (widget.highlightTerm != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Glossary')),
        body: content,
      );
    }

    return content;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadGlossary();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredTerms.isEmpty) {
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
              'No terms found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      itemCount: _filteredTerms.length,
      itemBuilder: (context, index) {
        final vm = _filteredTerms[index];
        final term = vm.term;
        final isBookmarked = _bookmarkStatus[term.term] ?? false;
        final isHighlighted =
            _highlightTermLowerCase != null &&
            term.term.toLowerCase() == _highlightTermLowerCase;

        return GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showContextMenu(term.term, term.definition);
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: isHighlighted ? 8 : 2,
            color: isHighlighted
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with term name and bookmark icon
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            // Try to find the first rule reference to link to
                            // We can use the first pre-calculated link if available
                            final hasLink = vm.links.isNotEmpty;

                            // Helper to build text with potential highlights
                            Widget buildText(String text, TextStyle? style) {
                              if (_searchQuery.isEmpty) {
                                return Text(text, style: style);
                              }

                              // Highlight search matches in the term title
                              final spans = <TextSpan>[];
                              final lowerText = text.toLowerCase();
                              final lowerQuery = _searchQuery.toLowerCase();
                              int lastIndex = 0;
                              int index = lowerText.indexOf(lowerQuery);

                              while (index != -1) {
                                if (index > lastIndex) {
                                  spans.add(
                                    TextSpan(
                                      text: text.substring(lastIndex, index),
                                    ),
                                  );
                                }
                                spans.add(
                                  TextSpan(
                                    text: text.substring(
                                      index,
                                      index + lowerQuery.length,
                                    ),
                                    style: style?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                );
                                lastIndex = index + lowerQuery.length;
                                index = lowerText.indexOf(
                                  lowerQuery,
                                  lastIndex,
                                );
                              }

                              if (lastIndex < text.length) {
                                spans.add(
                                  TextSpan(text: text.substring(lastIndex)),
                                );
                              }

                              return RichText(
                                text: TextSpan(children: spans, style: style),
                              );
                            }

                            final style = Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isHighlighted
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.primary,
                                );

                            Widget textWidget = buildText(term.term, style);

                            if (hasLink) {
                              // Use the first link found in the definition as the title link target
                              // (Heuristic: usually the first link is the "main" rule)
                              final ruleNumber = vm.links.first.ruleNumber;

                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => navigateToRule(ruleNumber),
                                  child: textWidget,
                                ),
                              );
                            }

                            return textWidget;
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          size: 20,
                        ),
                        color: isBookmarked
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        onPressed: () =>
                            _toggleBookmark(term.term, term.definition),
                        tooltip: isBookmarked
                            ? 'Remove bookmark'
                            : 'Add bookmark',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RichText(
                    text: TextSpan(
                      children: parseTextWithLinks(
                        term.definition,
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: isHighlighted
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                        ),
                        searchQuery: _searchQuery,
                        preCalculatedLinks: vm.links,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
