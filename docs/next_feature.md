# Upcoming Work

> **For completed features and development history**, see `docs/development_log.md`

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

## Outstanding Code Quality Items

From pre-release audit (2026-02-14). See `docs/implemented/prerelease_audit_feb_2026.md` for full details.

### High Priority

#### SharedPreferences Error Handling
**Complexity**: Medium (3-4 hours)
- Add try-catch blocks to all SharedPreferences write operations in `FavoritesService`
- Show user feedback when saves fail
- Revert in-memory state on failure
- Prevents silent data loss on disk full/permissions errors

#### List Deletion Bookmark Count
**Complexity**: Low (30 min)
- Show bookmark count in delete confirmation dialog
- Query `getBookmarksInList()` before showing dialog
- Prevents accidental deletion of many bookmarks

#### Snackbar "Add to list" Validation
**Complexity**: Low (1 hour)
- Cancel previous snackbars when unbookmarking
- Check bookmark exists before showing list selection sheet
- Show error if bookmark was removed
- Prevents confusing UX

#### List Loading Optimization
**Complexity**: Medium-High (requires state management)
- Remove `.then((_) => _loadLists())` pattern
- Use state management (Provider/Riverpod) to share list state
- Only reload when actual changes occur
- Improves navigation performance

### Medium Priority

- Bulk operation progress indicators (>10 items)
- Empty state messaging improvements
- List selection sheet scroll position persistence
- Bulk delete feedback snackbars

### Low Priority

- Accessibility labels on IconButtons
- Haptic feedback on Dismissible actions
- Remove debug print statements (search_screen.dart:535, data_preloader.dart)
- Dark mode contrast audit (WCAG AA compliance)
- Crash reporting implementation (Firebase Crashlytics/Sentry)
- Advanced search relevance scoring (TF-IDF)

---

## Future Phases - Bookmark Features

### Manual Bookmark Reordering
**Status**: Deferred - using automatic alphabetical ordering for now
**Complexity**: Medium-High

**As a general user**, I want the ability to re-order my bookmarks so that I can have instant access to the most important rules to me.

**Implementation approach**:
- Fractional indexing for sort order
- Drag-and-drop UI with ReorderableListView
- Per-list ordering (not global)

### Decklist Import
**Status**: Deferred to Phase 2
**Complexity**: High

**As an EDH player**, I want the ability to import an entire decklist to my bookmarks so that I don't have to manually search up individual card rulings.

**Implementation approach**:
- Parse decklist formats (text, .dek, .txt)
- Match card names to database
- Batch bookmark creation
- Error handling for unknown cards

### Keyword Import from Decklist
**Status**: Deferred to Phase 2
**Complexity**: Medium

**As a new/learning player**, I want deck imports to optionally bookmark relevant keywords in addition to card rulings so that I don't have to look up those rules later.

**Implementation approach**:
- Extract keywords from imported cards
- Match to glossary terms
- Optional checkbox during import
- Deduplicate keywords

---

**Last Updated**: 2026-02-14
