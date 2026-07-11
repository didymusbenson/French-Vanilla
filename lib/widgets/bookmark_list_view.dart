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
  final Set<String> _selectedBookmarks = {}; // Stores "type:identifier" composite keys

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

  void _removeBookmarkWithUndo(BookmarkedItem item) async {
    // Optimistically remove from UI
    final removedIndex = _bookmarks.indexOf(item);
    setState(() {
      _bookmarks.remove(item);
    });

    // Show snackbar with undo option
    if (mounted) {
      final snackBar = SnackBar(
        content: Text(widget.listId != null
            ? 'Removed from list'
            : 'Bookmark deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Restore to UI
            setState(() {
              _bookmarks.insert(removedIndex, item);
            });
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
        // Only permanently delete if not undone
        if (reason != SnackBarClosedReason.action) {
          _removeBookmark(item);
        }
      });
    }
  }

  Future<void> _addSelectedBookmarksToLists() async {
    if (_selectedBookmarks.isEmpty) return;

    final allLists = await _favoritesService.getAllLists();

    if (!mounted) return;

    final selectedLists = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _BulkListDialog(
        allLists: allLists,
        title: 'Add to List',
        actionLabel: 'Add',
      ),
    );

    if (selectedLists != null && selectedLists.isNotEmpty) {
      // Add all selected bookmarks to the chosen lists (only if not already in them)
      for (final compositeKey in _selectedBookmarks) {
        final parts = compositeKey.split(':');
        final type = BookmarkType.values.firstWhere((t) => t.name == parts[0]);
        final identifier = parts.sublist(1).join(':');

        // Get current bookmark
        final bookmark = _bookmarks.firstWhere(
          (b) => b.identifier == identifier && b.type == type,
        );

        // Add to selected lists (set union automatically handles duplicates)
        final updatedListIds = {...bookmark.listIds, ...selectedLists}.toList();

        await _favoritesService.updateBookmarkLists(
          identifier,
          type,
          updatedListIds,
        );
      }

      await _loadBookmarks();
    }
  }

  Future<void> _removeSelectedBookmarksFromLists() async {
    if (_selectedBookmarks.isEmpty) return;

    final allLists = await _favoritesService.getAllLists();

    if (!mounted) return;

    final selectedLists = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _BulkListDialog(
        allLists: allLists,
        title: 'Remove from List',
        actionLabel: 'Remove',
      ),
    );

    if (selectedLists != null && selectedLists.isNotEmpty) {
      // Remove all selected bookmarks from the chosen lists
      for (final compositeKey in _selectedBookmarks) {
        final parts = compositeKey.split(':');
        final type = BookmarkType.values.firstWhere((t) => t.name == parts[0]);
        final identifier = parts.sublist(1).join(':');

        // Get current bookmark
        final bookmark = _bookmarks.firstWhere(
          (b) => b.identifier == identifier && b.type == type,
        );

        // Remove from selected lists
        final updatedListIds = bookmark.listIds
            .where((id) => !selectedLists.contains(id))
            .toList();

        await _favoritesService.updateBookmarkLists(
          identifier,
          type,
          updatedListIds,
        );
      }

      await _loadBookmarks();
    }
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
      // Build lists of identifiers and types for bulk operation
      final identifiers = <String>[];
      final types = <BookmarkType>[];

      for (final compositeKey in _selectedBookmarks) {
        // Parse "type:identifier" format
        final parts = compositeKey.split(':');
        final type = BookmarkType.values.firstWhere((t) => t.name == parts[0]);
        final identifier = parts.sublist(1).join(':'); // Handle identifiers with colons
        identifiers.add(identifier);
        types.add(type);
      }

      // Use bulk delete methods for better performance
      if (widget.listId != null) {
        // Remove from this list only
        await _favoritesService.removeBookmarksFromList(
            identifiers, types, widget.listId!);
      } else {
        // Delete entirely
        await _favoritesService.removeBookmarks(identifiers, types);
      }

      setState(() {
        _selectedBookmarks.clear();
        _isEditMode = false;
      });
      await _loadBookmarks();
    }
  }

  void _toggleSelection(String identifier, BookmarkType type) {
    final compositeKey = '${type.name}:$identifier';
    setState(() {
      if (_selectedBookmarks.contains(compositeKey)) {
        _selectedBookmarks.remove(compositeKey);
      } else {
        _selectedBookmarks.add(compositeKey);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedBookmarks.clear();
      _selectedBookmarks.addAll(
          _bookmarks.map((b) => '${b.type.name}:${b.identifier}'));
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
            TextButton(
              onPressed: toggleEditMode,
              child: Text(_isEditMode ? 'Cancel' : 'Edit'),
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
              final compositeKey = '${bookmark.type.name}:${bookmark.identifier}';
              final isSelected = _selectedBookmarks.contains(compositeKey);

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
                              _toggleSelection(bookmark.identifier, bookmark.type),
                        )
                      : _getBookmarkIcon(bookmark.type),
                  title: Text(
                    displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: _buildSubtitleWithBadges(bookmark),
                  onTap: _isEditMode
                      ? () => _toggleSelection(bookmark.identifier, bookmark.type)
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
                  onDismissed: (_) => _removeBookmarkWithUndo(bookmark),
                  child: tile,
                );
              }

              return tile;
            },
          ),
        ),
        if (_isEditMode && _selectedBookmarks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: _addSelectedBookmarksToLists,
                  icon: const Icon(Icons.playlist_add),
                  label: Text(
                      'Add to List (${_selectedBookmarks.length} bookmark${_selectedBookmarks.length == 1 ? '' : 's'})'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _removeSelectedBookmarksFromLists,
                  icon: const Icon(Icons.playlist_remove),
                  label: Text(
                      'Remove from List (${_selectedBookmarks.length} bookmark${_selectedBookmarks.length == 1 ? '' : 's'})'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _deleteSelectedBookmarks,
                  icon: const Icon(Icons.delete),
                  label: Text(
                      'Delete ${_selectedBookmarks.length} Bookmark${_selectedBookmarks.length == 1 ? '' : 's'}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
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

  /// Normalizes text for drift comparison: collapses runs of whitespace and
  /// trims, so cosmetic formatting differences don't register as a change.
  String _normalizeForCompare(String s) =>
      s.replaceAll(RegExp(r'\s+'), ' ').trim();

  void _showBookmarkPreview(BookmarkedItem bookmark) async {
    if (bookmark.type == BookmarkType.glossary) {
      // Prefer the live definition so glossary bookmarks reflect data updates;
      // fall back to the saved snapshot if the term is gone (renamed/removed).
      String definition = bookmark.content;
      String? staleNotice;
      try {
        final terms = await _dataService.getGlossaryTerms();
        final match = terms
            .where((t) =>
                t.term.toLowerCase() == bookmark.identifier.toLowerCase())
            .firstOrNull;
        if (match != null) {
          definition = match.definition;
        } else {
          staleNotice =
              'This term was bookmarked for an older version of the glossary '
              'and may have been changed or removed. Showing your saved copy.';
        }
      } catch (_) {
        // Live glossary unavailable — keep the snapshot silently.
      }
      if (!mounted) return;
      showGlossaryBottomSheet(
        term: bookmark.identifier,
        definition: definition,
        staleNotice: staleNotice,
        showListButton: true,
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
          // Not found live — card name may have changed. Show the saved copy.
          showSnapshotBottomSheet(
            title: bookmark.identifier,
            subtitle: 'Card',
            content: bookmark.content,
            staleNotice:
                'This card was bookmarked from an older version of the card '
                'data and may have been changed or removed. Showing your '
                'saved copy.',
          );
        }
      } catch (e) {
        debugPrint('Failed to load card preview: $e');
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
              showListButton: true,
            );
            return;
          }
        }

        // Not found live — likely renumbered/removed by an update. Show the
        // saved snapshot instead of a dead end.
        if (!mounted) return;
        showSnapshotBottomSheet(
          title: bookmark.identifier,
          subtitle: 'Magic Tournament Rules',
          content: bookmark.content,
          staleNotice:
              'This rule was bookmarked for an older version of the MTR and '
              'may have been changed or removed. Showing your saved copy.',
        );
      } catch (e) {
        debugPrint('Failed to load MTR rule preview: $e');
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
              showListButton: true,
            );
            return;
          }
        }

        // Not found live — likely renumbered/removed by an update. Show the
        // saved snapshot instead of a dead end.
        if (!mounted) return;
        showSnapshotBottomSheet(
          title: bookmark.identifier,
          subtitle: 'Infraction Procedure Guide',
          content: bookmark.content,
          staleNotice:
              'This entry was bookmarked for an older version of the IPG and '
              'may have been changed or removed. Showing your saved copy.',
        );
      } catch (e) {
        debugPrint('Failed to load IPG infraction preview: $e');
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

      // Prefer the LIVE subrule text and flag drift against the saved snapshot.
      // Rule bookmarks store the SubruleGroup number as their identifier and
      // that group's full content as the snapshot, so this compares like-for-like.
      final liveGroup = rule.subruleGroups
          .where((g) => g.number == bookmark.identifier)
          .firstOrNull;

      String displayContent;
      String? staleNotice;
      if (liveGroup == null) {
        // Subrule renumbered or removed — show the saved copy.
        displayContent = bookmark.content;
        staleNotice =
            'This rule was bookmarked for an older version of the Comprehensive '
            'Rules and may have been changed or removed. Showing your saved copy.';
      } else {
        displayContent = liveGroup.content;
        if (_normalizeForCompare(liveGroup.content) !=
            _normalizeForCompare(bookmark.content)) {
          // Subrule still exists but its text changed — silently refresh the
          // saved snapshot so the bookmark tracks the current rules. No notice.
          await _favoritesService.refreshBookmarkContent(
            bookmark.identifier,
            BookmarkType.rule,
            liveGroup.content,
          );
        }
      }

      if (!mounted) return;

      // Use mixin method for rule preview
      showRuleBottomSheet(
        rule: rule,
        sectionNumber: sectionNumber,
        subruleNumber: bookmark.identifier,
        content: displayContent,
        highlightSubruleNumber:
            bookmark.identifier, // Highlight the bookmarked subrule
        staleNotice: staleNotice,
        showListButton: true,
      );
    } catch (e) {
      debugPrint('Failed to load rule preview: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rule: $e')),
        );
      }
    }
  }
}

/// Dialog for bulk list operations (add/remove)
class _BulkListDialog extends StatefulWidget {
  final List<BookmarkList> allLists;
  final String title;
  final String actionLabel;

  const _BulkListDialog({
    required this.allLists,
    required this.title,
    required this.actionLabel,
  });

  @override
  State<_BulkListDialog> createState() => _BulkListDialogState();
}

class _BulkListDialogState extends State<_BulkListDialog> {
  final Set<String> _selectedListIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.allLists.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No lists available. Create a list first.'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allLists.length,
                itemBuilder: (context, index) {
                  final list = widget.allLists[index];
                  final isSelected = _selectedListIds.contains(list.id);

                  return CheckboxListTile(
                    title: Text(list.name),
                    subtitle: list.description != null
                        ? Text(
                            list.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedListIds.add(list.id);
                        } else {
                          _selectedListIds.remove(list.id);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedListIds),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
