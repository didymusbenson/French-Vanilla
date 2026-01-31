import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ipg_infraction.dart';
import '../services/favorites_service.dart';
import '../mixins/rule_link_mixin.dart';
import '../mixins/formatted_content_mixin.dart';

/// Screen showing the full content of a single IPG infraction.
/// Displays all sections: Definition, Examples, Philosophy, Additional Remedy, Upgrade.
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
    // Build bookmark content from all infraction parts
    final buffer = StringBuffer();
    buffer.writeln(widget.infraction.cleanTitle);
    if (widget.infraction.penalty != null) {
      buffer.writeln('Penalty: ${widget.infraction.penalty}');
    }
    buffer.writeln();
    if (widget.infraction.definition != null) {
      buffer.writeln(widget.infraction.definition);
    }

    if (_isBookmarked) {
      await _favoritesService.removeBookmark(
        widget.infraction.number,
        BookmarkType.ipg,
      );
    } else {
      await _favoritesService.addBookmark(
        widget.infraction.number,
        buffer.toString(),
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

  void _copyToClipboard() {
    final buffer = StringBuffer();
    buffer.writeln('IPG ${widget.infraction.number}: ${widget.infraction.cleanTitle}');
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
        buffer.writeln();
      }
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

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareInfraction() {
    final buffer = StringBuffer();
    buffer.writeln('IPG ${widget.infraction.number}: ${widget.infraction.cleanTitle}');
    if (widget.infraction.penalty != null) {
      buffer.writeln('Penalty: ${widget.infraction.penalty}');
    }
    buffer.writeln();
    if (widget.infraction.definition != null) {
      buffer.writeln(widget.infraction.definition);
    }

    Share.share(buffer.toString().trim());
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
              _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
            ),
            onPressed: _toggleBookmark,
            tooltip: _isBookmarked ? 'Remove bookmark' : 'Add bookmark',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: 'Copy infraction',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with infraction number and title
            Text(
              'IPG ${widget.infraction.number}. ${widget.infraction.cleanTitle}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            // Penalty badge
            if (widget.infraction.penalty != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getPenaltyColor(widget.infraction.penalty),
                  borderRadius: BorderRadius.circular(6),
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

            const SizedBox(height: 24),

            // Card with all content sections
            Card(
              margin: EdgeInsets.zero,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Definition
                    if (widget.infraction.definition != null) ...[
                      Text(
                        'Definition',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildFormattedContent(widget.infraction.definition!),
                      const SizedBox(height: 24),
                    ],

                    // Examples
                    if (widget.infraction.examples.isNotEmpty) ...[
                      Text(
                        'Examples',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.infraction.examples.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildFormattedContent(entry.value),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // Philosophy
                    if (widget.infraction.philosophy != null) ...[
                      Text(
                        'Philosophy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildFormattedContent(widget.infraction.philosophy!),
                      const SizedBox(height: 24),
                    ],

                    // Additional Remedy
                    if (widget.infraction.additionalRemedy != null) ...[
                      Text(
                        'Additional Remedy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildFormattedContent(widget.infraction.additionalRemedy!),
                      const SizedBox(height: 24),
                    ],

                    // Upgrade
                    if (widget.infraction.upgrade != null) ...[
                      Text(
                        'Upgrade',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildFormattedContent(widget.infraction.upgrade!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
