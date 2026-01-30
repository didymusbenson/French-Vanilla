import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ipg_infraction.dart';
import '../services/favorites_service.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/formatted_content_mixin.dart';

/// Screen showing the full structured content of a single IPG infraction.
class IpgInfractionDetailScreen extends StatefulWidget {
  final IpgInfraction infraction;

  const IpgInfractionDetailScreen({
    super.key,
    required this.infraction,
  });

  @override
  State<IpgInfractionDetailScreen> createState() => _IpgInfractionDetailScreenState();
}

class _IpgInfractionDetailScreenState extends State<IpgInfractionDetailScreen>
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
      widget.infraction.number,
      BookmarkType.ipg,
    );
    setState(() {
      _isBookmarked = isBookmarked;
    });
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await _favoritesService.removeBookmark(
        widget.infraction.number,
        BookmarkType.ipg,
      );
    } else {
      await _favoritesService.addBookmark(
        widget.infraction.number,
        _buildContentText(),
        BookmarkType.ipg,
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
                ? 'Bookmarked ${widget.infraction.number}'
                : 'Removed bookmark',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  String _buildContentText() {
    final buffer = StringBuffer();
    buffer.writeln('${widget.infraction.number}: ${widget.infraction.cleanTitle}');
    if (widget.infraction.penalty != null) {
      buffer.writeln('Penalty: ${widget.infraction.penalty}');
    }
    buffer.writeln();

    if (widget.infraction.definition != null) {
      buffer.writeln('Definition:');
      buffer.writeln(widget.infraction.definition);
      buffer.writeln();
    }

    if (widget.infraction.examples.isNotEmpty) {
      buffer.writeln('Examples:');
      for (final example in widget.infraction.examples) {
        buffer.writeln(example);
      }
      buffer.writeln();
    }

    if (widget.infraction.philosophy != null) {
      buffer.writeln('Philosophy:');
      buffer.writeln(widget.infraction.philosophy);
      buffer.writeln();
    }

    if (widget.infraction.additionalRemedy != null) {
      buffer.writeln('Additional Remedy:');
      buffer.writeln(widget.infraction.additionalRemedy);
      buffer.writeln();
    }

    if (widget.infraction.upgrade != null) {
      buffer.writeln('Upgrade:');
      buffer.writeln(widget.infraction.upgrade);
    }

    return buffer.toString();
  }

  void _copyToClipboard() {
    final text = 'IPG ${_buildContentText()}';
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareInfraction() {
    final text = 'IPG ${_buildContentText()}';
    Share.share(text);
  }

  Color _getPenaltyColor(String? penalty) {
    if (penalty == null) return Colors.grey;

    switch (penalty.toLowerCase()) {
      case 'no penalty':
        return Colors.green;
      case 'warning':
        return Colors.yellow.shade700;
      case 'game loss':
        return Colors.orange;
      case 'match loss':
        return Colors.red;
      case 'disqualification':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IPG ${widget.infraction.number}'),
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
                _shareInfraction();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title header (outside card, like CR)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.infraction.cleanTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (widget.infraction.penalty != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getPenaltyColor(widget.infraction.penalty),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.infraction.penalty!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Single card containing all subsections
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Definition
                    if (widget.infraction.definition != null &&
                        widget.infraction.definition!.isNotEmpty)
                      _buildSection(
                        'Definition',
                        widget.infraction.definition!,
                      ),

                    // Examples
                    if (widget.infraction.examples.isNotEmpty)
                      _buildExamplesSection('Examples', widget.infraction.examples),

                    // Philosophy
                    if (widget.infraction.philosophy != null &&
                        widget.infraction.philosophy!.isNotEmpty)
                      _buildSection(
                        'Philosophy',
                        widget.infraction.philosophy!,
                      ),

                    // Additional Remedy
                    if (widget.infraction.additionalRemedy != null &&
                        widget.infraction.additionalRemedy!.isNotEmpty)
                      _buildSection(
                        'Additional Remedy',
                        widget.infraction.additionalRemedy!,
                      ),

                    // Upgrade
                    if (widget.infraction.upgrade != null &&
                        widget.infraction.upgrade!.isNotEmpty)
                      _buildSection(
                        'Upgrade',
                        widget.infraction.upgrade!,
                        isLast: true,
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

  Widget _buildSection(String title, String content, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled header
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          // Content with formatted rendering (links, example callouts, etc.)
          buildFormattedContent(content),
        ],
      ),
    );
  }

  Widget _buildExamplesSection(String title, List<String> examples) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled header
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          // Content - each example with formatted rendering
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: examples.map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: buildFormattedContent(example),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }
}
