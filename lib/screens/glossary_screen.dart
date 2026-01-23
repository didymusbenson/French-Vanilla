import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../services/rules_data_service.dart';
import '../services/favorites_service.dart';
import '../models/glossary_term.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/aggregating_snackbar_mixin.dart';

class GlossaryScreen extends StatefulWidget {
  final String? highlightTerm;

  const GlossaryScreen({super.key, this.highlightTerm});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen>
    with RuleLinkMixin, AggregatingSnackBarMixin {
  final _dataService = RulesDataService();
  final _favoritesService = FavoritesService();
  final _searchController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  List<GlossaryTerm> _allTerms = [];
  List<GlossaryTerm> _filteredTerms = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, bool> _bookmarkStatus = {};

  @override
  void initState() {
    super.initState();
    _loadGlossary();
  }

  void _scrollToTerm(String termName) {
    final targetIndex = _filteredTerms.indexWhere(
      (term) => term.term.toLowerCase() == termName.toLowerCase()
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
    for (final term in _allTerms) {
      final isBookmarked = await _favoritesService.isBookmarked(term.term, BookmarkType.glossary);
      if (mounted) {
        setState(() {
          _bookmarkStatus[term.term] = isBookmarked;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGlossary() async {
    try {
      final terms = await _dataService.getGlossaryTerms();
      setState(() {
        _allTerms = terms;
        _filteredTerms = terms;
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

  void _filterTerms(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTerms = _allTerms;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredTerms = _allTerms.where((term) {
          return term.term.toLowerCase().contains(lowerQuery) ||
                 term.definition.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _toggleBookmark(String termName, String definition) async {
    await _favoritesService.toggleBookmark(termName, definition, BookmarkType.glossary);
    final isBookmarked = await _favoritesService.isBookmarked(termName, BookmarkType.glossary);
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

    Share.share(
      plainText,
      sharePositionOrigin: sharePositionOrigin,
    );
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
              hintText: 'Filter glossary terms...',
              prefixIcon: const Icon(Icons.filter_list),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterTerms('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _filterTerms,
          ),
        ),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );

    // Wrap in Scaffold when used standalone (with highlightTerm)
    if (widget.highlightTerm != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Glossary'),
        ),
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
        final term = _filteredTerms[index];
        final isBookmarked = _bookmarkStatus[term.term] ?? false;
        final isHighlighted = widget.highlightTerm != null &&
            term.term.toLowerCase() == widget.highlightTerm!.toLowerCase();

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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          term.term,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isHighlighted
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                          size: 20,
                        ),
                        color: isBookmarked
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        onPressed: () => _toggleBookmark(term.term, term.definition),
                        tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
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
