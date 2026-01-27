import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../services/rules_data_service.dart';
import '../services/favorites_service.dart';
import '../models/glossary_term.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/aggregating_snackbar_mixin.dart';

/// Displays glossary terms in a format similar to rule subrules.
/// Each term is shown as a card with the term name as header and definition as content.
class GlossaryDetailScreen extends StatefulWidget {
  final String? highlightTerm;

  const GlossaryDetailScreen({super.key, this.highlightTerm});

  @override
  State<GlossaryDetailScreen> createState() => _GlossaryDetailScreenState();
}

class _GlossaryDetailScreenState extends State<GlossaryDetailScreen>
    with RuleLinkMixin, AggregatingSnackBarMixin {
  final _dataService = RulesDataService();
  final _favoritesService = FavoritesService();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  List<GlossaryTerm> _terms = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, bool> _bookmarkStatus = {};
  final Map<String, GlobalKey> _termKeys = {};

  @override
  void initState() {
    super.initState();
    _loadGlossary();
  }

  Future<void> _loadGlossary() async {
    try {
      final terms = await _dataService.getGlossaryTerms();
      setState(() {
        _terms = terms;
        _isLoading = false;
      });

      // Create keys for each term
      for (final term in terms) {
        _termKeys[term.term] = GlobalKey();
      }

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

  void _scrollToTerm(String termName) {
    final targetIndex = _terms.indexWhere(
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
    for (final term in _terms) {
      final isBookmarked = await _favoritesService.isBookmarked(term.term, BookmarkType.glossary);
      if (mounted) {
        setState(() {
          _bookmarkStatus[term.term] = isBookmarked;
        });
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glossary'),
      ),
      body: _buildBody(),
    );
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

    if (_terms.isEmpty) {
      return const Center(child: Text('No glossary terms found.'));
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _terms.length,
      itemBuilder: (context, index) {
        final term = _terms[index];
        final isBookmarked = _bookmarkStatus[term.term] ?? false;
        final isHighlighted = widget.highlightTerm != null &&
            term.term.toLowerCase() == widget.highlightTerm!.toLowerCase();

        return GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showContextMenu(term.term, term.definition);
          },
          child: Card(
            key: _termKeys[term.term],
            clipBehavior: Clip.antiAlias,
            elevation: isHighlighted ? 8 : 1,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: isHighlighted
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with term name and bookmark icon (similar to subrule header)
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
                      ),
                    ],
                  ),
                ),
                // Definition content (similar to subrule content)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RichText(
                    text: TextSpan(
                      children: parseTextWithLinks(
                        term.definition,
                        TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: isHighlighted
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
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
