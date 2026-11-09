# Upcoming Work

> **For completed features and development history**, see `docs/development_log.md`

## Reference Data Refresh - November 9, 2026

- Comprehensive Rules refreshed from Wizards’ November 6, 2026 edition; bundled and source JSON synchronized, with OTA rules version 5.
- Fresh MTGJSON November 9, 2026 download verified against its published SHA256: 35,487 cards, including 20,110 with rulings. OTA rulings version 7 adds 364 cards with no removed card names.
- Official MTR (February 27, 2026) and IPG (September 23, 2024) were rechecked and reproduced unchanged; their content and versions remain unchanged.
- Verified archive membership, payload equality, sizes, hashes, deterministic rebuilds, and decoding by existing app models. App release remains 1.4.1+9.
- Flutter 3.41.2 analysis passed with 29 pre-existing info-level lints, all 3 tests passed, and the unsigned iOS simulator debug and web release builds passed.

## Billing Dependency and Publication Sync - October 20, 2026

- The default publication branch is `master`. Android 1.4.1 (versionCode 9) uses `in_app_purchase` 3.3.1 and `in_app_purchase_android` 0.5.0, which packages Google Play Billing Library 8.0.0.
- The existing billing upgrade, lockfile, version bump, and Flutter 3.41.2 CI SDK (matching local validation) are now maintained together. CI enforces the lockfile and runs analysis and tests before deployment.
- Local Android debug APK and iOS simulator builds passed. The Android APK reports version 1.4.1, versionCode 9, and Billing Library 8.0.0.
- The saved September 1.4.1 build9 AAB also contains Billing Library 8.0.0. Its upload status and active Google Play tracks have not been verified; GitHub publication does not publish a Play Store release.
- Updated the existing app smoke test to check the current Rules title and navigation instead of its obsolete title expectation.

## Reference Data Refresh - October 20, 2026

- Comprehensive Rules updated to the September 25, 2026 edition; bundled JSON and OTA archive rebuilt (rules version 4).
- MTGJSON card data refreshed to October 20, 2026: 35,123 cards, including 20,106 with rulings; bundled data and OTA archive rebuilt (rulings version 6).
- Existing installs receive these updates through the content manifest on `master` using in-app "Check for Updates".

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
