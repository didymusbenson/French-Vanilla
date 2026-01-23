import 'package:flutter/material.dart';
import '../models/glossary_term.dart';

/// A bottom sheet widget for selecting glossary term filter categories.
/// Displays filter chips for each GlossaryTermType with multi-select support.
class GlossaryFilterSheet extends StatefulWidget {
  final Set<GlossaryTermType> selectedFilters;
  final ValueChanged<Set<GlossaryTermType>> onFiltersChanged;
  final Map<GlossaryTermType, int> termCounts;

  const GlossaryFilterSheet({
    super.key,
    required this.selectedFilters,
    required this.onFiltersChanged,
    required this.termCounts,
  });

  @override
  State<GlossaryFilterSheet> createState() => _GlossaryFilterSheetState();
}

class _GlossaryFilterSheetState extends State<GlossaryFilterSheet> {
  late Set<GlossaryTermType> _selectedFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = Set.from(widget.selectedFilters);
  }

  void _toggleFilter(GlossaryTermType type) {
    setState(() {
      if (_selectedFilters.contains(type)) {
        _selectedFilters.remove(type);
      } else {
        _selectedFilters.add(type);
      }
      widget.onFiltersChanged(_selectedFilters);
    });
  }

  void _selectAll() {
    setState(() {
      _selectedFilters = GlossaryTermType.values.toSet();
      widget.onFiltersChanged(_selectedFilters);
    });
  }

  void _clearAll() {
    setState(() {
      _selectedFilters.clear();
      widget.onFiltersChanged(_selectedFilters);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = _selectedFilters.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and action buttons
            Row(
              children: [
                Text('Filter by Category', style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: hasFilters ? _clearAll : _selectAll,
                  child: Text(hasFilters ? 'Clear All' : 'Select All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Choose which types of glossary terms to show',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Filter chips grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GlossaryTermType.values.map((type) {
                final isSelected = _selectedFilters.contains(type);
                final count = widget.termCounts[type] ?? 0;

                return FilterChip(
                  selected: isSelected,
                  showCheckmark: true,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.displayName),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.2,
                                )
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onSelected: (_) => _toggleFilter(type),
                  tooltip: type.description,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Shows the glossary filter bottom sheet.
/// The [onFiltersChanged] callback is called immediately whenever filters change.
Future<void> showGlossaryFilterSheet({
  required BuildContext context,
  required Set<GlossaryTermType> currentFilters,
  required Map<GlossaryTermType, int> termCounts,
  required ValueChanged<Set<GlossaryTermType>> onFiltersChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => GlossaryFilterSheet(
      selectedFilters: currentFilters,
      termCounts: termCounts,
      onFiltersChanged: onFiltersChanged,
    ),
  );
}
