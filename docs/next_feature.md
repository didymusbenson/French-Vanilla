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

## Verification Steps for Wrapper Scripts

Quick tests to verify the new `getcards` and `getrules` wrapper scripts work correctly:

- [ ] Run `./getcards` from project root - should execute without errors
- [ ] Verify it calls `scripts/process_cards.py` and checks MTGJSON for updates
- [ ] Run `./getrules` without parameters - should show usage error message
- [ ] Run `./getrules "<url>"` with a valid rules URL - should execute update_rules.py
- [ ] Verify all three commands (`./getjudgerules`, `./getcards`, `./getrules`) follow the same pattern

---

**Last Updated**: 2026-02-05
