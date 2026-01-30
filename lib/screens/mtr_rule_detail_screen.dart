import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/mtr_rule.dart';
import '../services/favorites_service.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/formatted_content_mixin.dart';

/// Screen showing the full content of a single MTR rule.
class MtrRuleDetailScreen extends StatefulWidget {
  final MtrRule rule;

  const MtrRuleDetailScreen({
    super.key,
    required this.rule,
  });

  @override
  State<MtrRuleDetailScreen> createState() => _MtrRuleDetailScreenState();
}

class _MtrRuleDetailScreenState extends State<MtrRuleDetailScreen>
    with RuleLinkMixin, FormattedContentMixin {
  final _favoritesService = FavoritesService();
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await _favoritesService.isBookmarked(
      widget.rule.number,
      BookmarkType.mtr,
    );
    setState(() {
      _isBookmarked = isBookmarked;
    });
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await _favoritesService.removeBookmark(
        widget.rule.number,
        BookmarkType.mtr,
      );
    } else {
      await _favoritesService.addBookmark(
        widget.rule.number,
        '${widget.rule.title}\n\n${widget.rule.content}',
        BookmarkType.mtr,
      );
    }

    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked
                ? 'Bookmarked ${widget.rule.number}'
                : 'Removed bookmark',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyToClipboard() {
    final text = 'MTR ${widget.rule.number}: ${widget.rule.title}\n\n${widget.rule.content}';
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareRule() {
    final text = 'MTR ${widget.rule.number}: ${widget.rule.title}\n\n${widget.rule.content}';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MTR ${widget.rule.number}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: 'Copy rule',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rule number
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'MTR ${widget.rule.number}. ${widget.rule.title}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Card with rule content
            GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _showContextMenu();
              },
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with rule number and bookmark icon
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
                              widget.rule.number,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                              size: 20,
                            ),
                            color: _isBookmarked
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            onPressed: _toggleBookmark,
                            tooltip: _isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    // Content with formatted rendering
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: buildFormattedContent(widget.rule.content),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(_isBookmarked ? 'Remove Bookmark' : 'Add Bookmark'),
              onTap: () {
                Navigator.pop(context);
                _toggleBookmark();
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
                _copyToClipboard();
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
                _shareRule();
              },
            ),
          ],
        ),
      ),
    );
  }
}
