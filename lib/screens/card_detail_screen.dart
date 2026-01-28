import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/card.dart';
import '../services/favorites_service.dart';
import '../services/rules_data_service.dart';
import '../mixins/aggregating_snackbar_mixin.dart';
import 'glossary_screen.dart';
import 'search_screen.dart';

class CardDetailScreen extends StatefulWidget {
  final MagicCard card;

  const CardDetailScreen({
    super.key,
    required this.card,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen>
    with AggregatingSnackBarMixin {
  final _favoritesService = FavoritesService();
  final _dataService = RulesDataService();
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    final isBookmarked =
        await _favoritesService.isBookmarked(widget.card.name, BookmarkType.card);
    setState(() {
      _isBookmarked = isBookmarked;
    });
  }

  Future<void> _toggleBookmark() async {
    await _favoritesService.toggleBookmark(
      widget.card.name,
      _getCardSummary(),
      BookmarkType.card,
    );
    final isBookmarked =
        await _favoritesService.isBookmarked(widget.card.name, BookmarkType.card);
    setState(() {
      _isBookmarked = isBookmarked;
    });

    if (mounted) {
      showAggregatingSnackBar(
        isBookmarked ? 'Bookmark added' : 'Bookmark removed',
      );
    }
  }

  String _getCardSummary() {
    return '${widget.card.name}\n${widget.card.type}${widget.card.text != null ? '\n${widget.card.text}' : ''}';
  }

  void _copyCardContent() {
    final content = StringBuffer();
    content.writeln(widget.card.name);
    content.writeln(widget.card.type);
    if (widget.card.text != null) {
      content.writeln();
      content.writeln(widget.card.text);
    }
    if (widget.card.rulings.isNotEmpty) {
      content.writeln();
      content.writeln('Rulings:');
      for (final ruling in widget.card.rulings) {
        content.writeln('${ruling.date}: ${ruling.text}');
      }
    }

    Clipboard.setData(ClipboardData(text: content.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _shareCardContent() {
    final content = StringBuffer();
    content.writeln(widget.card.name);
    content.writeln(widget.card.type);
    if (widget.card.text != null) {
      content.writeln();
      content.writeln(widget.card.text);
    }

    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    Share.share(
      content.toString(),
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> _handleKeywordTap(String keyword) async {
    // First, try to find the keyword in the glossary
    final glossaryTerms = await _dataService.getGlossaryTerms();
    final matchingTerm = glossaryTerms.where((term) =>
        term.term.toLowerCase() == keyword.toLowerCase()).firstOrNull;

    if (matchingTerm != null && mounted) {
      // Navigate to glossary with the term highlighted
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GlossaryScreen(highlightTerm: matchingTerm.term),
        ),
      );
    } else if (mounted) {
      // Fallback to search
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$keyword" not found in Glossary, searching.'),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchScreen(initialQuery: keyword),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.card.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleBookmark,
            tooltip: _isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyCardContent,
            tooltip: 'Copy Card',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareCardContent,
            tooltip: 'Share Card',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Name (large)
              Text(
                widget.card.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              // Card Type
              Text(
                widget.card.type,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),

              const SizedBox(height: 16),

              // Card Text (Oracle Text)
              if (widget.card.text != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.card.text!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Keywords
              if (widget.card.keywords.isNotEmpty) ...[
                Text(
                  'Keywords',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.card.keywords.map((keyword) {
                    return ActionChip(
                      label: Text(keyword),
                      onPressed: () => _handleKeywordTap(keyword),
                      avatar: const Icon(Icons.search, size: 18),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Format Legalities (always show)
              Text(
                'Formats',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildLegalitiesGrid(),
              const SizedBox(height: 16),

              // Rulings
              if (widget.card.rulings.isNotEmpty) ...[
                Text(
                  'Rulings (${widget.card.rulings.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...widget.card.rulings.map((ruling) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ruling.date,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ruling.text,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )),
              ],

              if (widget.card.rulings.isEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No rulings for this card',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalitiesGrid() {
    // Define all standard formats to display
    const allFormats = [
      'standard',
      'pioneer',
      'modern',
      'legacy',
      'vintage',
      'commander',
      'alchemy',
      'historic',
      'brawl',
      'timeless',
      'pauper',
      'penny',
      'oathbreaker',
    ];

    // Build entries for all formats (default to "Not Legal" if not present)
    final sortedEntries = allFormats.map((format) {
      final status = widget.card.legalities[format] ?? 'Not Legal';
      return MapEntry(format, status);
    }).toList();

    // Sort: Legal first, then Restricted, then Banned, then Not Legal
    sortedEntries.sort((a, b) {
      const statusOrder = {
        'Legal': 0,
        'Restricted': 1,
        'Banned': 2,
        'Not Legal': 3,
      };
      final aOrder = statusOrder[a.value] ?? 4;
      final bOrder = statusOrder[b.value] ?? 4;

      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }

      // Same status, sort alphabetically by format name
      return a.key.compareTo(b.key);
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 8,
        crossAxisSpacing: 6,
        mainAxisSpacing: 3,
      ),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final format = entry.key;
        final legality = entry.value;

        // Determine colors based on status
        Color backgroundColor;
        Color badgeColor;
        Color textColor;
        String badgeText;

        switch (legality) {
          case 'Legal':
            backgroundColor = Colors.green.shade100;
            badgeColor = Colors.green.shade700;
            textColor = Colors.green.shade900;
            badgeText = 'LEGAL';
            break;
          case 'Banned':
            backgroundColor = Colors.red.shade100;
            badgeColor = Colors.red.shade700;
            textColor = Colors.red.shade900;
            badgeText = 'BANNED';
            break;
          case 'Restricted':
            backgroundColor = Colors.orange.shade100;
            badgeColor = Colors.orange.shade700;
            textColor = Colors.orange.shade900;
            badgeText = 'RESTRICTED';
            break;
          default: // "Not Legal"
            backgroundColor = Colors.grey.shade300;
            badgeColor = Colors.grey.shade600;
            textColor = Colors.grey.shade800;
            badgeText = 'NOT LEGAL';
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatFormatName(format),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textColor,
                    height: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFormatName(String format) {
    // Capitalize first letter of each word
    return format
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
