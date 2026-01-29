import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import '../models/rule.dart';
import '../services/favorites_service.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/formatted_content_mixin.dart';
import '../mixins/aggregating_snackbar_mixin.dart';

class RuleDetailScreen extends StatefulWidget {
  final Rule rule;
  final int sectionNumber;
  final String? highlightSubruleNumber; // e.g., "700.1" to highlight

  const RuleDetailScreen({
    super.key,
    required this.rule,
    required this.sectionNumber,
    this.highlightSubruleNumber,
  });

  @override
  State<RuleDetailScreen> createState() => _RuleDetailScreenState();
}

class _RuleDetailScreenState extends State<RuleDetailScreen>
    with RuleLinkMixin, FormattedContentMixin, AggregatingSnackBarMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final _favoritesService = FavoritesService();
  final Map<String, bool> _bookmarkStatus = {};

  @override
  void initState() {
    super.initState();

    // Load bookmark statuses
    _loadBookmarkStatuses();

    // Scroll to highlighted subrule after build
    if (widget.highlightSubruleNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSubrule(widget.highlightSubruleNumber!);
      });
    }
  }

  Future<void> _loadBookmarkStatuses() async {
    for (final group in widget.rule.subruleGroups) {
      final isBookmarked = await _favoritesService.isBookmarked(group.number, BookmarkType.rule);
      setState(() {
        _bookmarkStatus[group.number] = isBookmarked;
      });
    }
  }

  Future<void> _toggleBookmark(String ruleNumber, String content) async {
    await _favoritesService.toggleBookmark(ruleNumber, content, BookmarkType.rule);
    final isBookmarked = await _favoritesService.isBookmarked(ruleNumber, BookmarkType.rule);
    setState(() {
      _bookmarkStatus[ruleNumber] = isBookmarked;
    });

    // Show feedback
    if (mounted) {
      showAggregatingSnackBar(
        isBookmarked ? 'Bookmark added' : 'Bookmark removed',
      );
    }
  }

  void _copyRuleContent(String ruleNumber, String content) {
    // Get plain text content (remove any formatting)
    final plainText = 'Rule $ruleNumber\n\n$content';
    Clipboard.setData(ClipboardData(text: plainText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rule copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _shareRuleContent(String ruleNumber, String content) {
    // Get plain text content for sharing
    final plainText = 'Rule $ruleNumber\n\n$content';

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

  void _showContextMenu(String ruleNumber, String content) {
    final isBookmarked = _bookmarkStatus[ruleNumber] ?? false;

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
                _toggleBookmark(ruleNumber, content);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.copy,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Copy Rule'),
              onTap: () {
                Navigator.pop(context);
                _copyRuleContent(ruleNumber, content);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Share Rule'),
              onTap: () {
                Navigator.pop(context);
                _shareRuleContent(ruleNumber, content);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToSubrule(String subruleNumber) {
    // Find the index of the target subrule (add 1 for the header)
    final targetIndex = widget.rule.subruleGroups
        .indexWhere((group) => group.number == subruleNumber);

    if (targetIndex != -1) {
      // Position item just below app bar with minimal spacing
      // 0.01 provides small buffer so card header is barely visible below app bar
      const alignment = 0.01;

      // Scroll to the item (index + 1 to account for header)
      _itemScrollController.scrollTo(
        index: targetIndex + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: alignment,
      );
    }
  }

  void _copyAllContent() {
    final buffer = StringBuffer();
    buffer.writeln('${widget.rule.number}. ${widget.rule.title}\n');
    for (final group in widget.rule.subruleGroups) {
      buffer.writeln(group.content);
      buffer.writeln();
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rule copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rule ${widget.rule.number}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyAllContent,
            tooltip: 'Copy entire rule',
          ),
        ],
      ),
      body: widget.rule.subruleGroups.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.rule.number}. ${widget.rule.title}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No subrules available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ScrollablePositionedList.builder(
              itemCount: widget.rule.subruleGroups.length + 1, // +1 for header
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
              itemBuilder: (context, index) {
                // First item is the header
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      '${widget.rule.number}. ${widget.rule.title}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                // Remaining items are subrule groups
                final groupIndex = index - 1;
                final group = widget.rule.subruleGroups[groupIndex];
                final isHighlighted = widget.highlightSubruleNumber == group.number;
                final isBookmarked = _bookmarkStatus[group.number] ?? false;

                return GestureDetector(
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    _showContextMenu(group.number, group.content);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isHighlighted ? 8 : 2,
                    color: isHighlighted
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with subrule number and bookmark icon
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
                                  group.number,
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
                                onPressed: () => _toggleBookmark(group.number, group.content),
                                tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: buildFormattedContent(group.content, isHighlighted: isHighlighted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
