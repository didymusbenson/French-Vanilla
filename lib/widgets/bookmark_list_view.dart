import 'dart:math';
import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/rules_data_service.dart';
import '../services/card_data_service.dart';
import '../services/judge_docs_service.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/formatted_content_mixin.dart';
import '../mixins/preview_bottom_sheet_mixin.dart';
import '../screens/card_detail_screen.dart';

/// Widget that displays a list of bookmarks with edit/delete functionality
/// Can show all bookmarks or filter by a specific list ID
class BookmarkListView extends StatefulWidget {
  final String? listId; // null = show all bookmarks
  final String title; // Display title for app bar

  const BookmarkListView({
    super.key,
    this.listId,
    required this.title,
  });

  @override
  State<BookmarkListView> createState() => _BookmarkListViewState();
}

class _BookmarkListViewState extends State<BookmarkListView>
    with RuleLinkMixin, FormattedContentMixin, PreviewBottomSheetMixin {
  final _favoritesService = FavoritesService();
  final _dataService = RulesDataService();
  final _cardService = CardDataService();
  final _judgeDocsService = JudgeDocsService();
  List<BookmarkedItem> _bookmarks = [];
  List<BookmarkList> _allLists = []; // For showing list badges in "All" view
  bool _isLoading = true;
  bool _isEditMode = false;
  final Set<String> _selectedBookmarks = {}; // Stores identifiers

  void toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedBookmarks.clear();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final bookmarks = widget.listId == null
        ? await _favoritesService.getBookmarks()
        : await _favoritesService.getBookmarksInList(widget.listId!);

    // Load all lists if showing "All" view (for list badges)
    List<BookmarkList> lists = [];
    if (widget.listId == null) {
      lists = await _favoritesService.getAllLists();
    }

    setState(() {
      _bookmarks = bookmarks;
      _allLists = lists;
      _isLoading = false;
    });
  }

  Future<void> _removeBookmark(BookmarkedItem item) async {
    if (widget.listId != null) {
      // In a specific list view: remove from this list only
      await _favoritesService.removeBookmarkFromList(
          item.identifier, item.type, widget.listId!);
    } else {
      // In "All" view: delete bookmark entirely
      await _favoritesService.removeBookmark(item.identifier, item.type);
    }
    await _loadBookmarks();
  }

  Future<void> _deleteSelectedBookmarks() async {
    if (_selectedBookmarks.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmarks'),
        content: Text(
            'Are you sure you want to delete ${_selectedBookmarks.length} bookmark${_selectedBookmarks.length == 1 ? '' : 's'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final identifier in _selectedBookmarks) {
        final item = _bookmarks.firstWhere((b) => b.identifier == identifier);
        if (widget.listId != null) {
          // Remove from this list only
          await _favoritesService.removeBookmarkFromList(
              identifier, item.type, widget.listId!);
        } else {
          // Delete entirely
          await _favoritesService.removeBookmark(identifier, item.type);
        }
      }
      setState(() {
        _selectedBookmarks.clear();
        _isEditMode = false;
      });
      await _loadBookmarks();
    }
  }

  void _toggleSelection(String identifier) {
    setState(() {
      if (_selectedBookmarks.contains(identifier)) {
        _selectedBookmarks.remove(identifier);
      } else {
        _selectedBookmarks.add(identifier);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedBookmarks.clear();
      _selectedBookmarks.addAll(_bookmarks.map((b) => b.identifier));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedBookmarks.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_bookmarks.isNotEmpty)
            IconButton(
              icon: Icon(_isEditMode ? Icons.close : Icons.edit),
              onPressed: toggleEditMode,
              tooltip: _isEditMode ? 'Cancel' : 'Edit',
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

    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color:
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              widget.listId == null ? 'No bookmarks yet' : 'No bookmarks in this list',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                widget.listId == null
                    ? 'Save a rule by tapping the bookmark icon on any subrule card, or use the long-press menu'
                    : 'Add bookmarks to this list using the "Add to list" button after bookmarking',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_isEditMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Text(
                  '${_selectedBookmarks.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedBookmarks.length == _bookmarks.length
                      ? _deselectAll
                      : _selectAll,
                  child: Text(
                    _selectedBookmarks.length == _bookmarks.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = _bookmarks[index];
              final isSelected =
                  _selectedBookmarks.contains(bookmark.identifier);

              // Display title differently based on type
              String displayTitle;
              switch (bookmark.type) {
                case BookmarkType.rule:
                  displayTitle = 'Rule ${bookmark.identifier}';
                  break;
                case BookmarkType.mtr:
                  displayTitle = bookmark.identifier;
                  break;
                case BookmarkType.ipg:
                  displayTitle = bookmark.identifier;
                  break;
                case BookmarkType.glossary:
                case BookmarkType.card:
                  displayTitle = bookmark.identifier;
                  break;
              }

              // Wrap in Dismissible only when NOT in edit mode
              Widget tile = Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: _isEditMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) =>
                              _toggleSelection(bookmark.identifier),
                        )
                      : _getBookmarkIcon(bookmark.type),
                  title: Text(
                    displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: _buildSubtitleWithBadges(bookmark),
                  onTap: _isEditMode
                      ? () => _toggleSelection(bookmark.identifier)
                      : () => _showBookmarkPreview(bookmark),
                ),
              );

              if (!_isEditMode) {
                tile = Dismissible(
                  key: Key('${bookmark.type.name}_${bookmark.identifier}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeBookmark(bookmark),
                  child: tile,
                );
              }

              return tile;
            },
          ),
        ),
        if (_isEditMode && _selectedBookmarks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: _deleteSelectedBookmarks,
              icon: const Icon(Icons.delete),
              label: Text(
                  'Delete ${_selectedBookmarks.length} Bookmark${_selectedBookmarks.length == 1 ? '' : 's'}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitleWithBadges(BookmarkedItem bookmark) {
    // Get list names for this bookmark (only in "All" view)
    final listNames = <String>[];
    if (widget.listId == null && bookmark.listIds.isNotEmpty) {
      for (final listId in bookmark.listIds) {
        final list = _allLists.where((l) => l.id == listId).firstOrNull;
        if (list != null) {
          listNames.add(list.name);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getFirstLine(bookmark.content),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (listNames.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: listNames.map((name) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _getBookmarkIcon(BookmarkType type) {
    IconData iconData;

    switch (type) {
      case BookmarkType.rule:
        iconData = Icons.rule;
        break;
      case BookmarkType.glossary:
        iconData = Icons.list_alt;
        break;
      case BookmarkType.mtr:
        iconData = Icons.gavel;
        break;
      case BookmarkType.ipg:
        iconData = Icons.warning_amber;
        break;
      case BookmarkType.card:
        // Card icon needs to be rotated
        return Transform.rotate(
          angle: pi,
          child: Icon(
            Icons.style,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
    }

    return Icon(
      iconData,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  String _getFirstLine(String content) {
    // Remove the rule number prefix if present and get the first meaningful line
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      // Skip empty lines and lines that are just the rule number
      if (trimmed.isNotEmpty &&
          !RegExp(r'^\d{3}\.\d+[a-z]?$').hasMatch(trimmed)) {
        // Remove rule number prefix like "702.9a " if present at the start
        return trimmed.replaceFirst(RegExp(r'^\d{3}\.\d+[a-z]?\s'), '');
      }
    }
    return content;
  }

  void _showBookmarkPreview(BookmarkedItem bookmark) async {
    if (bookmark.type == BookmarkType.glossary) {
      // Use mixin method for glossary terms
      showGlossaryBottomSheet(
        term: bookmark.identifier,
        definition: bookmark.content,
      );
      return;
    }

    if (bookmark.type == BookmarkType.card) {
      // Navigate to card detail screen
      try {
        final card = await _cardService.getCardByName(bookmark.identifier);
        if (card != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardDetailScreen(card: card),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card not found')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load card: $e')),
          );
        }
      }
      return;
    }

    if (bookmark.type == BookmarkType.mtr) {
      // Handle MTR bookmarks
      try {
        final allSections = await _judgeDocsService.getAllMtrSections();

        // Find the rule in all sections
        for (final section in allSections) {
          final rule = section.rules
              .where((r) => r.number == bookmark.identifier)
              .firstOrNull;
          if (rule != null) {
            if (!mounted) return;
            showMtrBottomSheet(
              rule: rule,
              sectionNumber: section.sectionNumber,
              sectionTitle: section.title,
            );
            return;
          }
        }

        // Rule not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MTR rule not found')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load MTR rule: $e')),
          );
        }
      }
      return;
    }

    if (bookmark.type == BookmarkType.ipg) {
      // Handle IPG bookmarks
      try {
        final allSections = await _judgeDocsService.getAllIpgSections();

        // Find the infraction in all sections
        for (final section in allSections) {
          final infraction = section.infractions
              .where((i) => i.number == bookmark.identifier)
              .firstOrNull;
          if (infraction != null) {
            if (!mounted) return;
            showIpgBottomSheet(
              infraction: infraction,
            );
            return;
          }
        }

        // Infraction not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('IPG infraction not found')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load IPG infraction: $e')),
          );
        }
      }
      return;
    }

    // Handle rule bookmarks (comprehensive rules)
    // Parse the rule number to extract section and rule info
    // Format: "702.9a" -> section 7, rule "702", subrule "702.9"
    final ruleNumberMatch =
        RegExp(r'^(\d)(\d{2})\.(\d+)([a-z])?$').firstMatch(bookmark.identifier);

    if (ruleNumberMatch == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to parse rule number')),
        );
      }
      return;
    }

    final sectionNumber = int.parse(ruleNumberMatch.group(1)!);
    final ruleNumber =
        '${ruleNumberMatch.group(1)}${ruleNumberMatch.group(2)}';

    // Preload the section data
    try {
      final rules = await _dataService.getRulesForSection(sectionNumber);
      final rule = rules.firstWhere(
        (r) => r.number == ruleNumber,
        orElse: () => throw Exception('Rule not found'),
      );

      if (!mounted) return;

      // Use mixin method for rule preview
      showRuleBottomSheet(
        rule: rule,
        sectionNumber: sectionNumber,
        subruleNumber: bookmark.identifier,
        content: bookmark.content,
        highlightSubruleNumber:
            bookmark.identifier, // Highlight the bookmarked subrule
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rule: $e')),
        );
      }
    }
  }
}
