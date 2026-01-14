import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import '../models/rule.dart';
import '../services/favorites_service.dart';
import '../services/rules_data_service.dart';

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

class _RuleDetailScreenState extends State<RuleDetailScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final _favoritesService = FavoritesService();
  final Map<String, bool> _bookmarkStatus = {};

  @override
  void initState() {
    super.initState();

    print('=== RuleDetailScreen initState ===');
    print('Rule: ${widget.rule.number}. ${widget.rule.title}');
    print('Highlight subrule: ${widget.highlightSubruleNumber}');
    print('Total subrule groups: ${widget.rule.subruleGroups.length}');
    print('First few group numbers: ${widget.rule.subruleGroups.take(5).map((g) => g.number).toList()}');

    // Load bookmark statuses
    _loadBookmarkStatuses();

    // Scroll to highlighted subrule after build
    if (widget.highlightSubruleNumber != null) {
      print('Scheduling scroll to: ${widget.highlightSubruleNumber}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('PostFrameCallback executing for: ${widget.highlightSubruleNumber}');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBookmarked ? 'Bookmark added' : 'Bookmark removed'),
          duration: const Duration(seconds: 1),
        ),
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
    print('=== _scrollToSubrule called ===');
    print('Target subrule: $subruleNumber');
    print('Available subrule numbers: ${widget.rule.subruleGroups.map((g) => g.number).toList()}');

    // Find the index of the target subrule (add 1 for the header)
    final targetIndex = widget.rule.subruleGroups
        .indexWhere((group) => group.number == subruleNumber);

    print('Target index: $targetIndex');

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
      print('Scrolling to index ${targetIndex + 1} for subrule: $subruleNumber');
    } else {
      print('ERROR: Subrule not found: $subruleNumber');
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

  /// Parses text and creates TextSpan with tappable rule references
  List<TextSpan> _parseTextWithLinks(String text, TextStyle? baseStyle, bool isHighlighted) {
    final spans = <TextSpan>[];
    // Pattern matches: "rule 704", "rule 702.9", "rule 702.9a", "rules 702.9", etc.
    // Also matches variations like "see rule 704" or "Rule 702.9a"
    final rulePattern = RegExp(r'\brule(?:s)?\s+(\d{3})(?:\.(\d+)([a-z])?)?\b', caseSensitive: false);

    int lastMatchEnd = 0;
    for (final match in rulePattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      // Extract rule number (e.g., "702.9a" or just "704")
      final baseRule = match.group(1)!; // Always captured (e.g., "704" or "702")
      final minorPart = match.group(2); // Optional decimal part (e.g., "9")
      final letterPart = match.group(3); // Optional letter (e.g., "a")

      final ruleNumber = minorPart != null
          ? '$baseRule.$minorPart${letterPart ?? ''}'
          : baseRule;

      final fullMatch = match.group(0)!; // Full matched text like "rule 704" or "rule 702.9a"

      // Add the tappable link
      spans.add(TextSpan(
        text: fullMatch,
        style: baseStyle?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w500,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _navigateToRule(ruleNumber),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last match
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  /// Navigate to a referenced rule
  Future<void> _navigateToRule(String ruleNumber) async {
    // Parse the rule number to extract section and rule info
    // Format: "704" -> section 7, rule "704"
    // Format: "702.9a" -> section 7, rule "702", highlight subrule "702.9a"
    final ruleMatch = RegExp(r'^(\d)(\d{2})(?:\.(\d+)([a-z])?)?$').firstMatch(ruleNumber);

    if (ruleMatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to parse rule reference')),
      );
      return;
    }

    final sectionNumber = int.parse(ruleMatch.group(1)!);
    final baseRuleNumber = '${ruleMatch.group(1)}${ruleMatch.group(2)}';

    // Only highlight a specific subrule if the reference includes a decimal part
    // Strip letter suffix (e.g., "702.9a" -> "702.9") since we only index base subrules
    String? highlightSubrule;
    if (ruleMatch.group(3) != null) {
      highlightSubrule = '${ruleMatch.group(1)}${ruleMatch.group(2)}.${ruleMatch.group(3)}';
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final rules = await RulesDataService().getRulesForSection(sectionNumber);
      final targetRule = rules.firstWhere(
        (r) => r.number == baseRuleNumber,
        orElse: () => throw Exception('Rule not found'),
      );

      if (!mounted) return;

      // Close loading indicator
      Navigator.pop(context);

      // Navigate to the rule detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RuleDetailScreen(
            rule: targetRule,
            sectionNumber: sectionNumber,
            highlightSubruleNumber: highlightSubrule,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rule: $e')),
        );
      }
    }
  }

  /// Builds formatted subrule content with spacing between subsections
  Widget _buildSubruleContent(String content, bool isHighlighted) {
    // Strip the leading subrule number from the first line since it's now in the header
    // Matches "201.1. " or "702.90a " (period OR letter after minor number)
    final leadingNumberPattern = RegExp(r'^\d{3}\.\d+([a-z]|\.)\s+');
    String processedContent = content;

    if (leadingNumberPattern.hasMatch(content)) {
      processedContent = content.replaceFirst(leadingNumberPattern, '');
    }

    final lines = processedContent.split('\n');
    final subsections = <String>[];
    // Matches "100.1." or "100.1a" (note: letter variants have NO dot after them)
    final subsectionPattern = RegExp(r'^\d{3}\.\d+([a-z]|\.)\s');

    var currentSubsection = StringBuffer();

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Check if this is the start of a new subsection
      if (subsectionPattern.hasMatch(trimmedLine)) {
        // Save the previous subsection if it exists
        if (currentSubsection.isNotEmpty) {
          subsections.add(currentSubsection.toString().trim());
          currentSubsection = StringBuffer();
        }
        currentSubsection.writeln(line);
      } else if (trimmedLine.isNotEmpty) {
        currentSubsection.writeln(line);
      }
    }

    // Don't forget the last subsection
    if (currentSubsection.isNotEmpty) {
      subsections.add(currentSubsection.toString().trim());
    }

    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.6,
      fontSize: 15,
      color: isHighlighted
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : null,
    );

    // Build the widget with spacing between subsections
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < subsections.length; i++) ...[
          RichText(
            text: TextSpan(
              children: _parseTextWithLinks(subsections[i], baseStyle, isHighlighted),
            ),
          ),
          if (i < subsections.length - 1)
            Center(
              child: Text(
                '—',
                style: TextStyle(
                  color: isHighlighted
                      ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ],
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
                          child: _buildSubruleContent(group.content, isHighlighted),
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
