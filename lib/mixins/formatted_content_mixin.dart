import 'package:flutter/material.dart';
import 'rule_link_mixin.dart';

/// Represents a block of content that can be either regular text or an example
class ContentBlock {
  final String content;
  final bool isExample;

  ContentBlock({
    required this.content,
    required this.isExample,
  });
}

/// Mixin providing formatted content rendering with inline example callouts
/// Requires RuleLinkMixin for clickable rule references
mixin FormattedContentMixin<T extends StatefulWidget> on State<T>, RuleLinkMixin<T> {
  /// Builds an example callout with styled left border and subtle background
  Widget buildExampleCallout(String exampleText, bool isHighlighted) {
    final borderColor = isHighlighted
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.primary;

    final backgroundColor = Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1);

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.6,
      fontSize: 15,
      color: isHighlighted
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : null,
    );

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 3.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Example: ',
              style: textStyle?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ...parseTextWithLinks(exampleText, textStyle),
          ],
        ),
      ),
    );
  }

  /// Builds formatted subrule content with spacing between subsections and inline examples
  Widget buildFormattedContent(String content, {bool isHighlighted = false}) {
    // Strip the leading subrule number from the first line since it's shown in the header
    // Matches "201.1. " or "702.90a " (period OR letter after minor number)
    final leadingNumberPattern = RegExp(r'^\d{3}\.\d+([a-z]|\.)\s+');
    String processedContent = content;

    if (leadingNumberPattern.hasMatch(content)) {
      processedContent = content.replaceFirst(leadingNumberPattern, '');
    }

    final lines = processedContent.split('\n');
    final blocks = <ContentBlock>[];
    // Matches "100.1." or "100.1a" (note: letter variants have NO dot after them)
    final subsectionPattern = RegExp(r'^\d{3}\.\d+([a-z]|\.)\s');

    var currentBlock = StringBuffer();
    var currentBlockIsExample = false;

    void saveCurrentBlock() {
      if (currentBlock.isNotEmpty) {
        blocks.add(ContentBlock(
          content: currentBlock.toString().trim(),
          isExample: currentBlockIsExample,
        ));
        currentBlock = StringBuffer();
        currentBlockIsExample = false;
      }
    }

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Empty line indicates paragraph break - save current block and start new one
      if (trimmedLine.isEmpty) {
        saveCurrentBlock();
        continue;
      }

      // Check if this is the start of an example
      if (trimmedLine.startsWith('Example:')) {
        saveCurrentBlock();
        currentBlockIsExample = true;
        // Strip "Example: " prefix
        final exampleText = trimmedLine.substring(8).trim();
        if (exampleText.isNotEmpty) {
          currentBlock.writeln(exampleText);
        }
        continue;
      }

      // Check if this is the start of a new subsection (lettered subrule)
      if (subsectionPattern.hasMatch(trimmedLine)) {
        saveCurrentBlock();
        currentBlock.writeln(line);
        continue;
      }

      // Add to current block
      currentBlock.writeln(line);
    }

    // Don't forget the last block
    saveCurrentBlock();

    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.6,
      fontSize: 15,
      color: isHighlighted
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : null,
    );

    // Build the widget with spacing between blocks
    final widgets = <Widget>[];
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      if (block.isExample) {
        // Render as example callout
        widgets.add(buildExampleCallout(block.content, isHighlighted));
      } else {
        // Check if this block contains any list items
        final listItemPattern = RegExp(r'^\s*(?:[•\-*◦▪]|\d+\.)\s');
        final lines = block.content.split('\n');
        final hasListItems = lines.any((line) => listItemPattern.hasMatch(line));

        if (hasListItems) {
          // Render line by line with selective indentation
          final lineWidgets = <Widget>[];
          for (final line in lines) {
            if (line.trim().isEmpty) continue;

            final isListItem = listItemPattern.hasMatch(line);

            if (isListItem) {
              // Extract bullet/number and content
              final match = listItemPattern.firstMatch(line);
              if (match != null) {
                final bullet = match.group(0)!.trim();
                final content = line.substring(match.end);

                lineWidgets.add(
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fixed-width bullet column
                        SizedBox(
                          width: 24,
                          child: Text(
                            bullet,
                            style: baseStyle,
                          ),
                        ),
                        // Expanded text column (wraps without going under bullet)
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: parseTextWithLinks(content, baseStyle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            } else {
              // Regular line - no indentation
              lineWidgets.add(
                RichText(
                  text: TextSpan(
                    children: parseTextWithLinks(line, baseStyle),
                  ),
                ),
              );
            }
          }

          widgets.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lineWidgets,
            ),
          );
        } else {
          // No list items - render as single block
          widgets.add(
            RichText(
              text: TextSpan(
                children: parseTextWithLinks(block.content, baseStyle),
              ),
            ),
          );
        }
      }

      // Add separator between blocks (but not after examples or at the end)
      if (i < blocks.length - 1 && !block.isExample && !blocks[i + 1].isExample) {
        widgets.add(
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
        );
      }

      // Add spacing after examples
      if (block.isExample && i < blocks.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
