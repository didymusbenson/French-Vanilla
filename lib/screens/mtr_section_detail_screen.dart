import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import '../services/judge_docs_service.dart';
import '../models/mtr_rule.dart';
import '../services/favorites_service.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/formatted_content_mixin.dart';
import '../mixins/aggregating_snackbar_mixin.dart';

/// Screen showing all rules in an MTR section (like comprehensive rules).
/// Individual rules are displayed as "subrules" with titles in the header.
class MtrSectionDetailScreen extends StatefulWidget {
  final dynamic sectionNumber; // Can be int (1-10) or String ("A"-"F")
  final String sectionTitle;
  final String? highlightRuleNumber; // e.g., "6.7" to highlight

  const MtrSectionDetailScreen({
    super.key,
    required this.sectionNumber,
    required this.sectionTitle,
    this.highlightRuleNumber,
  });

  @override
  State<MtrSectionDetailScreen> createState() => _MtrSectionDetailScreenState();
}

class _MtrSectionDetailScreenState extends State<MtrSectionDetailScreen>
    with RuleLinkMixin, FormattedContentMixin, AggregatingSnackBarMixin {
  final _judgeDocsService = JudgeDocsService();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final _favoritesService = FavoritesService();
  final Map<String, bool> _bookmarkStatus = {};

  List<MtrRule>? _rules;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final section = await _judgeDocsService.loadMtrSection(widget.sectionNumber);
      setState(() {
        _rules = section.rules;
        _isLoading = false;
      });

      // Load bookmark statuses
      await _loadBookmarkStatuses();

      // Scroll to highlighted rule after build
      if (widget.highlightRuleNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToRule(widget.highlightRuleNumber!);
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load rules: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBookmarkStatuses() async {
    if (_rules == null) return;

    for (final rule in _rules!) {
      final isBookmarked = await _favoritesService.isBookmarked(rule.number, BookmarkType.mtr);
      setState(() {
        _bookmarkStatus[rule.number] = isBookmarked;
      });
    }
  }

  Future<void> _toggleBookmark(String ruleNumber, String title, String content) async {
    await _favoritesService.toggleBookmark(
      ruleNumber,
      '$title\n\n$content',
      BookmarkType.mtr,
    );
    final isBookmarked = await _favoritesService.isBookmarked(ruleNumber, BookmarkType.mtr);
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

  void _copyRuleContent(String ruleNumber, String title, String content) {
    final plainText = 'MTR $ruleNumber: $title\n\n$content';
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

  void _shareRuleContent(String ruleNumber, String title, String content) {
    final plainText = 'MTR $ruleNumber: $title\n\n$content';

    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    Share.share(
      plainText,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  void _showContextMenu(String ruleNumber, String title, String content) {
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
                _toggleBookmark(ruleNumber, title, content);
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
                _copyRuleContent(ruleNumber, title, content);
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
                _shareRuleContent(ruleNumber, title, content);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToRule(String ruleNumber) {
    if (_rules == null) return;

    final targetIndex = _rules!.indexWhere((rule) => rule.number == ruleNumber);

    if (targetIndex != -1) {
      const alignment = 0.01;

      _itemScrollController.scrollTo(
        index: targetIndex + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: alignment,
      );
    }
  }

  void _copyAllContent() {
    if (_rules == null) return;

    final buffer = StringBuffer();
    buffer.writeln('${widget.sectionTitle}\n');
    for (final rule in _rules!) {
      buffer.writeln('${rule.number}. ${rule.title}');
      buffer.writeln(rule.content);
      buffer.writeln();
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Section copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionTitle),
        actions: [
          if (!_isLoading && _rules != null && _rules!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyAllContent,
              tooltip: 'Copy entire section',
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
                  _loadRules();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rules == null || _rules!.isEmpty) {
      return const Center(child: Text('No rules found for this section.'));
    }

    return ScrollablePositionedList.builder(
      itemCount: _rules!.length + 1, // +1 for header
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      itemBuilder: (context, index) {
        // First item is the header
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              widget.sectionTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        // Remaining items are rules
        final ruleIndex = index - 1;
        final rule = _rules![ruleIndex];
        final isHighlighted = widget.highlightRuleNumber == rule.number;
        final isBookmarked = _bookmarkStatus[rule.number] ?? false;

        return GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showContextMenu(rule.number, rule.title, rule.content);
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
                // Header with rule number, title, and bookmark icon
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
                          '${rule.number} ${rule.title}',
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
                        onPressed: () => _toggleBookmark(rule.number, rule.title, rule.content),
                        tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: buildFormattedContent(rule.content, isHighlighted: isHighlighted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
