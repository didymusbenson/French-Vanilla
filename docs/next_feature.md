# IAP Platform Configuration & Testing

> **Implementation Status**: ✅ Code 100% complete. Platform configuration required.
>
> **For completed features and development history**, see `docs/development_log.md`

---
## Pre-Release Technical Debt

### Medium Priority
- [ ] Review bookmark snackbar aggregation UX (optional)
  - Implementation: `lib/mixins/aggregating_snackbar_mixin.dart`
  - Consider if rapid bookmark behavior needs refinement

---

## Universal Search - Remaining Work

**Status**: MTR/IPG search shipped in v1.1.0. Card rulings search + filter UI remaining.

### Still To Do:

#### 1. Card Rulings Search
**Data Layer:**
- [ ] Add `searchCardRulings()` method to `CardDataService`
  - Search card name (primary), ruling text (secondary), oracle text (tertiary)
  - Only include cards with rulings (`card.rulings.isNotEmpty`)
  - Return `CardSearchResult` with card + matched ruling + snippet

**Model Updates:**
- [ ] Add `card` to `SearchResultType` enum
- [ ] Add `MagicCard? card` and `Ruling? cardRuling` fields to `SearchResult` class

**UI Integration:**
- [ ] Integrate card search into `_performSearch()` (run in parallel with other searches)
- [ ] Add card result icon (`Icons.style`) and tap handler
- [ ] Implement `showCardRulingBottomSheet()` preview method
  - Show card name, type, oracle text, highlighted ruling
  - Action: "View All Rulings" → navigate to CardDetailScreen

#### 2. Search Filtering UI
- [ ] Add filter chip row above search results (FilterChip widgets, horizontal scroll)
- [ ] Implement filter state management (`Set<SearchResultType>`)
- [ ] Filter options: All, Rules, Glossary, MTR, IPG, Cards
- [ ] Show result count badges on each filter
- [ ] Multi-select support (e.g., Rules + Glossary together)
- [ ] "All" deselects specific filters; any specific filter deselects "All"

#### 3. Polish
- [ ] Add relevance scoring (title match > title contains > content match)
- [ ] Update `SearchHistoryService` to track applied filters
- [ ] Display filters in search history (e.g., "devotion → 45 results (Rules, Glossary)")
- [ ] Performance testing with large result sets

**Reference:** See `docs/everything_searchable.md` (archived) for full implementation details.

---

## Copy/Share Enhancements

**Status**: Design complete, ready for implementation
**Complexity**: Low (3/10, ~5-6 hours)

### Problem
Long-press context menu currently copies/shares entire subrule groups (e.g., 101.1 with all lettered parts). Users want to copy specific lettered subrules (e.g., just 101.1a).

### Solution
Change "Copy Rule" → "Copy..." and "Share Rule" → "Share..." in context menu. These open scrollable bottom sheets with options:
- Copy/Share entire rule (default, visually distinct)
- Copy/Share individual lettered subrules (704.5a, 704.5b, etc.)

### Implementation Tasks
- [ ] Update `_showContextMenu()` in `lib/screens/rule_detail_screen.dart` (line 104)
- [ ] Add `_showCopyOptions()` method with scrollable bottom sheet
- [ ] Add `_showShareOptions()` method with scrollable bottom sheet
- [ ] Implement `_parseSubruleOptions()` to extract lettered subrules from content
  - Leverage existing `FormattedContentMixin` parsing
  - Pattern: `^\d{3}\.\d+[a-z]\s`
  - Include associated examples with each lettered subrule
- [ ] Add `_copySpecificSubrule()` and `_shareSpecificSubrule()` methods
- [ ] Handle edge cases:
  - Rules with no lettered parts (show only "entire rule")
  - Rules with 24 lettered parts (704.5 a-x) - ensure scrolling works
  - Examples between lettered subrules (include with preceding subrule)

### Key Test Cases
- Rule 704.5 (24 lettered subrules) - worst case for scrolling
- Rule with 2-3 lettered subrules - typical case
- Rule with no lettered subrules - shows only "entire rule" option
- Copy specific subrule with example - example is included
- Share specific subrule - share dialog works correctly

**Reference:** See `docs/copy_share_enhancements_feature.md` (archived) for full design details.

---

## Verification Steps for Wrapper Scripts

Quick tests to verify the new `getcards` and `getrules` wrapper scripts work correctly:

- [ ] Run `./getcards` from project root - should execute without errors
- [ ] Verify it calls `scripts/process_cards.py` and checks MTGJSON for updates
- [ ] Run `./getrules` without parameters - should show usage error message
- [ ] Run `./getrules "<url>"` with a valid rules URL - should execute update_rules.py
- [ ] Verify all three commands (`./getjudgerules`, `./getcards`, `./getrules`) follow the same pattern

---

**Last Updated**: 2026-02-05
