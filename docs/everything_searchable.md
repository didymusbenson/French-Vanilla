# Universal Search Implementation

**Status**: 🔄 IN PROGRESS — MTR/IPG search shipped in v1.1.0. Card rulings + filter UI remaining.
**Priority**: High (completes core search functionality)
**Last Updated**: 2026-02-03

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
- ✅ MTR rules (10 sections + 6 appendices) — shipped v1.1.0
- ✅ IPG infractions (4 sections + 2 appendices) — shipped v1.1.0
- ❌ Card rulings (~thousands of cards with rulings)

**Bottom Sheet Previews:**
- ✅ `showRuleBottomSheet()` - for CR subrules (lib/mixins/preview_bottom_sheet_mixin.dart:98)
- ✅ `showGlossaryBottomSheet()` - for glossary terms
- ✅ `showMtrBottomSheet()` - navigates to MtrSectionDetailScreen with highlightRuleNumber — shipped v1.1.0
- ✅ `showIpgBottomSheet()` - navigates to IpgInfractionDetailScreen, subtitle shows penalty — shipped v1.1.0
- ❌ Card ruling previews

**Search Result Type Enum:**
```dart
enum SearchResultType {
  rule,      // Comprehensive Rules
  glossary,  // Glossary terms
  mtr,       // ✅ Shipped v1.1.0
  ipg,       // ✅ Shipped v1.1.0
  // STILL NEEDED: card
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
  // Return: MtrSearchResult with rule, section number, section title, snippet
  // IMPORTANT: Include sectionNumber and sectionTitle for navigation
}

/// Search all IPG infractions and appendices
Future<List<IpgSearchResult>> searchIpg(String query) async {
  // Search through all 4 sections + 2 appendices
  // Match on: infraction number, title, definition, philosophy, examples
  // Return: IpgSearchResult with infraction object and snippet
  // NOTE: Section context NOT required - navigation goes directly to detail screen
}
```

**Search Fields:**
- **MTR**: `number`, `title`, `content`
- **IPG**: `number`, `title`, `definition`, `philosophy`, `examples`, `additionalRemedy`

**Navigation Context:**
- **CRITICAL for MTR**: Search results must include section information (section number and title)
- This is required because MTR navigation uses section-level screens with highlighting
- Example: Searching for "6.7" should return the rule AND its section context (Section 6: Constructed Tournament Rules)
- The section context is used to navigate to `MtrSectionDetailScreen` with `highlightRuleNumber="6.7"`
- **NOT required for IPG**: IPG search results only need the infraction object since navigation goes directly to `IpgInfractionDetailScreen`

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

  // NEW: Section context for MTR navigation
  final String? sectionTitle; // e.g., "6. Constructed Tournament Rules"
  // Note: sectionNumber already exists above and is used for CR and MTR (not needed for IPG)
}
```

**Section Context Usage:**
- **Comprehensive Rules**: `sectionNumber` is used to identify the CR section (1-9)
- **MTR**: Both `sectionNumber` AND `sectionTitle` are required for navigation
  - `sectionNumber`: Used to load the correct section
  - `sectionTitle`: Displayed in the section screen title bar
  - Together with rule number, enables highlighting navigation to `MtrSectionDetailScreen`
- **IPG**: Section context NOT required - navigation goes directly to `IpgInfractionDetailScreen`
  - Only the `ipgInfraction` object is needed for navigation

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
  required int sectionNumber,
  required String sectionTitle,
  required String snippet,
}) {
  // Show modal bottom sheet with:
  // - Title: "MTR {number}. {title}"
  // - Subtitle: "Magic Tournament Rules — Section {sectionNumber}"
  // - Content: rule.content with FormattedContentMixin
  // - Action: "Go to MTR {number}" → navigate to MtrSectionDetailScreen
  //   with highlightRuleNumber parameter to scroll to and highlight the rule
}
```

**Navigation Pattern:**
- Navigate to `MtrSectionDetailScreen` (not a dedicated rule detail screen)
- Pass `highlightRuleNumber` parameter to scroll to and highlight the specific rule
- This matches the Comprehensive Rules pattern where subrules are shown in context
- The section screen displays all rules as cards with titles in headers

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
  // - Content preview: snippet from definition or first example
  // - Action: "Go to IPG {number}" → navigate to IpgInfractionDetailScreen
  //   passing the full infraction object
}
```

**Navigation Pattern:**
- Navigate to `IpgInfractionDetailScreen` (dedicated detail screen per infraction)
- Pass the complete `IpgInfraction` object
- This differs from MTR because infractions contain significantly more content (Definition, Examples, Philosophy, Additional Remedy, Upgrade)
- The detail screen shows all 5 sections in one scrollable view with section headers
- Section context (section number/title) is NOT required for IPG search results since navigation goes directly to detail screen

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

### Phase 1: Data Layer (Foundation) — ✅ MTR/IPG COMPLETE
**Estimate**: 2-3 hours

1. ✅ MTR search — loops in `RulesDataService.search()` (kept centralized here rather than adding to JudgeDocsService). Searches title + content.
2. ✅ IPG search — same location. Title match takes priority to avoid duplicates; otherwise searches definition → examples → philosophy → upgrade. Note: does not search `additionalRemedy` or bare `number` field.
3. ❌ Card search — `searchCardRulings()` not yet implemented
4. ✅ `SearchResultType` enum — added `mtr`, `ipg`
5. ✅ `SearchResult` class — added `mtrRule`, `mtrSectionNumber` (typed as `Object?` to handle both int sections and String appendix letters), `mtrSectionTitle`, `ipgInfraction`
6. ❌ Unit tests — not written

### Phase 2: Bottom Sheet Previews — ✅ MTR/IPG COMPLETE
**Estimate**: 1-2 hours

1. ✅ `showMtrBottomSheet()` — full rule content via `buildFormattedContent`, "Go to [sectionTitle]" navigates to `MtrSectionDetailScreen` with `highlightRuleNumber`
2. ✅ `showIpgBottomSheet()` — definition as preview (falls back to first example if null), penalty in subtitle, "Go to [cleanTitle]" navigates to `IpgInfractionDetailScreen`
3. ❌ `showCardRulingBottomSheet()` — pending card implementation
4. ✅ Navigation flows verified — iOS simulator build passes

### Phase 3: Search Integration — ⚠️ PARTIALLY COMPLETE
**Estimate**: 2-3 hours

1. ✅ MTR/IPG results merged — appended sequentially after CR + glossary in `RulesDataService.search()`. All data is cached by `JudgeDocsService` so parallel `Future.wait` not needed.
2. ❌ Relevance scoring — not implemented. Results ordered by source group (CR → glossary → MTR → IPG). Revisit if users report difficulty finding results.
3. ✅ Result icons — `Icons.gavel` (MTR), `Icons.warning_amber` (IPG), via switch expression
4. ✅ Hint/empty state text updated to "Search rules and judge docs"
5. ❌ Card search integration — pending

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

- [x] Can search MTR rules by number, title, and content ✅ v1.1.0 (note: number matched via content, not number field directly)
- [x] Can search IPG infractions by number, title, definition, philosophy ✅ v1.1.0 (also searches examples + upgrade; does NOT match bare infraction number)
- [ ] Can search card rulings by card name and ruling text
- [x] All results show consistent bottom sheet previews ✅ MTR + IPG done; card pending
- [x] Bottom sheets navigate to correct detail screens ✅ v1.1.0
- [ ] Filters work correctly (single and multi-select)
- [ ] Result counts update when filters change
- [ ] Search history tracks applied filters
- [ ] Performance: Search completes in <500ms for typical queries
- [x] No regressions to existing CR and Glossary search ✅ flutter analyze clean, iOS build passes

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
