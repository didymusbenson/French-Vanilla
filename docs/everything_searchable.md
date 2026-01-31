# Universal Search Implementation

**Status**: 📋 PLANNED
**Priority**: High (completes core search functionality)
**Last Updated**: 2026-01-30

---

## Overview

Extend the existing search functionality to include **MTR**, **IPG**, and **Card Rulings** alongside the current Comprehensive Rules and Glossary search. Add filtering capabilities to allow users to scope searches to specific content types.

---

## Current State Analysis

### ✅ What's Already Working

**Search Infrastructure:**
- `SearchScreen` with auto-focus search bar (lib/screens/search_screen.dart)
- Search history tracking via `SearchHistoryService`
- Bottom sheet previews via `PreviewBottomSheetMixin`
- Snippet extraction with query highlighting
- Search results with consistent card-based UI

**Current Search Coverage:**
- ✅ Comprehensive Rules (all 9 sections)
- ✅ Glossary terms
- ❌ MTR rules (10 sections + 6 appendices = 87 rules)
- ❌ IPG infractions (4 sections + 2 appendices = 28 infractions)
- ❌ Card rulings (~thousands of cards with rulings)

**Existing Bottom Sheet Previews:**
- `showRuleBottomSheet()` - for CR subrules (lib/mixins/preview_bottom_sheet_mixin.dart:98)
- `showGlossaryBottomSheet()` - for glossary terms (line 15)
- ❌ MTR rule previews
- ❌ IPG infraction previews
- ❌ Card ruling previews

**Search Result Type Enum:**
```dart
enum SearchResultType {
  rule,      // Comprehensive Rules
  glossary,  // Glossary terms
  // NEED TO ADD:
  // mtr, ipg, card
}
```

---

## Requirements

### 1. Data Layer: Search Service Extensions

#### **A. JudgeDocsService Search Methods**

Add to `lib/services/judge_docs_service.dart`:

```dart
/// Search all MTR rules and appendices
Future<List<MtrSearchResult>> searchMtr(String query) async {
  // Search through all 10 sections + 6 appendices
  // Match on: rule number, title, content
  // Return: MtrSearchResult with rule, section context, snippet
}

/// Search all IPG infractions and appendices
Future<List<IpgSearchResult>> searchIpg(String query) async {
  // Search through all 4 sections + 2 appendices
  // Match on: infraction number, title, definition, philosophy, examples
  // Return: IpgSearchResult with infraction, section context, snippet
}
```

**Search Fields:**
- **MTR**: `number`, `title`, `content`
- **IPG**: `number`, `title`, `definition`, `philosophy`, `examples`, `additionalRemedy`

**Snippet Strategy:**
- Extract ~150 characters around the match
- Highlight matched terms in the snippet
- Prioritize title matches over content matches

#### **B. CardDataService Search Methods**

Add to `lib/services/card_data_service.dart`:

```dart
/// Search cards by name and ruling text
Future<List<CardSearchResult>> searchCardRulings(String query) async {
  // Search through all cards with rulings
  // Match on: card name, ruling text
  // Return: CardSearchResult with card, matched ruling, snippet
}
```

**Search Fields:**
- Card `name` (primary)
- Ruling `text` (secondary)
- Card `text` (tertiary - oracle text)

**Only Include:**
- Cards that have rulings (filter `card.rulings.isNotEmpty`)
- This matches the existing "Card Rulings" section behavior

### 2. Model Updates

#### **A. Extend SearchResultType Enum**

```dart
enum SearchResultType {
  rule,      // Comprehensive Rules
  glossary,  // Glossary terms
  mtr,       // Magic Tournament Rules
  ipg,       // Infraction Procedure Guide
  card,      // Card rulings
}
```

#### **B. Extend SearchResult Class**

Add optional fields to `SearchResult`:

```dart
class SearchResult {
  final SearchResultType type;
  final int? sectionNumber;
  final String title;
  final String snippet;

  // Existing
  final Rule? rule;
  final SubruleGroup? subruleGroup;
  final GlossaryTerm? glossaryTerm;

  // NEW: Add these
  final MtrRule? mtrRule;
  final IpgInfraction? ipgInfraction;
  final MagicCard? card;
  final Ruling? cardRuling; // Specific ruling that matched
}
```

### 3. UI Layer: Search Screen Enhancements

#### **A. Search Filtering**

Add filter chips above search results (when results exist):

```
┌─────────────────────────────────────┐
│ [All] [Rules] [Glossary] [MTR] ... │  ← Filter chips
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Rule 701.68. Blight             │ │
│ │ To blight a permanent...        │ │
│ └─────────────────────────────────┘ │
```

**Filter Options:**
- **All** (default)
- **Rules** (Comprehensive Rules only)
- **Glossary**
- **MTR** (Magic Tournament Rules)
- **IPG** (Infraction Procedure Guide)
- **Cards** (Card Rulings)

**Filter State:**
- Use `Set<SearchResultType>` to track active filters
- When "All" is selected, clear specific filters
- When any specific filter is selected, deselect "All"
- Multi-select: allow combining filters (e.g., Rules + Glossary)

**Filter UI:**
- Use `FilterChip` widgets in a horizontal scrollable row
- Show result count badges on each filter
- Persist filter state during search session (reset on new search)

#### **B. Result Icons**

Update result list icons to distinguish content types:

| Type | Icon | Color Scheme |
|------|------|-------------|
| Comprehensive Rule | `Icons.rule` | Primary |
| Glossary | `Icons.list_alt` | Primary |
| MTR | `Icons.gavel` | Blue |
| IPG | `Icons.warning_amber_rounded` | Orange |
| Card | `Icons.style` (rotated) | Indigo |

#### **C. Result Layout**

Maintain consistent card-based layout:

```dart
Card(
  child: ListTile(
    leading: Icon(...), // Type-specific icon
    title: Text(result.title),
    subtitle: Text(result.snippet),
    trailing: Icon(Icons.chevron_right),
    onTap: () => _showPreview(result),
  ),
)
```

### 4. Bottom Sheet Previews

#### **A. Add MTR Preview Method**

Add to `PreviewBottomSheetMixin`:

```dart
void showMtrBottomSheet({
  required MtrRule rule,
  required String snippet,
}) {
  // Show modal bottom sheet with:
  // - Title: "MTR {number}. {title}"
  // - Subtitle: "Magic Tournament Rules"
  // - Content: rule.content with FormattedContentMixin
  // - Action: "Go to MTR {number}" → navigate to MtrRuleDetailScreen
}
```

**Consistent with existing patterns:**
- Same layout structure as `showRuleBottomSheet()`
- Use `buildFormattedContent()` for consistent rendering
- Clickable rule links via `RuleLinkMixin`
- Example callouts styled correctly

#### **B. Add IPG Preview Method**

```dart
void showIpgBottomSheet({
  required IpgInfraction infraction,
  required String snippet,
}) {
  // Show modal bottom sheet with:
  // - Title: "IPG {number}. {title}"
  // - Subtitle: "Penalty: {penalty}"
  // - Content sections: Definition, Philosophy, Examples
  // - Action: "Go to IPG {number}" → navigate to IpgInfractionDetailScreen
}
```

**Special considerations:**
- Display penalty prominently (Warning, Game Loss, etc.)
- Show definition, philosophy, and examples in sections
- Format examples as callouts (similar to CR examples)

#### **C. Add Card Ruling Preview Method**

```dart
void showCardRulingBottomSheet({
  required MagicCard card,
  required Ruling ruling,
}) {
  // Show modal bottom sheet with:
  // - Title: card.name
  // - Subtitle: card.type
  // - Oracle text: card.text
  // - Highlighted ruling: ruling.text with date
  // - Action: "View All Rulings for {card.name}" → navigate to CardDetailScreen
}
```

**Layout:**
```
┌─────────────────────────────────┐
│ Lightning Bolt                  │ ← Card name
│ Instant                         │ ← Type
├─────────────────────────────────┤
│ Oracle Text:                    │
│ Lightning Bolt deals 3 damage  │
│ to any target.                  │
├─────────────────────────────────┤
│ Ruling (2021-03-19):           │
│ [Matched ruling text here]      │
├─────────────────────────────────┤
│ [View All Rulings →]           │
└─────────────────────────────────┘
```

### 5. Search Integration: Unified Search Method

Update `SearchScreen._performSearch()` to merge results:

```dart
Future<void> _performSearch(String query) async {
  final results = <SearchResult>[];

  // Run all searches in parallel
  final [crResults, glossaryResults, mtrResults, ipgResults, cardResults] =
    await Future.wait([
      _dataService.search(query),           // CR + Glossary (existing)
      _judgeDocsService.searchMtr(query),   // MTR
      _judgeDocsService.searchIpg(query),   // IPG
      _cardService.searchCardRulings(query), // Cards
    ]);

  results.addAll(crResults);
  results.addAll(mtrResults);
  results.addAll(ipgResults);
  results.addAll(cardResults);

  // Apply filters
  final filteredResults = _applyFilters(results);

  // Sort by relevance (title matches first, then content matches)
  filteredResults.sort(_compareByRelevance);

  setState(() {
    _results = filteredResults;
    _isLoading = false;
  });
}
```

**Relevance Scoring:**
1. Exact title match (highest)
2. Title contains query
3. Content contains query (lowest)

Within same relevance tier, sort alphabetically by title.

### 6. Search History Updates

Extend `SearchHistoryService` to track filter usage:

```dart
class SearchHistoryEntry {
  final String query;
  final int resultCount;
  final DateTime timestamp;
  final Set<SearchResultType>? appliedFilters; // NEW
}
```

Display filters in history:
```
"devotion" → 45 results (Rules, Glossary)
"missed trigger" → 12 results (IPG)
```

---

## Implementation Phases

### Phase 1: Data Layer (Foundation)
**Estimate**: 2-3 hours

1. Add search methods to `JudgeDocsService`
   - `searchMtr()`
   - `searchIpg()`
2. Add search method to `CardDataService`
   - `searchCardRulings()`
3. Extend `SearchResultType` enum
4. Extend `SearchResult` class with new fields
5. Write unit tests for search methods

### Phase 2: Bottom Sheet Previews
**Estimate**: 1-2 hours

1. Add `showMtrBottomSheet()` to mixin
2. Add `showIpgBottomSheet()` to mixin
3. Add `showCardRulingBottomSheet()` to mixin
4. Test preview navigation flows

### Phase 3: Search Integration
**Estimate**: 2-3 hours

1. Update `_performSearch()` to merge all results
2. Implement relevance scoring
3. Add result type icons
4. Update search hint text: "Search rules, glossary, MTR, IPG, cards..."
5. Test search across all content types

### Phase 4: Filter UI
**Estimate**: 2-3 hours

1. Add filter chip row to search screen
2. Implement filter state management
3. Add result count badges
4. Implement multi-select filter logic
5. Test filter combinations

### Phase 5: Polish & Testing
**Estimate**: 1-2 hours

1. Update search history to track filters
2. Add loading states for parallel searches
3. Performance testing with large result sets
4. Edge case testing (empty queries, no results, etc.)

**Total Estimate**: 8-13 hours

---

## Technical Considerations

### Performance

**Search Optimization:**
- **Preloading**: Already done via `DataPreloader` for MTR/IPG indices and all cards
- **Parallel Searches**: Use `Future.wait()` to search all sources concurrently
- **Result Limiting**: Cap at 100 results per source (300 total max)
- **Debouncing**: Consider adding 300ms debounce to search input

**Memory:**
- All data already loaded and cached by services
- No additional memory overhead from search functionality

### User Experience

**Empty States:**
- No MTR results: "No MTR rules match '{query}'"
- No results at all: "No results found for '{query}' in any source"
- Filter with no results: "No {type} results for '{query}'"

**Loading States:**
- Show spinner while searching
- Display "Searching..." with progress indicator for large queries

**Accessibility:**
- Filter chips have clear labels
- Result types are visually distinguishable
- Bottom sheets are scrollable for long content

---

## Open Questions

1. **Should card search include oracle text or only ruling text?**
   - Current thinking: Include both, but prioritize ruling matches

2. **Should we show result counts in filter chips before searching?**
   - No - only show counts after search completes

3. **Should "All" filter be persistent or reset per search?**
   - Reset to "All" for each new search query

4. **Should we add autocomplete/suggestions based on search history?**
   - Future enhancement - not part of initial implementation

---

## Success Criteria

- [ ] Can search MTR rules by number, title, and content
- [ ] Can search IPG infractions by number, title, definition, philosophy
- [ ] Can search card rulings by card name and ruling text
- [ ] All results show consistent bottom sheet previews
- [ ] Bottom sheets navigate to correct detail screens
- [ ] Filters work correctly (single and multi-select)
- [ ] Result counts update when filters change
- [ ] Search history tracks applied filters
- [ ] Performance: Search completes in <500ms for typical queries
- [ ] No regressions to existing CR and Glossary search

---

## Future Enhancements (Post-MVP)

- [ ] **Advanced Filters**: Date ranges for card rulings, penalty levels for IPG
- [ ] **Search Syntax**: Support operators like `type:mtr`, `penalty:warning`
- [ ] **Saved Searches**: Bookmark frequently used search queries
- [ ] **Recent Items**: Show recently viewed rules/cards in search
- [ ] **Deep Linking**: Support `frenchvanilla://search?q=devotion&filter=rules`
- [ ] **Search Analytics**: Track popular searches to improve UX

---

**Next Steps**: Review requirements with team, then proceed with Phase 1 implementation.
