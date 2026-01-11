import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/rule.dart';

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

  @override
  void initState() {
    super.initState();

    print('=== RuleDetailScreen initState ===');
    print('Rule: ${widget.rule.number}. ${widget.rule.title}');
    print('Highlight subrule: ${widget.highlightSubruleNumber}');
    print('Total subrule groups: ${widget.rule.subruleGroups.length}');

    // Scroll to highlighted subrule after build
    if (widget.highlightSubruleNumber != null) {
      print('Scheduling scroll to: ${widget.highlightSubruleNumber}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('PostFrameCallback executing for: ${widget.highlightSubruleNumber}');
        _scrollToSubrule(widget.highlightSubruleNumber!);
      });
    }
  }

  void _scrollToSubrule(String subruleNumber) {
    print('=== _scrollToSubrule called ===');
    print('Target subrule: $subruleNumber');

    // Find the index of the target subrule (add 1 for the header)
    final targetIndex = widget.rule.subruleGroups
        .indexWhere((group) => group.number == subruleNumber);

    print('Target index: $targetIndex');

    if (targetIndex != -1) {
      // Scroll to the item (index + 1 to account for header)
      _itemScrollController.scrollTo(
        index: targetIndex + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05, // Slight offset from top to clear app bar
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

  /// Builds formatted subrule content with spacing between subsections
  Widget _buildSubruleContent(String content, bool isHighlighted) {
    final lines = content.split('\n');
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

    // Build the widget with spacing between subsections
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < subsections.length; i++) ...[
          SelectableText(
            subsections[i],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              fontSize: 15,
              color: isHighlighted
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : null,
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isHighlighted ? 8 : 2,
                  color: isHighlighted
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSubruleContent(group.content, isHighlighted),
                  ),
                );
              },
            ),
    );
  }
}
