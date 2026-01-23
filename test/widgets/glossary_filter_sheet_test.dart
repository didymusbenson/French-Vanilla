import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenchvanilla/models/glossary_term.dart';
import 'package:frenchvanilla/widgets/glossary_filter_sheet.dart';

void main() {
  final termCounts = {
    GlossaryTermType.keyword: 10,
    GlossaryTermType.cardType: 5,
    GlossaryTermType.other: 2,
  };

  group('GlossaryFilterSheet', () {
    testWidgets('renders correctly with initial selection', (tester) async {
      final initialFilters = {GlossaryTermType.keyword};
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GlossaryFilterSheet(
            selectedFilters: initialFilters,
            onFiltersChanged: (_) {},
            termCounts: termCounts,
          ),
        ),
      ));

      expect(find.text('Filter by Category'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(GlossaryTermType.values.length));
      
      // Check keyword chip is selected
      final keywordChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Keywords')
      );
      expect(keywordChip.selected, isTrue);
      
      // Check card type chip is not selected
      final cardTypeChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Card Types')
      );
      expect(cardTypeChip.selected, isFalse);
    });

    testWidgets('toggles filters on tap immediately', (tester) async {
      Set<GlossaryTermType>? lastEmittedFilters;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GlossaryFilterSheet(
            selectedFilters: {},
            onFiltersChanged: (filters) => lastEmittedFilters = filters,
            termCounts: termCounts,
          ),
        ),
      ));

      // Tap card types chip
      await tester.tap(find.widgetWithText(FilterChip, 'Card Types'));
      await tester.pump();

      // Verify callback was called immediately containing the new filter
      expect(lastEmittedFilters, contains(GlossaryTermType.cardType));
      
      // Tap again to deselect
      await tester.tap(find.widgetWithText(FilterChip, 'Card Types'));
      await tester.pump();
      
      expect(lastEmittedFilters, isEmpty);
    });

    testWidgets('select all triggers callback immediately', (tester) async {
      Set<GlossaryTermType>? lastEmittedFilters;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GlossaryFilterSheet(
            selectedFilters: {},
            onFiltersChanged: (filters) => lastEmittedFilters = filters,
            termCounts: termCounts,
          ),
        ),
      ));

      await tester.tap(find.text('Select All'));
      await tester.pump();

      // Verify all chips selected and callback fired
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      expect(chips.every((chip) => chip.selected), isTrue);
      expect(find.text('Clear All'), findsOneWidget);
      expect(lastEmittedFilters?.length, GlossaryTermType.values.length);
    });

    testWidgets('clear all triggers callback immediately', (tester) async {
      Set<GlossaryTermType>? lastEmittedFilters;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GlossaryFilterSheet(
            selectedFilters: {GlossaryTermType.keyword},
            onFiltersChanged: (filters) => lastEmittedFilters = filters,
            termCounts: termCounts,
          ),
        ),
      ));

      await tester.tap(find.text('Clear All'));
      await tester.pump();

      // Verify no chips selected
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      expect(chips.every((chip) => !chip.selected), isTrue);
      expect(find.text('Select All'), findsOneWidget);
      expect(lastEmittedFilters, isEmpty);
    });
  });
}
