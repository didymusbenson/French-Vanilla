import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/mtr_rule.dart';
import '../services/favorites_service.dart';

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

class _MtrRuleDetailScreenState extends State<MtrRuleDetailScreen> {
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
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleBookmark,
            tooltip: _isBookmarked ? 'Remove bookmark' : 'Bookmark',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copy') {
                _copyToClipboard();
              } else if (value == 'share') {
                _shareRule();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Copy'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.rule.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Content
                Text(
                  widget.rule.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
